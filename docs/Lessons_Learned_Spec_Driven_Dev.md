# Lessons Learned: Spec-Driven Softwareentwicklung

Dieses Dokument fasst die wichtigsten Erkenntnisse aus der Entwicklung des "Food-Waste Recipe Finder MVP" zusammen. Es dient als Grundlage für die interne Schulung zum Thema **"Spec-Driven Softwareentwicklung"**.

---

## Lektion 1: Die Markdown-Spezifikation als "Single Source of Truth"

Der wichtigste Erfolgsfaktor des Projekts war die initiale Erstellung der `spec_md_food_waste_recipe_finder_mvp.md`.

* **Erkenntnis:** Anstatt sofort Code zu schreiben, zwang uns das Spec-Driven-Vorgehen dazu, Datenmodelle (TypeScript), UI-Entwürfe (ASCII-Wireframes) und API-Schnittstellen im Vorfeld zu durchdenken.
* **Vorteil für KI-Agenten:** LLM-basierte Entwickler-Agenten benötigen präzise Leitplanken. Eine detaillierte Markdown-Spezifikation ist das perfekte Format für KI, da sie maschinenlesbar ist, Kontext liefert und Halluzinationen in der Architektur drastisch reduziert.
* **Ergebnis:** Das Frontend (Vue) und das Backend (FastAPI/SQLite) konnten auf Basis einer klaren Schnittstellenvereinbarung nahtlos entwickelt werden.

## Lektion 2: Strukturierte Architektur-Entscheidungen (ADRs)

Um Nachvollziehbarkeit bei komplexen Entscheidungen zu gewährleisten, wurden Architecture Decision Records (ADRs) eingesetzt (siehe `docs/adr/`).

* **Erkenntnis:** Die Entscheidung, wie das System mit dem LLM kommuniziert, wurde nicht im Code versteckt, sondern in ADR-0001 und ADR-0002 dokumentiert.
* **Praxisbeispiel:** Anstatt auf fehleranfälliges "Prompt-Voodoo" zu setzen, um JSON vom LLM zu erzwingen, wurde die strategische Entscheidung getroffen, auf **OpenAPI 3.0** und **Structured Outputs (via Pydantic)** zu setzen. 
* **Ergebnis:** Typensicherheit auf Backend-Ebene, Single Source of Truth für Datenschemata und eine zukunftssichere Provider-Unabhängigkeit (OpenAI vs. Gemini).

## Lektion 3: LLM-Integration & Prompt-Wartbarkeit

Die Integration des Language Models hat gezeigt, dass Prompts wie Software-Code behandelt werden müssen.

* **Erkenntnis (Trennung von Code und Prompt):** Die anfängliche Vermischung von Python-Logik und Prompts war schwer zu warten. Die Auslagerung des System-Prompts in eine externe Datei (`system_recipe_assistant.md`) verbesserte die Lesbarkeit und Wartbarkeit massiv.
* **Erkenntnis (Security & Hardening):** Prompts sind Angriffsvektoren ("Prompt Injection"). Wie im `Security.md` definiert, muss der System-Prompt strikte Grenzen setzen, Fallbacks bei bösartigen Eingaben definieren (leeres Array zurückgeben) und Benutzer-Daten klar von System-Instruktionen trennen.

## Lektion 4: KI-Agenten gezielt steuern

Die Projektentwicklung erfolgte durch den intensiven Einsatz von KI-Agenten (z. B. Agent Manager, Agent Researcher).

* **Erkenntnis:** KI-Agenten arbeiten nur so gut wie ihre Projektregeln. Dateien wie `AGENTS.md` und `Typescript-Rules.md` waren notwendig, um das Verhalten der Agenten zu standardisieren.
* **Praxisbeispiel:** Agenten konnten direkt auf die ADRs und die `spec.md` verwiesen werden, um Features wie die "Zutaten-Bearbeitung" genau nach den vorab definierten Verfallslogiken ("ExpiresAt < Today") zu implementieren.

---

## Zusammenfassung für die Schulung

Für das Training "Spec-Driven Softwareentwicklung" sollten folgende Kernprinzipien vermittelt werden:

1. **Write Spec First:** Kein Code ohne Markdown-Spezifikation.
2. **Schema over Prompt:** Für Maschinen-Kommunikation nutzen wir strukturierte Daten (OpenAPI/Pydantic), keinen Freitext-Prompt.
3. **Decouple Prompts:** Prompts sind Konfigurationen und gehören nicht tief in die Applikationslogik.
4. **Design for AI:** Architektur- und Designdokumente (ADRs, Specs) müssen so geschrieben sein, dass sowohl Menschen als auch KI-Entwicklungsagenten sie eindeutig interpretieren können.
