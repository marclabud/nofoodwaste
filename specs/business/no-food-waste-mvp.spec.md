# Business & UX Master Specification: NoFoodWaste MVP
*(Single Source of Truth)*

---

## 1. Produktvision & Ziele

**NoFoodWaste** ist eine mobile Webanwendung zur Reduktion von Lebensmittelverschwendung im privaten Haushalt. 

Benutzer erfassen vorhandene Lebensmittel mit Namen, Menge, Einheit und Verfallsdatum. Die Anwendung analysiert diese Zutaten und generiert mithilfe eines intelligenten AI-Agenten (**„Koch-Agent“**) genau drei passende, kreative und alltagstaugliche Rezeptvorschläge.

### Kernziele:
*   **Lebensmittel retten**: Zutaten vor dem Verfall verbrauchen.
*   **Einfache Rezeptideen**: Schnelle und unkomplizierte Vorschläge ohne langwierige Suche.
*   **Spontane Resteverwertung**: Pragmatische Kochvorschläge basierend auf dem aktuellen Bestand.
*   **Freude am Kochen**: Lebensmittelverschwendung spielerisch und positiv motiviert reduzieren (*„Lebensmittel retten soll Spaß machen!“*).

### Architektur- & Designcharakter:
*   **Mobile First**: Primär für die Nutzung auf Smartphones in der Küche konzipiert.
*   **LLM-zentriert**: Das System verzichtet im MVP auf eine klassische, starre Rezeptdatenbank. Stattdessen generiert die generative KI (Gemini 2.5 Flash via Google ADK 2.0) dynamische, maßgeschneiderte Vorschläge.
*   **Bewusst einfach**: Minimalistisches, ruhiges UI mit Fokus auf das Wesentliche.

---

## 2. Functional Scope (Funktionsumfang)

### ✓ Enthalten im MVP
*   **Lebensmittel erfassen**: Schnelle Eingabe neuer Zutaten über ein ausklappbares Formular.
*   **Lebensmittel speichern**: Lokale Speicherung der Daten (SQLite/Firestore).
*   **Lebensmittel bearbeiten & löschen**: Nachträgliche Anpassung von Name, Menge, Einheit oder Ablaufdatum direkt in der Liste.
*   **Verfallsprüfung**: Automatische Berechnung des Frischestatus mit visueller Farbkennzeichnung.
*   **MHD-Inferenzfilter**: Vollständiger Ausschluss verfallener Lebensmittel von der Rezeptgenerierung.
*   **Agentengestützte Rezeptsuche**: Manuelle Generierung von **exakt drei** Rezepten über den Koch-Agenten (Google ADK 2.0).
*   **Rezeptanzeige (Card-based Action UI)**: Strukturierte Darstellung der Rezepte inklusive verwendeter, fehlender und optionaler Zutaten sowie Kochanleitung.
*   **Food-Waste-Hinweise (AI Insights)**: Ein prägnanter Hinweis pro Rezept, warum dieser Vorschlag zur Rettung der Lebensmittel beiträgt.

### ✗ Nicht im MVP
*   Benutzerkonten & Login (Multi-User-Betrieb)
*   Cloud Sync / Synchronisation zwischen Geräten
*   Barcode-Scanner zur automatischen Produkterfassung
*   Automatische Einkaufslisten-Generierung
*   Allergen-Filter oder Nährwert-Tracking (Nutrition Tracking)
*   Lokale Rezept-RAG-Datenbank
*   Rezepte favorisieren, speichern, drucken oder teilen
*   Offline-Modus

---

## 3. Datenmodelle & API-Schnittstellen

Die Datenmodelle sind im Backend (`models.py`) und im Frontend (`types/index.ts`) identisch definiert und garantieren Typensicherheit durch Pydantic- und TypeScript-Validierung.

### 3.1 Ingredient (Lebensmittel)
```typescript
type Ingredient = {
  id: string
  name: string
  quantity: number
  unit: "g" | "kg" | "ml" | "l" | "piece"
  expiresAt: string  // Format: YYYY-MM-DD
  createdAt: string  // ISO-Timestamp (z.B. 2026-05-26T14:30:00Z)
}
```

