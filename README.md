# claude-jira-prd

A [Claude Code](https://claude.ai/claude-code) custom skill that takes a Jira ticket number and fully automates the path from ticket → code → pull request.

---

## What it does

Type `/jira-prd PW-123` (or paste a full Jira URL) and the plugin:

1. Fetches the Jira ticket via Atlassian MCP
2. Reads any linked Figma designs via Figma MCP
3. Routes the ticket to the affected repos (Frontend, Backend, AI Server, Notifications, AI Cron, Cron Jobs)
4. Does a deep codebase exploration in every affected repo
5. Generates a concrete implementation plan with exact file paths
6. **Waits for your approval** before writing a single line of code
7. Creates feature branches from the correct dev branches
8. Writes the code following each repo's CLAUDE.md conventions
9. Runs type-check and performs a self code-review
10. Commits, pushes, and raises PRs — one per affected repo

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer types:                          │
│             /jira-prd PW-123  or  <Jira URL>                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  STEP 1 — Fetch Ticket                       │
│          Atlassian MCP  →  ticket + AC + Figma links        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 STEP 2 — Fetch Figma (if any)                │
│       Figma MCP  →  screen names, layout, copy, states      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            STEP 3 — Route + Deep Codebase Exploration        │
│                                                              │
│  Routing rules:                                              │
│  • UI / components / chat cards  →  Frontend                 │
│  • API / socket / DB / services  →  Backend                  │
│  • LLM / prompts / embeddings    →  AI Server                │
│  • Push / email / in-app alerts  →  Notifications            │
│  • Scheduled AI jobs             →  AI Cron Server           │
│  • Scheduled data / reports      →  Cron Jobs                │
│                                                              │
│  For every affected repo:                                    │
│  → Read CLAUDE.md (conventions)                              │
│  → Grep for related code                                     │
│  → Read existing service/component/socket files              │
│  → Confirm cross-repo payload contracts                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 4 — Implementation Plan                    │
│                                                              │
│  • Exact file paths (confirmed, not guessed)                 │
│  • What changes in each file and why                         │
│  • New socket events / API endpoints / payload shapes        │
│  • AC coverage mapping                                       │
│  • Out-of-scope items listed explicitly                      │
│                                                              │
│  ⛔ STOPS HERE and asks: "Does this plan look correct?"      │
└──────────────────────┬──────────────────────────────────────┘
                       │  user approves
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           STEP 5 — Create Feature Branches                   │
│                                                              │
│  Frontend       feat/<id>-<slug>  from  dev                  │
│  Backend        feat/<id>-<slug>  from  coolify-dev-v3       │
│  AI Server      feat/<id>-<slug>  from  dev                  │
│  Notifications  feat/<id>-<slug>  from  notif_dev            │
│  AI Cron        feat/<id>-<slug>  from  dev                  │
│  Cron Jobs      feat/<id>-<slug>  from  jobs_dev             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│               STEP 6 — Write Code                            │
│                                                              │
│  • Follows each repo's CLAUDE.md strictly                    │
│  • PWButton / PWTypography / PWIcon only (no raw MUI)        │
│  • socket.on() always paired with socket.off() cleanup       │
│  • No comments / docstrings unless logic is non-obvious      │
│  • Type-check after every repo (npx tsc -b / yarn type-check)│
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 7 — Self Code Review (mandatory)           │
│                                                              │
│  • All ACs covered?                                          │
│  • Edge cases handled?                                       │
│  • Payload contracts match across repos?                     │
│  • No raw MUI / no console.log / no unused vars?             │
│  • Fixes any issues found before committing                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│               STEP 8 — Commit + Push                         │
│                                                              │
│  git add <specific files>  (never git add .)                 │
│  git commit -m "feat(PW-123): ..."                           │
│  git push -u origin feat/<id>-<slug>                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   STEP 9 — Raise PRs                         │
│                                                              │
│  gh pr create for each repo with:                            │
│  • Jira ticket link                                          │
│  • What changed (per file)                                   │
│  • Figma design link                                         │
│  • AC checklist                                              │
│  • Manual test plan                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ✅  Final summary with all PR URLs
```

---

## Repo Map

| Repo | Role | Dev Branch |
|------|------|-----------|
| `pw-react-client-v3` | Frontend (React 18 + TypeScript) | `dev` |
| `pw-server-v3` | Backend (Express + Prisma) | `coolify-dev-v3` |
| `pw-ai-server` | AI Server (OpenAI + LangChain) | `dev` |
| `pw-notifications` | Notifications (FCM / SES / OneSignal) | `notif_dev` |
| `ai-cron-server` | AI Cron (scheduled LLM jobs) | `dev` |
| `pw-cron-jobs` | Data Cron (reports, email, Sheets sync) | `jobs_dev` |

---

## Setup

### 1. Install Claude Code
```bash
npm install -g @anthropic/claude-code
```

### 2. Configure MCP servers

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "${FIGMA_API_KEY}" }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" }
    },
    "atlassian": {
      "command": "npx",
      "args": ["-y", "atlassian-mcp"],
      "env": {
        "ATLASSIAN_API_TOKEN": "${ATLASSIAN_API_TOKEN}",
        "ATLASSIAN_EMAIL": "${ATLASSIAN_EMAIL}",
        "ATLASSIAN_DOMAIN": "${ATLASSIAN_DOMAIN}"
      }
    }
  }
}
```

Add to `~/.zshrc` (or `~/.bashrc`):
```bash
export FIGMA_API_KEY="your-figma-api-key"
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-pat"
export ATLASSIAN_API_TOKEN="your-atlassian-api-token"
export ATLASSIAN_EMAIL="you@yourcompany.com"
export ATLASSIAN_DOMAIN="yourcompany.atlassian.net"
```

### 3. Install the skill

Copy `skills/jira-prd.md` to your global Claude commands:
```bash
cp skills/jira-prd.md ~/.claude/commands/jira-prd.md
```

Or install per-project:
```bash
cp skills/jira-prd.md <your-project>/.claude/commands/jira-prd.md
```

### 4. Copy CLAUDE.md files

Each repo needs its `CLAUDE.md` at its root. Files in `claude-md/` map to repos:

| File | Destination |
|------|-------------|
| `claude-md/frontend.md` | `pw-react-client-v3/CLAUDE.md` (place in `.claude/CLAUDE.md`) |
| `claude-md/backend.md` | `pw-server-v3/CLAUDE.md` |
| `claude-md/ai-server.md` | `pw-ai-server/CLAUDE.md` |
| `claude-md/notifications.md` | `pw-notifications/CLAUDE.md` |
| `claude-md/ai-cron-server.md` | `ai-cron-server/CLAUDE.md` |
| `claude-md/cron-jobs.md` | `pw-cron-jobs/CLAUDE.md` |

---

## Usage

```bash
# From any affected repo directory
/jira-prd PW-123

# Or with a full Jira URL
/jira-prd https://yourcompany.atlassian.net/browse/PW-123
```

---

## Hard Rules (enforced by the skill)

- Never writes code before the plan is approved
- Plan is based on actual file reads — never guesses file paths
- Never uses `git add .` — always stages specific files
- Never force pushes
- Never skips type-check before committing
- Never skips the self code-review step
- Never commits `.env` or secret files
- Cross-repo payloads are verified to match on both ends before committing
