# NoFoodWaste - Backend Setup & Startup Guide

This directory contains the backend for the **NoFoodWaste** web application. The backend is implemented as a **FastAPI** application in Python, utilizes a local **SQLite** database for managing ingredients, and integrates the **Google ADK (Agent Development Kit) 2.0** for intelligent recipe generation using **Gemini 2.5 Flash**.

---

## 🏗️ System Overview & Setup

The backend comprises the following core components:
*   **`main.py`**: The main entry point of the FastAPI application. It configures CORS for the frontend (`http://localhost:3000`), CRUD endpoints for ingredients (`/ingredients`), and the recipe generation endpoint (`/recipes/generate`).
*   **`database.py`**: Manages the SQLite database (`food_waste.db`). The `ingredients` table is automatically created on startup if it does not exist.
*   **`models.py`**: Pydantic data schemas for validating API requests and responses.
*   **`llm_service.py`**: Acts as the LLM connection service, exposing `LLMProvider` to manage LLM configurations, validate model options, and map choice constants to concrete model names.
*   **`agent_service.py`**: Integrates the Google ADK 2.0. It defines the `cook_agent` which generates structured recipes using the system prompt located in `prompts/system_recipe_assistant.md`, maps selected LLMs via constants, handles execution auditing, and exposes `generate_recipes` for FastAPI.
*   **`requirements.txt`**: Defines python dependencies (FastAPI, Uvicorn, Pydantic, python-dotenv, google-adk).
*   **`.python-version`**: Specifies the target Python version (`3.13.11`).

---

## 🛠️ Prerequisites

Ensure the following are installed on your Mac:
1.  **Python 3.13.x** (Target version: `3.13.11`). If you use `pyenv`, it will automatically select the correct version based on the `.python-version` file.
2.  A **Gemini API Key** from Google AI Studio.

---

## ⚙️ Step-by-Step Setup

Follow these steps in your terminal to set up the backend:

### 1. Navigate to the Backend Directory
Open your terminal and navigate to the backend folder:
```bash
cd /Users/hector/dev/NoFoodWaste/Apps/Backend
```

### 2. Activate or Recreate the Virtual Environment
A `.venv` folder is already provided. You can activate it with:
```bash
source .venv/bin/activate
```

> [!NOTE]
> If the virtual environment is corrupted or needs to be re-created, you can set it up from scratch using:
> ```bash
> # Delete old environment (optional)
> rm -rf .venv
> 
> # Create a new venv using Python 3.13
> python3 -m venv .venv
> 
> # Activate the virtual environment
> source .venv/bin/activate
> 
> # Upgrade pip and install dependencies
> pip install --upgrade pip
> pip install -r requirements.txt
> ```

### 3. Configure Environment Variables (`.env`)
Locate the `.env` file in the backend directory. Open it in your favorite editor (e.g., VS Code or `nano`) and configure your Gemini API Key:

```env
# API Keys for LLM Integration
# Obtain your Gemini API key from Google AI Studio: https://aistudio.google.com/
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE   # <-- Replace this with your actual Gemini API Key!

# LLM Configuration
LLM_MODEL=gemini-2.5-flash

# App Settings
DEBUG=True
ENVIRONMENT=development
```

---

## 🚀 Starting the Backend in the Terminal

Once your virtual environment is active and the `.env` file is configured, start the FastAPI server using **Uvicorn**:

```bash
uvicorn main:app --reload
```

### Understanding the command:
*   `main:app` tells Uvicorn to look for the `app` instance inside `main.py`.
*   `--reload` enables auto-reloading whenever you make changes to your python files, which is ideal for development.

Upon a successful startup, you will see output similar to this:
```text
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

---

## 🔌 Testing & Interactive API Documentation

Once the backend is running at `http://localhost:8000`, you can inspect and interact with it:

### 1. Health Check
Open your browser and navigate to:
👉 [http://localhost:8000/health](http://localhost:8000/health)

You should see the following JSON response:
```json
{
  "status": "ok",
  "message": "FastAPI server is running!"
}
```

### 2. Interactive Swagger UI Docs
FastAPI automatically generates an interactive documentation page where you can run and test all endpoints directly from your browser:
👉 [http://localhost:8000/docs](http://localhost:8000/docs)

*Here you can test:*
*   Retrieving ingredients (`GET /ingredients`)
*   Adding new ingredients (`POST /ingredients`)
*   Deleting ingredients (`DELETE /ingredients/{ingredient_id}`)
*   Updating ingredients (`PUT /ingredients/{ingredient_id}`)
*   Generating recipes via LLM (`POST /recipes/generate`)

### 3. Alternative API Documentation (ReDoc)
For a clean, read-only API reference, visit:
👉 [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## 🛠️ Handy Terminal Commands

*   **Deactivate the Virtual Environment:**
    ```bash
    deactivate
    ```
*   **Update Dependencies:**
    If new packages are added, run:
    ```bash
    pip install -r requirements.txt
    ```
*   **Reset the Database:**
    To reset the ingredient database, simply delete the SQLite file. It will be recreated empty when the server restarts:
    ```bash
    rm food_waste.db
    ```
