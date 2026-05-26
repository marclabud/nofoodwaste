import os
import json
import time
from datetime import datetime, timezone
from pydantic import ValidationError

# ADK 2.0 Imports
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.runners import InMemoryRunner

# Internal Imports
from models import RecipeResponse
from llm_service import llm_provider

# =====================================================================
# 0. LLM CONFIGURATION & CONSTANTS
# =====================================================================

# LLM Constants for Agent Choices
LLM_GEMINI_FLASH = "gemini-2.5-flash"
LLM_GEMINI_PRO = "gemini-2.5-pro"
LLM_DEFAULT = "default"

# Choose the active LLM for this Agent
CHOSEN_LLM = LLM_GEMINI_FLASH

# Resolve the model name using the LLMProvider
model_name = llm_provider.get_model(CHOSEN_LLM)

# =====================================================================
# 1. HELPER & UTILITY FUNCTIONS
# =====================================================================

def load_system_prompt() -> str:
    """Loads the system markdown instructions for the chef agent."""
    try:
        prompt_path = os.path.join(os.path.dirname(__file__), "prompts", "system_recipe_assistant.md")
        with open(prompt_path, "r", encoding="utf-8") as file:
            return file.read()
    except FileNotFoundError:
        raise RuntimeError(
            "CRITICAL: 'system_recipe_assistant.md' not found. "
            "Ensure the file exists in the 'prompts/' directory."
        )

def log_agent_run_to_audit_file(ingredients: list, final_recipes: list, duration: float, success: bool, error_msg: str = None):
    """Audits agent execution details either locally or to Cloud Firestore."""
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
            
    log_path = os.path.join(os.path.dirname(__file__), "cook_agent_audit.jsonl")
    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(audit_log, ensure_ascii=False) + "\n")
        print(f"💾 [Audit Log] Successfully written to local file '{log_path}'.")
    except Exception as e:
        print(f"❌ [Audit Log] Failed to write to cook_agent_audit.jsonl: {e}")

# =====================================================================
# 2. GLOBAL ADK 2.0 DEFINITIONS (Crucial for the ADK Web UI)
# =====================================================================

# The Agent definition must be global so the UI engine can crawl and render it.
cook_agent = Agent(
    name="cook_agent",
    model=model_name,
    instruction=load_system_prompt(),
    output_schema=RecipeResponse,
    output_key="recipe_response"
)

# Wrapping it in an App exposes it perfectly to 'adk web'
app = App(
    name="FoodWasteCook",
    root_agent=cook_agent
)

# =====================================================================
# 3. RUNTIME PIPELINE (For API endpoints / local calls)
# =====================================================================

async def generate_recipes(ingredients: list[dict]) -> RecipeResponse:
    """
    Executes the cook_agent pipeline with up to 3 self-correction iterations 
    if Pydantic JSON schema compliance fails.
    """
    prompt_user = json.dumps({"ingredients": ingredients}, ensure_ascii=False)
    
    # DEBUG: Local print statement prior to inference
    print("\n--- DEBUG: USER PROMPT ---")
    print(prompt_user)
    print("--------------------------\n")
    
    start_time = time.perf_counter()
    max_retries = 3  
    current_attempt = 0
    current_prompt = prompt_user
    
    # Notice we pass our globally defined `app` object into the runner here
    async with InMemoryRunner(app=app) as runner:
        while current_attempt <= max_retries:
            try:
                print(f"\n📢 [ADK 2.0] Durchlauf {current_attempt + 1} gestartet...")
                events = await runner.run_debug(current_prompt)
                
                # Console Event Tracing Block
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
                                print(f"    ▪️ Part {p_idx+1} [TOOL CALL]: {part.function_call.name}")
                            elif hasattr(part, "function_response") and part.function_response:
                                print(f"    ▪️ Part {p_idx+1} [TOOL RESPONSE]: {part.function_response.name}")
                print("📢 [ADK 2.0] Tracing beendet.\n")
                
                # Extract the validated payload response
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
                
                # Parse structured output 
                recipe_response = RecipeResponse.model_validate_json(final_text)
                
                # Normalize match scores to a clean 0.0 - 1.0 floating percentage bounds
                for recipe in recipe_response.recipes:
                    if recipe.matchScore > 1.0:
                        recipe.matchScore = recipe.matchScore / 100.0
                    recipe.matchScore = min(max(recipe.matchScore, 0.0), 1.0)
                
                # Audit and return mapping
                duration = time.perf_counter() - start_time
                recipes_list = [
                    {
                        "title": r.title,
                        "matchScore": r.matchScore,
                        "foodWastePriorityReason": r.foodWastePriorityReason
                    } for r in recipe_response.recipes
                ]
                log_agent_run_to_audit_file(ingredients, recipes_list, duration, True)
                
                print(f"✅ [ADK 2.0] Erfolgreiche Generierung und Validierung im Durchlauf {current_attempt + 1}!")
                return recipe_response
                
            except (ValidationError, json.JSONDecodeError, ValueError, Exception) as error:
                current_attempt += 1
                duration = time.perf_counter() - start_time
                print(f"⚠️ [ADK 2.0] Validierungsfehler in Durchlauf {current_attempt}: {str(error)}")
                
                if current_attempt > max_retries:
                    log_agent_run_to_audit_file(
                        ingredients, None, duration, False, 
                        f"Fehlgeschlagen nach {current_attempt} Versuchen. Letzter Fehler: {str(error)}"
                    )
                    raise Exception(f"Failed to validate agent recipe response after maximum attempts: {str(error)}")
                
                # Formulate loop correction feedback
                current_prompt = (
                    f"Deine vorherige Antwort hat die Pydantic-Validierung nicht bestanden.\n\n"
                    f"❌ VALIDIERUNGSFEHLER:\n{str(error)}\n\n"
                    f"Bitte analysiere den Fehler, korrigiere deine Generierung und antworte erneut strictly "
                    f"im geforderten JSON-Format (RecipeResponse Schema)."
                )
