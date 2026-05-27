Hier ist die finale Zusammenfassung der vorgeschlagenen Lösung, die die beiden Sicherheitsmechanismen optimal miteinander kombiniert.

Dieses Design nutzt das Prinzip der **Separation of Concerns**: Die Funktion selbst kümmert sich um die Logik und die Begrenzung ihrer internen Schleifen, während der Decorator als außenstehender Wächter die globale Kostenkontrolle und Buchhaltung übernimmt.

---

## 🏗️ Das 2-Stufen-Sicherheitskonzept

### Stufe 1: Die interne Reißleine (Innerhalb der Funktion)

* **Mechanismus:** Eine harte Begrenzung der Iterationen über `max_retries = 3`.
* **Zweck:** Verhindert eine technische Endlosschleife und explodierende Token-Kosten pro User-Lauf, falls die Pydantic-Validierung des LLM-Outputs mehrfach fehlschlägt.
* **Vorteil:** Da die maximale Anzahl der API-Aufrufe pro Funktion mathematisch auf 4 (1 Start + 3 Retries) gedeckelt ist, sind die maximalen Kosten pro Aufruf von vornherein berechenbar und limitiert. Ein unkontrolliertes "Weglaufen" der Kosten innerhalb eines einzelnen Requests ist ausgeschlossen.

### Stufe 2: Der externe Wächter (Der Decorator / `@budget_guard`)

* **Mechanismus:** Ein asynchroner Python-Decorator, der die Funktion umschließt.
* **Zweck:** Überwachung des globalen System-Budgets (Gesamtkosten aller User) und nachträgliche Token-Abrechnung.
* **Vorteil (Black Box):** Du musst nicht zwingend Zugriff auf den inneren Code der Funktion haben. Der Decorator fängt die Anfrage ab, bevor sie das LLM erreicht, und analysiert die ADK 2.0-Metadaten erst, wenn die Funktion komplett fertig ist.

---

## 🔄 Der Ablauf eines API-Aufrufs

1. **Anfrage trifft ein:** Der `@budget_guard` prüft, ob das globale Systembudget (z.B. 50€/Monat) noch ausreicht. Wenn das Budget erschöpft ist (z.B. durch einen Bot-Angriff), wird der Aufruf **sofort blockiert**, ohne dass Kosten entstehen.
2. **Ausführung:** Ist Budget vorhanden, startet die eigentliche Funktion. Sie führt das ADK-Tool-Calling aus. Schlägt die Validierung fehl, korrigiert sich der Agent selbst – jedoch **maximal 3-mal**.
3. **Rückgabe & Abrechnung:** Die Funktion beendet sich (erfolgreich oder nach maximalen Retries) und übergibt die gesammelten ADK-Events an den Decorator. Der Decorator liest die `usage_metadata` (Prompt- und Candidate-Tokens) aller Durchläufe aus, berechnet die Kosten anhand des Modell-Preises (Flash vs. Pro) und zieht den Betrag vom globalen Budget ab.

---

## 🛠️ Code-Zusammenfassung

### 1. Der Wächter (`llm_service.py`)

```python
from functools import wraps
import os

class BudgetManager:
    def __init__(self):
        self.global_budget_limit = float(os.getenv("GLOBAL_BUDGET_LIMIT", "50.00"))
        self.current_spend = 0.0 # In der Praxis aus DB/Redis laden

    def has_budget(self) -> bool:
        return self.current_spend < self.global_budget_limit

    def record_usage(self, events):
        # Extrahiert alle Tokens aus den ADK 2.0 Events und berechnet die Kosten
        input_tokens = sum(getattr(e.usage_metadata, "prompt_token_count", 0) for e in events if hasattr(e, "usage_metadata") and e.usage_metadata)
        output_tokens = sum(getattr(e.usage_metadata, "candidates_token_count", 0) for e in events if hasattr(e, "usage_metadata") and e.usage_metadata)
        
        # Beispiel-Berechnung (fiktive Gemini-Preise)
        cost = (input_tokens * 0.000075 / 1000) + (output_tokens * 0.0003 / 1000)
        self.current_spend += cost
        print(f"💰 Global Spend: {self.current_spend:.4f}$ / {self.global_budget_limit:.2f}$")

def budget_guard():
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if not llm_provider.budget.has_budget():
                raise PermissionError("❌ Globales Budget erschöpft! Aufruf blockiert.")
            
            # Funktion ausführen (liefert Response und die Event-Historie)
            recipe_response, events = await func(*args, **kwargs)
            
            # Nachgelagerte Abrechnung aller Versuche
            llm_provider.budget.record_usage(events)
            return recipe_response
        return wrapper
    return decorator

```

### 2. Die geschützte Pipeline (`agent_service.py`)

```python
@budget_guard()
async def generate_recipes(ingredients: list[dict]):
    max_retries = 3  
    current_attempt = 0
    all_collected_events = []
    current_prompt = json.dumps({"ingredients": ingredients})
    
    async with InMemoryRunner(app=app) as runner:
        while current_attempt <= max_retries:
            try:
                events = await runner.run_debug(current_prompt)
                all_collected_events.extend(events) # Für den Decorator sichern
                
                # ... (Parsing & Pydantic Validierung) ...
                recipe_response = RecipeResponse.model_validate_json(final_text)
                return recipe_response, all_collected_events
                
            except Exception as error:
                current_attempt += 1
                if current_attempt > max_retries:
                    raise Exception(f"Fehlgeschlagen nach max Retries. Letzter Fehler: {str(error)}")
                current_prompt = f"Fehler: {str(error)}. Bitte korrigiere das JSON strictly nach Schema."

```

---

## 🎯 Warum diese Kombination gewinnt

1. **Zukunftssicher (Kopplung):** Wenn du morgen ein geschlossenes System oder ein anderes Framework nutzt, bei dem du die `while`-Schleife nicht einsehen kannst, bleibt deine globale Kostenkontrolle über den Decorator intakt.
2. **Wartbarkeit:** Der Kern-Code des Agenten bleibt übersichtlich. Er kümmert sich nur um seine Aufgabe (Rezepte generieren und Fehler korrigieren), während die "Buchhaltung" komplett ausgelagert ist.
3. **Voller Schutz:** Du bist sowohl gegen "Amok-Läufe" einzelner User-Anfragen (Stufe 1) als auch gegen unvorhergesehene Massen-Aufrufe/Bot-Angriffe von außen (Stufe 2) geschützt.