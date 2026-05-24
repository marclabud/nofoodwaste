# Technische Features & Architektur-Vorteile (NoFoodWaste)

Dieses Dokument beschreibt die Kernarchitektur und die technischen Vorteile des **NoFoodWaste**-Projekts. Die Architektur vereint modernste KI-gestützte Logik mit einer hocheffizienten, kostengünstigen und portablen Cloud-Infrastruktur.

---

## 🧠 Intelligente KI-Agenten zur Rezepterstellung (LLM)

Die App nutzt fortschrittliche Large Language Models (LLMs) über die Gemini API, um Lebensmittelverschwendung aktiv zu reduzieren.

*   **Dynamische Echtzeit-Kreation statt starrer Datenbanken:** Keine vordefinierten Rezepte. Der KI-Agent analysiert die exakten Reste des Benutzers und generiert in Sekundenbruchteilen maßgeschneiderte, sichere und kreative Rezeptvorschläge.
*   **Kontextsensitives Food-Matching:** Die LLM-Logik berücksichtigt nicht nur die Hauptzutaten, sondern optimiert Rezepte intelligent nach Küchentyp, Portionsgrößen, vorhandenen Gewürzen und individuellen Ernährungspräferenzen (z. B. vegan, vegetarisch, glutenfrei).
*   **Strukturierte Datenintegrität (Type-Safety):** Durch die nahtlose Anbindung von FastAPI und Pydantic liefert das LLM strikt validierte JSON-Objekte. Dies garantiert eine fehlerfreie, strukturierte Anzeige von Zutatenlisten, Mengenangaben und Zubereitungsschritten im Nuxt-Frontend.

---

## ⚡ Serverless Container-Infrastruktur (Cloud Run & Docker)

Die gesamte Infrastruktur ist auf maximale Effizienz, Skalierbarkeit und minimale Betriebskosten ausgelegt.

*   **Skalierung bis auf Null & $0 Standby-Kosten:** Dank modernster Serverless-Container-Technologie (**Google Cloud Run**) verbraucht die Anwendung im Leerlauf keinerlei Ressourcen. Sie skaliert bei Inaktivität vollautomatisch auf exakt null Instanzen herunter. Kosten entstehen ausschließlich bei aktiver Nutzung.
*   **100 % Konsistenz durch Containerisierung:** Verpackt in standardisierte Docker-Images läuft die App in jeder Umgebung absolut identisch. Dies eliminiert Kompatibilitätsprobleme zwischen lokaler Entwicklung (z. B. macOS mit Podman/Docker) und der Google Cloud-Produktionsumgebung.
*   **Hochverfügbares, serverless Frontend (Firebase CDN):** Das Nuxt-Frontend wird statisch generiert und über das weltweite, wartungsfreie Content Delivery Network von **Firebase Hosting** ausgeliefert. Dies sorgt für minimale Ladezeiten (Core Web Vitals im Spitzenbereich) bei maximaler Ausfallsicherheit.
*   **Zukunftssicher & Cloud-Agnostisch:** Durch die konsequente Kapselung in Docker-Container ist die Anwendung hochgradig portabel. Sie kann jederzeit ohne Code-Änderungen auf andere Cloud-Plattformen oder eigene On-Premise-Server migriert werden.
