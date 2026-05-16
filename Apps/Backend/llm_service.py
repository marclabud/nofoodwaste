import os
from openai import OpenAI
import json
from models import RecipeResponse

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

PROMPT_SYSTEM = """Du bist ein Rezeptassistent für Food-Waste-Reduktion.

Aufgabe:
Finde 1 bis 3 einfache Rezepte auf Basis vorhandener Lebensmittel.

Regeln:
- Nutze möglichst viele vorhandene Lebensmittel.
- Bevorzuge Lebensmittel mit nahem Verfalldatum.
- Nutze keine verfallenen Lebensmittel.
- Nenne fehlende Pflichtzutaten separat.
- Nenne optionale Zutaten separat.
- Gib kurze Kochschritte.
"""

def generate_recipes(ingredients: list[dict]) -> RecipeResponse:
    prompt_user = json.dumps({"ingredients": ingredients}, ensure_ascii=False)
    
    # DEBUG: Gib den User-Prompt vor der Abfrage im Terminal (Uvicorn) aus
    print("\n--- DEBUG: USER PROMPT ---")
    print(prompt_user)
    print("--------------------------\n")
    
    # Temporär für Debugging: Dummy-Rezept mit Prompt zurückgeben
    return RecipeResponse(recipes=[{
        "title": "Debug Rezept",
        "matchScore": 1.0,
        "foodWastePriorityReason": "Dies ist ein Debug-Lauf.",
        "estimatedTimeMinutes": 15,
        "usedIngredients": [ing["name"] for ing in ingredients],
        "missingRequiredIngredients": [],
        "optionalIngredients": [],
        "steps": ["Den User-Prompt prüfen."],
        "explanation": f"Hier ist der generierte User-Prompt:\n\n{prompt_user}"
    }])
    
    # ECHTER AUFRUF (Lösung 2 mit Structured Outputs)
    # Sobald der API-Key gesetzt ist, diese Zeilen einkommentieren und den Dummy-Return entfernen.
    # Wir nutzen client.beta.chat.completions.parse, was das Pydantic-Modell automatisch in ein JSON-Schema
    # umwandelt und OpenAI zwingt, sich zu 100% daran zu halten.
    #
    # response = client.beta.chat.completions.parse(
    #     model=os.getenv("LLM_MODEL", "gpt-4o"),
    #     messages=[
    #         {"role": "system", "content": PROMPT_SYSTEM},
    #         {"role": "user", "content": prompt_user}
    #     ],
    #     response_format=RecipeResponse,
    #     extra_body={"instant": True}
    # )
    # 
    # return response.choices[0].message.parsed
