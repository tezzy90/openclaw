#!/usr/bin/env bash
# =============================================================================
# OpenClaw Production Startup Script
# =============================================================================
#
# Usage:
#   ./start.sh              # Start gateway only
#   ./start.sh --browser    # Start gateway + browser sandbox
#   ./start.sh --setup      # First-time setup (build + onboard)
#   ./start.sh --stop       # Stop all services
#   ./start.sh --status     # Check health
#   ./start.sh --logs       # Tail gateway logs
#   ./start.sh --cli        # Open interactive CLI
#
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"
ENV_FILE="$SCRIPT_DIR/.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[openclaw]${NC} $*"; }
warn() { echo -e "${YELLOW}[openclaw]${NC} $*"; }
error() { echo -e "${RED}[openclaw]${NC} $*" >&2; }

compose() {
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"
}

check_deps() {
  if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed. Install from https://docker.com"
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    error "Docker Compose not available"
    exit 1
  fi
  if [ ! -f "$ENV_FILE" ]; then
    error ".env file not found. Run: cp .env.production.example .env"
    exit 1
  fi
}

cmd_setup() {
  check_deps
  log "Pulling latest OpenClaw Docker image from ghcr.io..."
  compose pull openclaw-gateway

  # Generate token if still default
  if grep -q "change-me" "$ENV_FILE" 2>/dev/null; then
    local token
    token="$(openssl rand -hex 32)"
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/change-me-to-a-long-random-token/$token/" "$ENV_FILE"
    else
      sed -i "s/change-me-to-a-long-random-token/$token/" "$ENV_FILE"
    fi
    log "Generated gateway token: $token"
    warn "Save this token - you'll need it to connect clients"
  fi

  log "Running onboarding wizard..."
  compose run --rm openclaw-cli onboard --no-install-daemon

  log ""
  log "Setup complete. Start with: ./start.sh"
}

cmd_update() {
  check_deps
  log "Pulling latest OpenClaw image..."
  compose pull
  log "Restarting services with new image..."
  compose --profile browser up -d
  log "Update complete."
}

cmd_start() {
  check_deps
  local profiles=()

  if [[ "${1:-}" == "--browser" ]]; then
    profiles=("--profile" "browser")
    log "Starting gateway + browser sandbox..."
  else
    log "Starting gateway..."
  fi

  compose "${profiles[@]}" up -d

  log ""
  log "OpenClaw is running."
  log "  Dashboard:  http://localhost:${OPENCLAW_GATEWAY_PORT:-18789}"
  if [[ "${1:-}" == "--browser" ]]; then
    log "  Browser VNC: http://localhost:${OPENCLAW_BROWSER_NOVNC_PORT:-6080}"
  fi
  log "  Logs:       ./start.sh --logs"
  log "  Health:     ./start.sh --status"
  log "  Stop:       ./start.sh --stop"
}

cmd_stop() {
  check_deps
  log "Stopping all OpenClaw services..."
  compose --profile browser --profile cli down
  log "Stopped."
}

cmd_status() {
  check_deps
  log "Checking health..."
  compose exec openclaw-gateway node dist/index.js health \
    --token "$(grep OPENCLAW_GATEWAY_TOKEN "$ENV_FILE" | cut -d= -f2)" \
    2>/dev/null || error "Gateway is not running or unhealthy"
}

cmd_logs() {
  check_deps
  compose logs -f openclaw-gateway
}

cmd_cli() {
  check_deps
  compose run --rm openclaw-cli "$@"
}

# ─── Main ────────────────────────────────────────────────────
case "${1:-}" in
  --setup)
    cmd_setup
    ;;
  --update)
    cmd_update
    ;;
  --stop)
    cmd_stop
    ;;
  --status)
    cmd_status
    ;;
  --logs)
    cmd_logs
    ;;
  --cli)
    shift
    cmd_cli "$@"
    ;;
  --browser)
    cmd_start --browser
    ;;
  ""|--start)
    cmd_start
    ;;
  *)
    echo "Usage: $0 [--setup|--update|--start|--browser|--stop|--status|--logs|--cli]"
    exit 1
    ;;
esac
