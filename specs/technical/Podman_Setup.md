# 🦭 Running NoFoodWaste with Podman on macOS

This guide provides everything you need to build and run the **NoFoodWaste** monorepo using **Podman** on macOS. 

Since you have Podman installed at `/opt/podman/bin/podman` but do not have `podman-compose` in your path, you have two excellent, premium options to run the application:

1. **Option A: Built-in Podman Orchestration (Recommended & Automated)** — Uses a highly-optimized orchestration script (`run-podman.sh`) integrated directly into your `package.json` `pnpm` tasks. No extra dependencies required!
2. **Option B: Setting up Podman Compose** — A quick 1-minute setup to enable `podman-compose` or `docker-compose` support so that standard `docker-compose` commands work natively with Podman.

---

## 🚀 Option A: Built-in Podman Orchestration (Recommended)

We have created an extremely powerful, native shell helper script `run-podman.sh` at the root of the project and integrated it directly into your `package.json`. 

This script handles the creation of a secure local container network, configures the SQLite persistent volume, loads environment variables (including your `GEMINI_API_KEY`), and orchestrates the backend and frontend services.

### How to use with `pnpm` (No need to make executable!)

You can run these scripts directly using `pnpm` from the project root:

| Command | Action | Description |
| :--- | :--- | :--- |
| `pnpm podman:build` | **Build** | Builds clean, production-ready backend and frontend OCI images using Podman. |
| `pnpm podman:up` | **Start** | Performs cleanup, creates networks/volumes, and launches backend and frontend in the background. |
| `pnpm podman:status` | **Status** | Shows the active status of both containers, their ports, and run health. |
| `pnpm podman:logs` | **Logs** | Streams output logs in real-time from both frontend and backend. |
| `pnpm podman:down` | **Stop** | Gracefully stops and cleans up all running containers. |

### Accessing the Application

Once you run `pnpm podman:up`, the containers are spun up securely:
- 🖥️ **Frontend Web UI:** [http://localhost:3000](http://localhost:3000)
- ⚙️ **Backend FastAPI Server:** [http://localhost:8000](http://localhost:8000)
- 📖 **Interactive Swagger API Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)

> [!TIP]
> Under the hood, the frontend's Nginx configuration automatically proxies all requests from `/api/*` to the backend on the internal container network (`nofoodwaste-net`). 
> SQLite database persistent data is safely stored in a local volume named `nofoodwaste-sqlite` so your ingredients aren't lost when you stop the container!

---

## 🛠️ Option B: Setting up Podman Compose

If you prefer to use the standard `docker-compose.yml` file, you can easily install and configure compose support.

### 1. Install compose provider
You can install either `podman-compose` or the standard `docker-compose` CLI using Homebrew:

```bash
# To install podman-compose:
brew install podman-compose

# OR to install standard docker-compose (which integrates beautifully with Podman):
brew install docker-compose
```

### 2. Connect Compose to Podman Socket
For compose tools to talk to Podman on macOS, ensure the Podman machine is running and set the `DOCKER_HOST` environment variable to point to the socket.

```bash
# 1. Start the podman machine
podman machine start

# 2. Get the connection URI
podman machine inspect --format '{{.ConnectionInfos.podman.Uri}}'

# 3. Export DOCKER_HOST to your shell profile (.zshrc)
export DOCKER_HOST="unix://$HOME/.local/share/containers/podman/machine/qemu/podman.sock"
```

Once done, you can run normal compose commands:
```bash
podman compose up -d
# or if you installed docker-compose
docker-compose up -d
```

---

## ⚙️ Configuration & Security Notes

> [!IMPORTANT]
> The orchestrator automatically loads environment variables from [Apps/Backend/.env](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/.env).
> Your Gemini API Key is fully loaded and ready to be utilized by the backend AI agent to generate delicious, waste-free recipes!

### Troubleshooting
- **Podman Machine Status**: If you receive network or connection errors, verify your virtual machine is running with:
  ```bash
  podman machine list
  ```
- **Port Conflict**: Make sure ports `3000` (frontend) and `8000` (backend) are not occupied by local processes.
