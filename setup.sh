#!/bin/bash
# setup.sh — Install claude-jira-prd plugin
# Run: bash setup.sh

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  claude-jira-prd — Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Check required CLI tools ───────────────────────────────
echo "▶ Checking dependencies..."

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "  ✗ $1 not found — $2"
    MISSING=1
  else
    echo "  ✓ $1"
  fi
}

MISSING=0
check_cmd node    "install from https://nodejs.org"
check_cmd npx     "comes with Node.js"
check_cmd git     "install from https://git-scm.com"
check_cmd gh      "install from https://cli.github.com"

if [ "$MISSING" = "1" ]; then
  echo ""
  echo "  Please install the missing tools above and re-run setup.sh"
  exit 1
fi

# ── 2. Check Claude Code ──────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo ""
  echo "▶ Installing Claude Code..."
  npm install -g @anthropic/claude-code
else
  echo "  ✓ claude (Claude Code)"
fi

# ── 3. Install the skill ──────────────────────────────────────
echo ""
echo "▶ Installing jira-prd skill..."
mkdir -p ~/.claude/commands
cp skills/jira-prd.md ~/.claude/commands/jira-prd.md
echo "  ✓ Installed to ~/.claude/commands/jira-prd.md"

# ── 4. Configure MCP settings ────────────────────────────────
echo ""
echo "▶ Configuring MCP servers (Figma + Atlassian + GitHub)..."

SETTINGS_FILE=~/.claude/settings.json

if [ -f "$SETTINGS_FILE" ]; then
  echo "  ⚠ $SETTINGS_FILE already exists."
  echo "  Manually merge the mcpServers block from mcp/settings.json into it."
  echo "  (Skipping to avoid overwriting your existing config)"
else
  mkdir -p ~/.claude
  cp mcp/settings.json "$SETTINGS_FILE"
  echo "  ✓ Copied to $SETTINGS_FILE"
fi

# ── 5. CLAUDE.md reminder ────────────────────────────────────
echo ""
echo "▶ CLAUDE.md files (copy to each repo root):"
echo "  claude-md/frontend.md      →  <pw-react-client-v3>/.claude/CLAUDE.md"
echo "  claude-md/backend.md       →  <pw-server-v3>/CLAUDE.md"
echo "  claude-md/ai-server.md     →  <pw-ai-server>/CLAUDE.md"
echo "  claude-md/notifications.md →  <pw-notifications>/CLAUDE.md"
echo "  claude-md/ai-cron-server.md →  <ai-cron-server>/CLAUDE.md"
echo "  claude-md/cron-jobs.md     →  <pw-cron-jobs>/CLAUDE.md"

# ── 6. Secrets reminder ──────────────────────────────────────
echo ""
echo "▶ Secrets — add these to ~/.zshrc or ~/.bashrc:"
echo "  export FIGMA_API_KEY=\"figd_...\""
echo "  export GITHUB_PERSONAL_ACCESS_TOKEN=\"ghp_...\""
echo "  export ATLASSIAN_API_TOKEN=\"ATATT3x...\""
echo "  export ATLASSIAN_EMAIL=\"you@yourcompany.com\""
echo "  export ATLASSIAN_DOMAIN=\"yourcompany.atlassian.net\""
echo ""
echo "  See mcp/SECRETS.template.md for where to get each key."

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Setup complete"
echo ""
echo "  Usage (from any project with Claude Code):"
echo "    /jira-prd PW-123"
echo "    /jira-prd https://yourcompany.atlassian.net/browse/PW-123"
echo ""
echo "  Verify MCP plugins inside a Claude Code session:"
echo "    /mcp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