### 3.2 Recipe (Rezeptvorschlag)
```typescript
type Recipe = {
  title: string
  matchScore: number               // Dezimalwert zwischen 0.0 und 1.0 (z.B. 0.95 für 95% Match)
  foodWastePriorityReason: string   // AI Insight Erklärung (z.B. „Nutzt ablaufende Eier“)
  estimatedTimeMinutes: number
  usedIngredients: string[]        // Genutzte Zutaten aus dem vorhandenen Bestand
  missingRequiredIngredients: string[] // Zusätzlich benötigte Pflichtzutaten
  optionalIngredients: string[]    // Optionale Zutaten zur Verfeinerung
  steps: string[]                  // Schritt-für-Schritt Zubereitungsschritte (kurz und präzise)
  explanation: string              // Fachliche Begründung des Koch-Agenten für diesen Vorschlag
}
```

---

## 4. Geschäftsregeln (Business Rules)

### 4.1 Verfallslogik & Inferenzfilter
*   **Berechnung**: Ein Lebensmittel gilt als abgelaufen (verfallen), wenn das Ablaufdatum vor dem heutigen Tag liegt:
    ```typescript
    expiresAt < today
    ```
*   **Statusdefinitionen & Verhalten im UI**:
    
    | Status | Bedingung | UI-Farbkennzeichnung | Verhalten |
    | :--- | :--- | :--- | :--- |
    | **Frisch** | `expiresAt > today` | Soft Green (`#6BA368`) | Vollständig auswählbar |
    | **Läuft heute ab** | `expiresAt == today` | Warm Orange (`#F4A261`) | Auswählbar + Warnung im Badge |
    | **Abgelaufen** | `expiresAt < today` | Soft Red (`#D84C3F`) | Deaktiviert, visuell ausgegraut |

*   **Inferenzfilter (MHD-Schutz)**:
    Abgelaufene Zutaten dürfen **unter keinen Umständen** an den AI-Rezept-Agenten gesendet werden. Das System filtert diese vor der Anfrage heraus, um sicherzustellen, dass keine gesundheitsschädlichen Empfehlungen generiert werden.

### 4.2 Sortierung der Lebensmittelliste
Die Lebensmittelliste wird im Frontend standardmäßig wie folgt sortiert:
1.  **Ablauf-Dringlichkeit**: Lebensmittel, die abgelaufen sind oder kurz vor dem Ablauf stehen (heute/morgen), werden ganz oben angezeigt.
2.  **Alphabetisch**: Zutaten mit demselben Ablaufdatum werden alphabetisch nach Namen sortiert.

### 4.3 AI-Agent „Koch“: Verhalten & Match-Score
*   **Rolle des Agenten**: Der Agent agiert als pragmatischer Koch, kreativer Resteverwerter und motivierender Foodwaste-Berater.
*   **Ziele**:
    *   Lebensmittelverschwendung minimieren.
    *   Möglichst vollständige Verwertung der übergebenen Zutaten anstreben.
    *   Pflichtzutaten, die der Benutzer zukaufen müsste, auf ein absolutes Minimum reduzieren.
    *   Einfache, alltagstaugliche und realistisch kochbare Rezepte vorschlagen.
*   **Berechnung des Match-Scores**:
    Der Match-Score wird nicht über eine starre mathematische Formel berechnet, sondern vom Rezept-Agenten (Gemini 2.5 Flash) semantisch geschätzt. Kriterien sind:
    1.  **Zutaten-Abdeckung**: Verhältnis von verwendeten Bestandzutaten zu zusätzlich benötigten Zukäufen.
    2.  **Food-Waste-Priorisierung**: Ein Bonus fließt in den Score ein, wenn Zutaten mit sehr nahem Verfallsdatum vollständig verwertet werden.
*   **Backend-Normalisierung (Robustness Layer)**:
    Da LLMs den Match-Score gelegentlich als Prozentzahl (z.B. `95` oder `95.0`) statt als Dezimalbruch (`0.95`) zurückliefern, führt das Backend nach dem Empfang der KI-Antwort eine Normalisierung durch. Werte über `1.0` werden durch `100` geteilt und der Endwert wird strikt auf das Intervall `[0.0, 1.0]` begrenzt.
