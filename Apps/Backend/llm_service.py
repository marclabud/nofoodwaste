import os
import json
from models import RecipeResponse
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner

def load_system_prompt() -> str:
    prompt_path = os.path.join(os.path.dirname(__file__), "prompts", "system_recipe_assistant.md")
    with open(prompt_path, "r", encoding="utf-8") as file:
        return file.read()

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
    
    # 2. Run the agent using InMemoryRunner context manager
    async with InMemoryRunner(agent=cook_agent, app_name="FoodWasteCook") as runner:
        events = await runner.run_debug(prompt_user)
        
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
            raise Exception("No response received from Cook Agent.")
            
        # Parse the structured JSON response into our Pydantic model
        try:
            return RecipeResponse.model_validate_json(final_text)
        except Exception as parse_error:
            print(f"Validation failed for Cook Agent output: {parse_error}")
            print(f"Raw Output: {final_text}")
            raise Exception(f"Failed to validate agent recipe response: {str(parse_error)}")

