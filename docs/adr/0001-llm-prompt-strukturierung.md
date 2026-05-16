# ADR 0001: Strukturierung der LLM-Prompts für JSON-Antworten mit Structured Outputs

## Status
Akzeptiert

## Kontext (Context)
Die Anwendung nutzt ein Large Language Model (LLM), um aus vorhandenen Zutaten Rezeptvorschläge zu generieren. Dabei müssen Lebensmittel, die kurz vor dem Verfallsdatum stehen, priorisiert werden. Die Antwort des Modells muss strikt als maschinenlesbares JSON-Format zurückgeliefert werden, damit das Frontend die Daten als `RecipeCard`s rendern kann. 

Wenn Anweisungen, Dateneingabe und Formatierungsvorgaben vermischt werden, neigen LLMs oft dazu, zwischen Freitext und Code zu schwanken, was das Parsen der JSON-Antwort im Backend fehleranfällig macht.

## Entscheidung (Decision)
Wir entscheiden uns gegen klassisches "Prompt-Engineering" für das JSON-Format und setzen stattdessen auf **OpenAI Structured Outputs** in Kombination mit **Pydantic**. 

Anstatt das JSON-Format mühsam im System-Prompt zu beschreiben, definieren wir das gewünschte Ausgabe-Schema als Pydantic-Klasse und übergeben es direkt an die neue Methode `client.beta.chat.completions.parse()` (bzw. `client.chat.completions.parse()`). 

### Implementierung (Beispiel)

```python
from typing import List
from openai import OpenAI
from pydantic import BaseModel, Field

# 1. Das gewünschte Ausgabe-Schema via Pydantic definieren
class Rezept(BaseModel):
    titel: str = Field(description="Ein kreativer Name für das Gericht")
    verwendete_zutaten: List[str] = Field(description="Liste der genutzten Zutaten inkl. Mengen")
    zubereitung: str = Field(description="Schritt-für-Schritt Kochanleitung")

class RezeptAntwort(BaseModel):
    rezepte: List[Rezept] = Field(description="Eine Liste bestehend aus Rezeptvorschlägen")

# 2. Die Eingangsdaten (Zutaten) vorbereiten
verfuegbare_lebensmittel = { ... }

# 3. API-Aufruf mit .parse() und gesetztem response_format
completion = client.chat.completions.parse(
    model="chatgpt-5.2",
    messages=[
        {
            "role": "system", 
            "content": "Du bist ein Rezeptassistent. Erstelle aus den übergebenen Zutaten Rezepte. Nutze möglichst viele vorhandene Lebensmittel und bevorzuge Lebensmittel mit nahem Verfalldatum."
        },
        {
            "role": "user", 
            "content": f"Hier sind die verfügbaren Lebensmittel:\\n{verfuegbare_lebensmittel}"
        }
    ],
    response_format=RezeptAntwort,
)

# 4. Daten direkt als typisiertes Python-Objekt abgreifen
daten = completion.choices[0].message.parsed
```

## Konsequenzen (Consequences)

### Positive Auswirkungen (Vorteile)
* **Kein Prompt-Voodoo mehr:** Man muss im System- oder User-Prompt nicht mehr "anflehen", dass das Modell "nur valides JSON" ausgeben soll. Formatierungsanweisungen können komplett entfallen.
* **Typensicherheit (Type Safety):** `.parsed` liefert kein rohes JSON-String-Objekt, das erst geparst werden muss, sondern direkt eine voll validierte Instanz der Pydantic-Klasse (z.B. `RezeptAntwort`). Das ermöglicht im Backend volle IDE-Unterstützung (Autocompletion).
* **Single Source of Truth:** Das Schema existiert nur einmal (in `models.py`). Es gibt keine doppelte Pflege mehr von Text-Prompts und Pydantic-Modellen.
* **Fehlertoleranz:** Sollte die API fehlschlagen (z.B. wegen Inhaltsfiltern), wirft das SDK einen sauberen Fehler, statt das Backend mit unvollständigen JSON-Strings abstürzen zu lassen.

### Negative Auswirkungen / Risiken
* **Framework-Abhängigkeit:** Wir koppeln uns stark an die Pydantic-Integration der OpenAI Python-Bibliothek und sind an Modelle gebunden, die "Structured Outputs" unterstützen.
* **Frontend-Synchronisierung:** Die TypeScript-Interfaces im Frontend müssen weiterhin mit den Pydantic-Modellen im Backend synchronisiert werden (dies könnte künftig über Tools wie `openapi-typescript` automatisiert werden).