*   **Prompt-Security & Leitplanken**:
    Der Rezept-Agent (`cook_agent`) ist durch ein strukturiertes System-Prompt (`system_recipe_assistant.md`) abgesichert:
    *   **Context Enforcement**: Der Agent beantwortet ausschließlich Anfragen im Kontext von Kochen, Rezepten und Lebensmitteln.
    *   **Jailbreak-Schutz**: Systemanweisungen können nicht durch Benutzereingaben überschrieben werden.
    *   **Schadcode-Schutz**: Bei unsinnigen, schädlichen oder themenfremden Eingaben führt der Agent keine Aktionen aus und liefert ein leeres Rezept-Array zurück.

---

## 5. Design-System & Style-Tokens

Das Design-System ist vollständig als **Tailwind v4 Theme** in `assets/css/main.css` definiert und folgt dem Konzept **„Warm Premium Off-White Sand“**.

### 5.1 Designprinzipien
*   **Mobile First**: Optimierung für die Einhandbedienung am Smartphone (Thumb Navigation, vertikales Scrollen, große Touch-Flächen von mind. 44px).
*   **Ruhe statt Überladung**: Reduktion von visuellem Rauschen. Keine harten roten Rahmen oder dicken Ränder mehr. Stattdessen weiche, schattenbasierte Tiefe, abgerundete Ecken und großzügiger Weißraum.
*   **Positive Emotionalisierung**: Der Retter-Gedanke steht im Vordergrund. Die App wirkt frisch, gesund und modern – niemals belehrend oder moralisierend.

### 5.2 Farbpalette
*   **Background**: `#F7F5F2` (Warmes Premium Off-White Sand)
*   **Surface**: `#FFFFFF` (Kartenhintergrund, Formulare)
*   **Primary**: `#D84C3F` (Terrakotta / Soft Red – für Buttons und Löschaktionen)
*   **Secondary**: `#6BA368` (Soft Green – für Frische-Indikatoren und Match-Scores)
*   **Accent**: `#F4A261` (Warm Orange – für AI-Insights und MHD-Warnungen)
*   **Text Primary**: `#1F1F1F` (Tiefes Anthrazit für exzellente Lesbarkeit)
*   **Text Secondary / Muted**: `#666666` (Dezentes Grau für Untertitel und Metadaten)
*   **Border**: `#EBE8E2` (Sehr weiches Warm-Grau für dezente Linien & Umrandungen)

### 5.3 Typografie
*   **Primärschriftart**: `Inter` (saubere, moderne serifenlose Schrift).
*   **Hierarchie**:
    *   **App-Titel (Hero)**: 40–48px, Extrabold (`font-extrabold`), kompakter Zeilenabstand.
    *   **Sektionen**: 20–24px, Bold (`font-bold`).
    *   **Karten-Titel**: 18–22px, Bold (`font-bold`).
    *   **Fließtext**: 14–16px, Regular / Medium (`font-medium`).
    *   **Metadaten / Labels**: 12px, Bold / Medium (`tracking-wide`).

### 5.4 Layoutsystem & Grid
*   **Grid**: 4px Base Grid mit 16px (1rem) seitlichem Padding und 24px (1.5rem) vertikalem Rhythmus.
*   **Schatten (Shadow System)**:
    `box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);` für Standardkarten,
    `box-shadow: 0 4px 16px rgba(0, 0, 0, 0.06);` bei Hover-Effekten mit subtilen Micro-Interaktionen (z. B. `-translate-y-[0.5px]` Übergang).

---

## 6. Component-Spec & UX Layouts

