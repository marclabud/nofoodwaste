# ADR 0002: Nutzung von OpenAPI 3.0 als Schema-Standard für LLM-Antworten

## Status
Akzeptiert

## Kontext (Context)
Mit der Entscheidung (siehe ADR 0001), strukturierte JSON-Antworten vom LLM durch "Structured Outputs" und Pydantic-Modelle zu erzwingen, stellt sich die Frage nach dem zugrundeliegenden Standard für die Schema-Definition. 

Sowohl OpenAI (gpt-4o) als auch Google (Gemini) greifen unter der Haube auf eine einheitliche Spezifikation zurück, um Datentypen und benötigte Felder zu definieren, anstatt proprietäre Formate zu erfinden.

## Entscheidung (Decision)
Wir erkennen den **OpenAPI 3.0-Standard** (speziell das `components/schemas`-Objekt) als das technologische Fundament für unsere Structured Outputs an. 

Wenn in unserem Backend `Pydantic` genutzt wird, übersetzt die Methode `.model_json_schema()` unseren Python-Code exakt in dieses standardisierte OpenAPI-Vokabular. Dieses Schema übergibt der OpenAI-Client dann unsichtbar an die API.

### Was ist der OpenAPI 3.0-Standard?
Ursprünglich unter dem Namen "Swagger" bekannt, wird die Spezifikation heute von der offenen OpenAPI Initiative (OAI) der Linux Foundation gepflegt. Während ein vollständiges OpenAPI-Dokument ganze REST-APIs beschreibt (URLs, Methoden, Auth), fokussieren sich LLMs ausschließlich auf den "Schema"-Teil. Dieser definiert strikt, ob ein Feld ein String, Array oder eine Zahl ist und welche Felder `required` sind.

## Konsequenzen (Consequences)

### Vorteile (Warum KI-Anbieter diesen Standard nutzen)
* **Interoperabilität:** Da das OpenAPI-Schema von verschiedenen KI-Anbietern (Google, OpenAI) verstanden wird, können wir unsere Datenschemata (z.B. unser Rezept-Schema) theoretisch ohne Änderungen auch für andere Modelle wie Gemini (`Controlled Generation`) weiternutzen.
* **Mathematische Striktheit:** Das Schema ist so präzise, dass die LLM-Entwickler den Token-Generator ("Ausgabemotor") mathematisch dazu zwingen können, sich während der Generierung Zeichen für Zeichen an die Grammatik zu halten.
* **Etabliertes Ökosystem:** Der Standard bringt ein riesiges Ökosystem an Werkzeugen mit, mit denen wir künftig automatisch Frontend-Code, Testdaten oder Dokumentationen generieren können.

## Referenzen & Offizielle Quellen
* **OpenAPI Initiative (OAI):** [OpenAPI Specification v3.0.3](https://swagger.io/specification/v3/)
* **Google Gemini:** [Structured Outputs / Controlled Generation Guide](https://ai.google.dev/docs/structured_outputs)
* **OpenAI:** [Developer Guide: Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs)
