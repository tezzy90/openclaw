# OpenClaw Production Deployment

Production-ready Docker setup for running OpenClaw as an always-on autonomous
agent system. **Uses the official `ghcr.io/openclaw/openclaw:latest` image
from GitHub Container Registry** — always the latest stable release,
independent of this fork's source code.

## ⚠️ Important: Claude Subscription Policy (April 2026)

As of **April 4, 2026**, Anthropic's TOS prohibits using Claude Pro/Max OAuth
tokens in third-party tools like OpenClaw. Your Claude Pro/Max subscription
CANNOT power OpenClaw's agents. You need a separate Anthropic API key
(pay-as-you-go via Claude Console) if you want Claude models here.

**Recommended approach:** Use DeepSeek API (cheap reasoning) + local Ollama
(free) for the agent runtime. Keep your Claude subscription for direct use
via Claude Code, claude.ai, and Claude Desktop.

## Quick Start

```bash
# 1. Configure environment
cp .env.production.example .env
# Edit .env with your API keys (at minimum: one LLM provider + gateway token)

# 2. First-time setup (pulls latest image + runs onboarding)
./start.sh --setup

# 3. Start the gateway
./start.sh

# 4. Open the dashboard
open http://localhost:18789
```

## Commands

| Command | What it does |
|---|---|
| `./start.sh --setup` | First-time image pull + onboarding wizard |
| `./start.sh` | Start gateway (default) |
| `./start.sh --browser` | Start gateway + browser sandbox with VNC |
| `./start.sh --update` | Pull latest image and restart |
| `./start.sh --stop` | Stop all services |
| `./start.sh --status` | Health check |
| `./start.sh --logs` | Tail gateway logs |
| `./start.sh --cli <cmd>` | Run any openclaw CLI command |

## Why This Setup Is Different

This deployment **does not build from the source code in this repository**.
Instead, it pulls the official pre-built image from GitHub Container Registry:

- `ghcr.io/openclaw/openclaw:latest` — always the newest stable release
- Maintained by the OpenClaw team
- Typically a few hundred MB vs the ~1.5GB you'd get building from source
- One command to upgrade: `./start.sh --update`

You can pin to a specific version if you want stability:
```bash
# In .env:
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:2026.4.14
```

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
# See SLACK-SETUP.md for the step-by-step Slack app creation guide
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

## Upgrading

When a new OpenClaw release comes out (they release frequently — typically
weekly or more):

```bash
./start.sh --update
```

This pulls the latest image, recreates containers, and preserves all your
data (agents, sessions, memory) in Docker volumes.

## Architecture

```
docker-compose.prod.yml
  |
  |- openclaw-gateway     (official image, always-on, port 18789)
  |    |- Slack/Telegram/Discord connections
  |    |- Agent runtime (tool-calling loop)
  |    |- Cron scheduler
  |    |- Vector memory (SQLite)
  |    |- Built-in Playwright browser
  |
  |- openclaw-cli         (on-demand, for management)
  |
  |- openclaw-browser     (optional, VNC debugging, port 6080)
       |- Chromium + noVNC viewer

Docker Volumes (persistent across restarts):
  |- openclaw-config      (gateway config, auth, sessions)
  |- openclaw-workspace   (agent workspaces, memory, files)
```

## Files

| File | Purpose |
|---|---|
| `docker-compose.prod.yml` | Production compose using official image |
| `.env.production.example` | Template - copy to `.env` and fill in |
| `start.sh` | Convenience wrapper for common operations |
| `SLACK-SETUP.md` | Step-by-step Slack app creation guide |
| `workspace/SOUL.md` | Agent personality template |
| `workspace/USER.md.example` | Your preferences template |

## Using Local Ollama

If you run Ollama on the host machine (e.g., Mac Studio):

```bash
# Start Ollama and pull a model
ollama pull gemma2:27b

# The compose file already has extra_hosts: host.docker.internal:host-gateway
# which lets the container reach Ollama on your Mac.
# Set Ollama model as default:
./start.sh --cli models set ollama/gemma2:27b
```

## Deploying to Google Cloud Run

When you're ready to move to the cloud, you can use the same official image:

```bash
gcloud run deploy openclaw \
  --image=ghcr.io/openclaw/openclaw:latest \
  --min-instances=1 \
  --memory=2Gi \
  --port=18789 \
  --set-env-vars="OPENCLAW_GATEWAY_TOKEN=your-token,DEEPSEEK_API_KEY=your-key"
```

Note: For Cloud Run, you'll need a managed database (Cloud SQL/Firestore)
for persistent state instead of Docker volumes.

## Troubleshooting

**Gateway won't start:**
```bash
./start.sh --logs              # See what's failing
./start.sh --cli health --json # Detailed health status
```

**Image pull fails:**
```bash
# Check Docker can reach ghcr.io
docker pull ghcr.io/openclaw/openclaw:latest
```

**Can't connect from host:**
The gateway binds to `lan` mode by default (accessible from host).
If you changed it to `loopback`, only the container can reach it.