### 6.1 Hauptseite Layout
Die Anwendung ist als kompakter Single-Page-Flow konzipiert:
```text
┌──────────────────────────────────────┐
│             NoFoodWaste              │
│     Dein intelligenter Assistent     │
├──────────────────────────────────────┤
│ 🍎 MEINE LEBENSMITTEL                │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 🧅 Zwiebeln                      │ │
│ │ 2 Stück      MHD: 30.05.2026     │ │
│ └──────────────────────────────────┘ │
│                                      │
│  + Neues Lebensmittel hinzufügen     │
├──────────────────────────────────────┤
│ 🍳 REZEPTVORSCHLÄGE                  │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ [ Ideen finden (3 Zutaten) ]     │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 🍝 Pasta della Casa              │ │
│ │ 95% Match   ⏱ 15 Min             │ │
│ │ ⚠ AI Insight: Nutzt ablaufende   │ │
│ │   Zwiebeln                       │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### 6.2 Lebensmittel-Karte (`IngredientCard.vue`)
*   **Visuals**: Weiße Floating-Karten mit weichen Schatten, Name des Lebensmittels, Menge und Einheit sowie dem Verfallsdatum (MHD).
*   **Zustands-Badges (Farbpriorisierung)**:
    *   **Frisch**: Soft Green Badge mit grünem Text (`bg-secondary/10 text-secondary`)
    *   **Läuft heute ab**: Warm Orange Badge mit orangefarbenem Text (`bg-accent/10 text-accent`)
    *   **Abgelaufen**: Soft Red Badge mit rotem Text (`bg-primary/10 text-primary`)
*   **Aktionen (Edit / Delete)**:
    *   Diskrete, auf Hover reagierende Buttons für Bearbeiten (Stift-Icon) und Löschen (Mülleimer-Icon).
    *   Bei Klick auf Bearbeiten klappt die Karte in den **Inline-Edit-Modus** um, in dem Name, Menge, Einheit und Datum direkt editiert werden können.

### 6.3 Add-Food Formular (`IngredientForm.vue`)
*   **Layout**: Integriert als Expandable Card, um das UI nicht zu überladen.
*   **CTA**: "Lebensmittel speichern" in voller Breite, farblich abgehoben.

### 6.4 Rezept-Karte (`RecipeCard.vue`)
Das emotionale Herzstück der Anwendung.
*   **Header**: Rezeptname, Match-Score (z.B. `95% Match`), geschätzte Zubereitungszeit.
*   **AI Insight Box**: Ein dezent orangefarben hinterlegter Bereich (`bg-accent/5 border border-accent/20`), der dem Benutzer kurz erklärt, warum das Rezept empfohlen wird (z. B. *"Verbraucht Eier, die morgen ablaufen"*).
*   **Zutaten-Bereiche (Zweispaltiges Grid)**:
    *   **Verwendet (Grün)**: Liste der genutzten Bestandteile mit Häkchen-Icon.
    *   **Fehlt noch (Rot/Neutral)**: Zusätzlich benötigte Pflichtzutaten. Wenn alle vorhanden sind, erscheint ein einladendes *"Alles da!"*.
*   **Optionale Veredelung**: Ein kompakter Bereich für zusätzliche Verfeinerungen.
*   **Zubereitungsschritte**: Eine nummerierte, gut lesbare Schritt-für-Schritt Anleitung.
*   **Erklärungstext**: Eine kurze Begründung des Koch-Agenten zur Abrundung.
*   **CTA-Button**: "Jetzt kochen" (Primary Color) als direkte Handlungsaufforderung.

---

## 7. AI-Interaktionsgefühl & Tonality

*   Der Koch-Agent verhält sich wie ein pragmatischer, professioneller und kreativer Küchenhelfer, nicht wie ein distanzierter Tech-Chatbot.
*   **Sprachstil**:
    *   Kurz, prägnant und fokussiert.
    *   Pragmatisch und alltagsnah.
    *   Positiv und motivierend.
    *   Keine künstliche Begeisterung oder überflüssige Erklärungen.

---

## 8. Barrierefreiheit (Accessibility)

*   **Große Touch-Targets**: Interaktive Buttons haben eine Mindestgröße von `44px` für einfache Bedienbarkeit mit dem Daumen.
*   **Hoher Farbkontrast**: Alle Textfarben erfüllen die WCAG-Kontrastanforderungen zur mühelosen Lesbarkeit bei schwierigen Lichtverhältnissen in der Küche.
*   **Keine rein farbcodierte Bedeutung**: Statusänderungen (wie der Verfall einer Zutat) werden immer durch begleitenden Text (z.B. *„Abgelaufen“*, *„Frisch“*) und entsprechende Symbole verdeutlicht.
*   **Semantisches HTML5**: Einsatz nativer Tags wie `<main>`, `<section>`, `<header>`, `<h1>`, `<h2>` zur bestmöglichen Unterstützung von Screenreadern.
