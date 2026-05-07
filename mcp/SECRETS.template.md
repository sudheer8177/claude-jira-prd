# SECRETS

> Copy this file to `~/.claude/SECRETS.md` and fill in your real values.
> This file is gitignored — **never commit it with real values**.

---

## GitHub

| Key | Value |
|-----|-------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

**Get it:** GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
**Scopes needed:** `repo`, `read:org`

---

## Figma

| Key | Value |
|-----|-------|
| `FIGMA_API_KEY` | `figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

**Get it:** Figma → Account Settings → Personal access tokens → Generate new token

---

## Atlassian (Jira)

| Key | Value |
|-----|-------|
| `ATLASSIAN_API_TOKEN` | `ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx` |
| `ATLASSIAN_EMAIL` | `you@yourcompany.com` |
| `ATLASSIAN_DOMAIN` | `yourcompany.atlassian.net` |

**Get it:** https://id.atlassian.com/manage-profile/security/api-tokens → Create API token

---

## Repo Local Paths

| Key | Value |
|-----|-------|
| `PW_FRONTEND_PATH` | `/path/to/pw-react-client-v3` |
| `PW_BACKEND_PATH` | `/path/to/pw-server-v3` |
| `PW_AI_SERVER_PATH` | `/path/to/pw-ai-server` |
| `PW_NOTIFICATIONS_PATH` | `/path/to/pw-notifications` |
| `PW_AI_CRON_PATH` | `/path/to/ai-cron-server` |
| `PW_CRON_JOBS_PATH` | `/path/to/pw-cron-jobs` |
| `PW_MCP_SERVER_PATH` | `/path/to/PW-Mcp-Server` |

**Set these** to the absolute paths where you cloned each repo on your machine.

---

## Shell exports (add to ~/.zshrc or ~/.bashrc)

```bash
# API keys
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export FIGMA_API_KEY="figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_API_TOKEN="ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_EMAIL="you@yourcompany.com"
export ATLASSIAN_DOMAIN="yourcompany.atlassian.net"

# Repo local paths
export PW_FRONTEND_PATH="/path/to/pw-react-client-v3"
export PW_BACKEND_PATH="/path/to/pw-server-v3"
export PW_AI_SERVER_PATH="/path/to/pw-ai-server"
export PW_NOTIFICATIONS_PATH="/path/to/pw-notifications"
export PW_AI_CRON_PATH="/path/to/ai-cron-server"
export PW_CRON_JOBS_PATH="/path/to/pw-cron-jobs"
export PW_MCP_SERVER_PATH="/path/to/PW-Mcp-Server"
```
