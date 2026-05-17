# Umsetzungsplan Schulung: Spec-Driven Softwareentwicklung

Dieser Plan führt die Teilnehmer schrittweise durch den Spec-Driven-Ansatz, vom manuellen Setup bis hin zur KI-gestützten, vertikalen Feature-Entwicklung anhand des "Food-Waste Recipe Finder" Beispiels.

---

## Modul 1: Das Fundament & Setup
Das Ziel dieses Moduls ist es, die Basis für die reibungslose Zusammenarbeit zwischen Entwicklern und KI-Agenten zu schaffen.

* **Spec-Driven Basis:** Gemeinsames Erstellen der Spezifikation als `.md` Datei (Single Source of Truth).
* **Design & Styling Spec:** 
  * Erstellen von Tailwind-Tokens als Teil der Spezifikation (Fokus auf Farben).
  * Design-Spezifikationen anlegen: `srf-einstein.md` und `einstein-tokens.json`.
* **Projekt-Setup (Manuell):** 
  * Projectsetup als Monorepo.
  * Strukturierung mit zwei `package.json` Dateien (einmal im Projekt Root, einmal im Frontend).

## Modul 2: Vertikale Feature-Entwicklung (CRUD)
In diesem Modul setzen wir die ersten Kernfunktionen der Spec von der Datenbank bis zur Benutzeroberfläche um.

* **Schritt 1: Lebensmittel anlegen**
  * Vertikale Umsetzung (Frontend bis Backend).
  * Fokus auf das Einhalten der in der Spec definierten Datenmodelle.
* **Schritt 2: Lebensmittel ändern**
  * Iteratives Erweitern der bestehenden Logik (z. B. Verfallslogik anpassen).

## Modul 3: LLM-Integration (KI als Feature)
Hier integrieren wir die eigentliche "Intelligenz" der Applikation und lernen, wie LLMs sicher und strukturiert in eine klassische Architektur eingebettet werden.

* **Schritt 3: LLM-Abfrage auf Rezepte einbauen**
  * Backend-Logik für die OpenAI-Anbindung.
  * Prompts auslagern und härten (Prompt Security).
  * *Schema over Prompt:* Nutzung von Pydantic und Structured Outputs, um valides JSON für die Rezepte zu erzwingen.

## Modul 4: Frontend Vollendung
Zum Abschluss wird das Ergebnis der KI im Frontend nutzbar gemacht.

* **Schritt 4: Rezepte anzeigen bauen**
  * Das Frontend nutzt die vom LLM generierten und vom Backend validierten strukturierten Daten.
  * Bau der UI-Komponenten (Card-based Action UI) exakt nach den Vorgaben der Markdown-Spezifikation.
