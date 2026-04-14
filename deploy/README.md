# OpenClaw Production Deployment

Production-ready Docker setup for running OpenClaw as an always-on autonomous
agent system.

## Quick Start

```bash
# 1. Configure environment
cp .env.production.example .env
# Edit .env with your API keys (at minimum: one LLM provider + gateway token)

# 2. First-time setup (builds image + runs onboarding)
./start.sh --setup

# 3. Start the gateway
./start.sh

# 4. Open the dashboard
open http://localhost:18789
```

## Commands

| Command | What it does |
|---|---|
| `./start.sh --setup` | First-time build + onboarding wizard |
| `./start.sh` | Start gateway (default) |
| `./start.sh --browser` | Start gateway + browser sandbox with VNC |
| `./start.sh --stop` | Stop all services |
| `./start.sh --status` | Health check |
| `./start.sh --logs` | Tail gateway logs |
| `./start.sh --cli <cmd>` | Run any openclaw CLI command |

## Adding Agents

```bash
# Add a dedicated research agent with its own workspace
./start.sh --cli agents add research-agent

# Add another agent for a different use case
./start.sh --cli agents add deals-agent

# Set the model for an agent
./start.sh --cli models set deepseek/deepseek-chat
```

## Adding Channels

```bash
# Slack (recommended - needs bot token + app token in .env)
./start.sh --cli channels add --channel slack

# Telegram
./start.sh --cli channels add --channel telegram --token YOUR_BOT_TOKEN

# Discord
./start.sh --cli channels add --channel discord --token YOUR_BOT_TOKEN
```

## Setting Up Cron Jobs

Once running, tell your agent in Slack:
- "Check the Maricopa County tax auction site every morning at 8am and
  notify me of new listings"
- The agent will use its built-in cron_tool to schedule this automatically

## Architecture

```
docker-compose.prod.yml
  |
  |- openclaw-gateway     (always-on, port 18789)
  |    |- Slack/Telegram/Discord connections
  |    |- Agent runtime (tool-calling loop)
  |    |- Cron scheduler
  |    |- Vector memory (SQLite)
  |    |- Built-in Playwright browser
  |
  |- openclaw-cli         (on-demand, for management)
  |
  |- openclaw-browser     (optional, VNC debugging)
       |- Chromium + noVNC viewer on port 6080
```

## Files

| File | Purpose |
|---|---|
| `docker-compose.prod.yml` | Production compose with all services |
| `.env.production.example` | Template - copy to `.env` and fill in |
| `start.sh` | Convenience wrapper for common operations |
| `workspace/SOUL.md` | Agent personality and principles |
| `workspace/USER.md` | Your preferences and budget rules |

## Using Local Ollama

If you run Ollama on the host machine (e.g., Mac Studio):

```bash
# Start Ollama and pull a model
ollama pull gemma2:27b

# The .env already points to host.docker.internal:11434
# Set it as the default model:
./start.sh --cli models set ollama/gemma2:27b
```

## Deploying to Google Cloud Run

When you're ready to move to the cloud:

```bash
# Build and push to Google Container Registry
docker build -t gcr.io/YOUR_PROJECT/openclaw:latest \
  --build-arg OPENCLAW_INSTALL_BROWSER=1 \
  -f ../Dockerfile ..

docker push gcr.io/YOUR_PROJECT/openclaw:latest

# Deploy to Cloud Run
gcloud run deploy openclaw \
  --image gcr.io/YOUR_PROJECT/openclaw:latest \
  --min-instances=1 \
  --memory=2Gi \
  --port=18789 \
  --set-env-vars="OPENCLAW_GATEWAY_TOKEN=your-token,DEEPSEEK_API_KEY=your-key"
```

Note: For Cloud Run, use a managed database (Cloud SQL/Firestore) for
persistent state instead of Docker volumes.
