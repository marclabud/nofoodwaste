# ADR 0003: Agentengestützte Rezeptsuche mit Google ADK 2.0 vs. Direkt-LLM-Abfrage

## Status
Akzeptiert

## Kontext (Context)
Für das MVP des "No Food-Waste Recipe Finders" benötigen wir eine intelligente Komponente zur Rezeptgenerierung auf Basis vorhandener Lebensmittel. Die klassische Herangehensweise wäre eine direkte, zustandslose LLM-Abfrage (z. B. ein roher API-Call per OpenAI- oder Gemini-SDK) direkt aus dem FastAPI-Route-Handler. 

Ein direkter API-Call führt jedoch zu einer starken Kopplung von Geschäftslogik und KI-Parametern, erschwert das Tracing einzelner Ausführungsschritte, macht die Integration von externen Hilfswerkzeugen (Tools) komplex und ist anfällig für Prompt-Injections, wenn Benutzereingaben ungesichert verarbeitet werden.

## Entscheidung (Decision)
Wir entscheiden uns gegen eine direkte, klassische LLM-Abfrage und setzen stattdessen auf eine **agentengestützte Software-Architektur** unter Verwendung des **Google ADK 2.0** (Agent Development Kit).

Der Rezept-Agent (`cook_agent`) wird als eigenständige, gekapselte Komponente in `llm_service.py` definiert. Die Ausführung wird über einen dedizierten Ausführungskontext (`InMemoryRunner`) gesteuert. Alle Systeminstruktionen, das erwartete Pydantic-Ausgabe-Schema und die API-Konfigurationen sind in diesem Agenten gebündelt.

## Konsequenzen (Consequences)

### Positive Auswirkungen (Vorteile)
* **Saubere Kapselung (Modularität):** Prompt-Instruktionen ([system_recipe_assistant.md](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/prompts/system_recipe_assistant.md)), Datenvalidierung (`RecipeResponse`) und Modellparameter sind in der Agenten-Instanz gebündelt. Der FastAPI-Route-Handler bleibt frei von KI-Konfigurationsdetails.
* **Isolierte Ausführung & Tracing:** Durch die Nutzung des `InMemoryRunner` lässt sich die Ausführung des Agenten steuern und über `run_debug` lückenlos tracen. Dies vereinfacht das automatisierte Testen und das Auffinden von Fehlern bei komplexen Prompt-Abfolgen.
* **Erweiterbarkeit durch Tools:** Der Agent kann zukünftig extrem leicht um eigene Hilfsfunktionen (z. B. Zugriff auf eine lokale SQLite-Datenbank oder eine Preissuch-API) erweitert werden. Der Agent entscheidet selbstständig über deren Aufruf, ohne dass der Anwendungs-Code geändert werden muss.
* **Erhöhte Robustheit:** Schema-over-Prompt erzwingt native Structured Outputs auf Provider-Ebene. Etwaige Ungenauigkeiten des Modells (wie fehlerhafte Prozentwerte beim `matchScore`) werden nachgelagert über eine Python-Bereinigung in `llm_service.py` normalisiert, bevor die Daten an das Frontend geliefert werden.
* **Prompt-Security:** Durch die Trennung von Systeminstruktionen und strukturierten User-Daten (JSON) bietet die Agenten-Architektur einen systemischen Schutz vor Jailbreaks und Prompt-Injections.

### Risiken & Mehraufwand
* **Erhöhte Abstraktionsschicht:** Entwickler müssen das Programmiermodell von Google ADK 2.0 (Agenten, Runner, Events) verstehen, anstatt einfache String-APIs aufzurufen. Für einfache Textgenerierungen wäre dieser Overhead zu groß – für eine strukturierte, erweiterbare Kernfunktionalität wie die Rezeptgenerierung überwiegen jedoch die Vorteile.
