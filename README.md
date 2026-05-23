# NoFoodWaste: Recipe Finder MVP

![NoFoodWaste](https://via.placeholder.com/800x200.png?text=NoFoodWaste)

**NoFoodWaste** is an intelligent, AI-powered recipe finder designed to help you reduce food waste. By tracking your available ingredients and their expiration dates, the app uses an LLM to suggest practical and delicious recipes that prioritize ingredients that are about to expire.

## 🎯 Goal

The main objective of this MVP is to answer the question: **Can an LLM generate meaningful, food-waste-oriented recipes from existing ingredients?** It is designed as a fast, sustainable decision support tool rather than a comprehensive cooking platform.

## ✨ Features

- **Ingredient Management:** Add, edit, and store your current food inventory.
- **Expiration Tracking:** Automatically warns you about ingredients expiring today and prevents the use of expired items.
- **LLM-Powered Suggestions:** Send your available ingredients to an LLM to receive 1-3 tailored recipe suggestions.
- **Food-Waste Prioritization:** Recipes clearly state *why* they were suggested (e.g., prioritizing ingredients expiring soon).
- **LLM Integration:** Utilizes OpenAI's **Structured Outputs** feature (via Pydantic) to ensure highly reliable, schema-validated responses.
- **Mobile-First Design:** A simple, card-based action UI optimized for quick decision-making.

## 🏗 Architecture

This project is structured as a monorepo containing both the frontend and backend applications.

- **Frontend:** Nuxt 4 & TailwindCSS 4 (located in `Apps/Frontend`)
- **Backend:** Python (located in `Apps/Backend`)
- **Package Manager:** `pnpm` (Workspace setup)

## 🚀 Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (v24 or higher)
- [pnpm](https://pnpm.io/) (v10 or higher)
- Python 3.x (for the backend)
- An active LLM API Key (e.g., Gemini API key from [Google AI Studio](https://aistudio.google.com/) or OpenAI)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd NoFoodWaste
   ```

2. Install dependencies for all workspace packages:
   ```bash
   pnpm install
   ```

3. Configure your environment variables for both the backend (API keys) and frontend as required by the specific applications.

### Running the App Locally

To start the development servers for both the frontend and backend simultaneously, run:

```bash
pnpm run dev
```

You can also build, lint, or test the entire project using:
- `pnpm run build`
- `pnpm run lint`
- `pnpm run test`

### Running with Podman (Containerized)

If you prefer to run the application inside local OCI containers, a native Podman orchestration setup is fully supported. This configures a local private network, builds production-ready images, and mounts a persistent SQLite volume.

To orchestrate the containers, use the following `pnpm` commands from the project root:

1. **Build backend and frontend images:**
   ```bash
   pnpm podman:build
   ```

2. **Start the containers in the background:**
   ```bash
   pnpm podman:up
   ```
   *(Note: This will automatically start the Podman machine on macOS if it is not already running.)*

3. **Check container status:**
   ```bash
   pnpm podman:status
   ```

4. **Stream real-time log output:**
   ```bash
   pnpm podman:logs
   ```

5. **Stop and remove the containers:**
   ```bash
   pnpm podman:down
   ```

Once started, the services will be accessible at:
- **Frontend App:** [http://localhost:3000](http://localhost:3000)
- **Backend API:** [http://localhost:8000](http://localhost:8000)
- **API Swagger Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)

For advanced settings, setting up Podman Compose, or troubleshooting macOS socket connections, please refer to the detailed [macOS Podman Setup Guide](docs/Podman_Setup.md).

## 📖 Specifications and Documentation

For detailed business logic, constraints, and architecture decisions, please refer to the documents located in the `specs/` and `docs/` directories:
- **Business Specs:** `specs/business/food-waste-mvp.spec.md`
- **Documentation:** Check `docs/` for security guidelines, training agendas, and other project references.

## 📝 License

This project is private and intended for development and demonstration purposes.
