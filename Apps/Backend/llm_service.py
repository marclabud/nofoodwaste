import os
import json
import time
from datetime import datetime, timezone
from pydantic import ValidationError
from models import RecipeResponse
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner

def load_system_prompt() -> str:
    prompt_path = os.path.join(os.path.dirname(__file__), "prompts", "system_recipe_assistant.md")
    with open(prompt_path, "r", encoding="utf-8") as file:
        return file.read()

def log_agent_run_to_audit_file(ingredients: list, final_recipes: list, duration: float, success: bool, error_msg: str = None):
    audit_log = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "input_ingredients": ingredients,
        "recipes_count": len(final_recipes) if final_recipes else 0,
        "recipes": final_recipes,
        "duration_seconds": round(duration, 3),
        "success": success,
        "error": error_msg
    }
    
    provider_name = os.getenv("DB_PROVIDER", "sqlite").lower()
    if provider_name == "firestore":
        try:
            from google.cloud import firestore
            db = firestore.Client()
            db.collection("agent_audit_logs").add(audit_log)
            print("💾 [Audit Log] Successfully written to Cloud Firestore collection 'agent_audit_logs'.")
            return
        except Exception as e:
            print(f"⚠️ [Audit Log] Failed to write to Firestore: {e}. Falling back to local file.")
            
    # Local fallback or default SQLite provider logs to local file
    log_path = os.path.join(os.path.dirname(__file__), "cook_agent_audit.jsonl")
    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(audit_log, ensure_ascii=False) + "\n")
        print(f"💾 [Audit Log] Successfully written to local file '{log_path}'.")
    except Exception as e:
        print(f"❌ [Audit Log] Failed to write to cook_agent_audit.jsonl: {e}")

async def generate_recipes(ingredients: list[dict]) -> RecipeResponse:
    prompt_user = json.dumps({"ingredients": ingredients}, ensure_ascii=False)
    system_prompt = load_system_prompt()
    
    # DEBUG: Gib den User-Prompt vor der Abfrage im Terminal (Uvicorn) aus
    print("\n--- DEBUG: USER PROMPT ---")
    print(prompt_user)
    print("--------------------------\n")
    
    # 1. Define the Cook Agent with ADK 2.0
    model_name = os.getenv("LLM_MODEL", "gemini-2.5-flash")
    cook_agent = Agent(
        name="cook_agent",
        model=model_name,
        instruction=system_prompt,
        output_schema=RecipeResponse,
        output_key="recipe_response"
    )
    
    start_time = time.perf_counter()
    max_retries = 3  # N=3 Versuche zur Selbstkorrektur (insgesamt max. 4 Durchläufe)
    current_attempt = 0
    current_prompt = prompt_user
    
    # 2. Run the agent using InMemoryRunner context manager
    async with InMemoryRunner(agent=cook_agent, app_name="FoodWasteCook") as runner:
        while current_attempt <= max_retries:
            try:
                print(f"\n📢 [ADK 2.0] Durchlauf {current_attempt + 1} gestartet (max. {max_retries + 1} Versuche)...")
                events = await runner.run_debug(current_prompt)
                
                # === Strategie 1: Detailliertes ADK-Event-Tracing in der Konsole ===
                print(f"📢 [ADK 2.0] Koch-Agent beendet - {len(events)} Events empfangen:")
                for idx, event in enumerate(events):
                    author = getattr(event, "author", "system/unknown")
                    is_final = event.is_final_response()
                    print(f"  🔹 [Event {idx+1}/{len(events)}] Quelle: '{author}' | Final: {is_final}")
                    
                    if event.content and event.content.parts:
                        for p_idx, part in enumerate(event.content.parts):
                            if hasattr(part, "text") and part.text:
                                text_preview = part.text.strip().replace('\n', ' ')
                                if len(text_preview) > 100:
                                    text_preview = text_preview[:100] + "..."
                                print(f"    ▪️ Part {p_idx+1} (Text): {text_preview}")
                            elif hasattr(part, "function_call") and part.function_call:
                                print(f"    ▪️ Part {p_idx+1} [TOOL CALL]: {part.function_call.name} (Args: {part.function_call.args})")
                            elif hasattr(part, "function_response") and part.function_response:
                                print(f"    ▪️ Part {p_idx+1} [TOOL RESPONSE]: {part.function_response.name}")
                print("📢 [ADK 2.0] Tracing beendet.\n")
                
                # 3. Extract the final response conforming to RecipeResponse
                final_text = ""
                for event in reversed(events):
                    if event.is_final_response() and event.content and event.content.parts:
                        for part in event.content.parts:
                            if part.text:
                                final_text = part.text
                                break
                        if final_text:
                            break
                
                if not final_text:
                    raise ValueError("No response received from Cook Agent.")
                
                # Parse the structured JSON response into our Pydantic model
                recipe_response = RecipeResponse.model_validate_json(final_text)
                
                # Normalize matchScore for each recipe
                for recipe in recipe_response.recipes:
                    if recipe.matchScore > 1.0:
                        recipe.matchScore = recipe.matchScore / 100.0
                    recipe.matchScore = min(max(recipe.matchScore, 0.0), 1.0)
                
                # Erfolgreichen Durchlauf auditieren
                duration = time.perf_counter() - start_time
                recipes_list = []
                for recipe in recipe_response.recipes:
                    recipes_list.append({
                        "title": recipe.title,
                        "matchScore": recipe.matchScore,
                        "foodWastePriorityReason": recipe.foodWastePriorityReason
                    })
                log_agent_run_to_audit_file(ingredients, recipes_list, duration, True)
                
                print(f"✅ [ADK 2.0] Erfolgreiche Generierung und Validierung im Durchlauf {current_attempt + 1}!")
                return recipe_response
                
            except (ValidationError, json.JSONDecodeError, ValueError, Exception) as error:
                current_attempt += 1
                duration = time.perf_counter() - start_time
                
                print(f"⚠️ [ADK 2.0] Validierungsfehler in Durchlauf {current_attempt}: {str(error)}")
                
                if current_attempt > max_retries:
                    # Keine Retries mehr übrig -> Fehler loggen und abbrechen
                    log_agent_run_to_audit_file(ingredients, None, duration, False, f"Fehlgeschlagen nach {current_attempt} Versuchen. Letzter Fehler: {str(error)}")
                    print(f"Validation or Agent execution failed permanently: {error}")
                    raise Exception(f"Failed to execute and validate agent recipe response after {max_retries + 1} attempts: {str(error)}")
                
                # Feedback-Prompt für die Korrekturschleife erstellen
                current_prompt = (
                    f"Deine vorherige Antwort hat die Pydantic-Validierung nicht bestanden und war fehlerhaft.\n\n"
                    f"❌ VALIDIERUNGSFEHLER:\n{str(error)}\n\n"
                    f"Bitte analysiere den Fehler, korrigiere deine Generierung und antworte erneut strictly "
                    f"im geforderten JSON-Format (RecipeResponse Schema)."
                )


