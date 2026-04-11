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
9. Runs type-check and performs a mandatory self code-review
10. Commits, pushes, and raises PRs — one per affected repo

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Developer types:                            │
│               /jira-prd PW-123  or  <Jira URL>                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │     Claude Code (claude CLI) │
          │  Skill: skills/jira-prd.md  │
          │                             │
          │  allowed-tools:             │
          │   Bash   Read   Write       │
          │   Edit   Glob   Grep        │
          │   Agent (spawns subagents)  │
          └──────┬──────────────┬───────┘
                 │              │
       ┌─────────▼──┐    ┌──────▼──────┐
       │  MCP Plugins│    │  CLI Tools  │
       │             │    │             │
       │  atlassian  │    │  git        │
       │  → Jira     │    │  gh         │
       │             │    │  npx tsc    │
       │  figma      │    │  yarn / npm │
       │  → Designs  │    │             │
       │             │    └─────────────┘
       │  github     │
       │  → PRs      │
       └─────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  STEP 1 — Fetch Jira Ticket (atlassian MCP)                    │
│  ticket title + description + AC + linked Figma URLs           │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 2 — Fetch Figma Designs (figma MCP, if links found)      │
│  screens, layout, copy, component names, states                 │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 3 — Route + Deep Codebase Exploration                    │
│                                                                 │
│  Routing rules:                                                 │
│  • UI / components / chat cards  →  Frontend                   │
│  • API / socket / DB / services  →  Backend                    │
│  • LLM / prompts / embeddings    →  AI Server                  │
│  • Push / email / in-app alerts  →  Notifications              │
│  • Scheduled AI jobs             →  AI Cron Server             │
│  • Scheduled data / reports      →  Cron Jobs                  │
│                                                                 │
│  For every affected repo (uses Glob + Grep + Read tools):      │
│  → Read CLAUDE.md — understand conventions                     │
│  → Grep for related existing code by domain keywords           │
│  → Read service / controller / component / socket files        │
│  → Confirm cross-repo payload contracts match                  │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 4 — Implementation Plan                                  │
│                                                                 │
│  • Exact file paths (confirmed by reads, never guessed)        │
│  • What to change in each file and why                         │
│  • New socket events / API endpoints / payload shapes          │
│  • AC coverage mapping                                         │
│  • Out-of-scope items listed explicitly                        │
│                                                                 │
│  ⛔ STOPS and asks: "Does this plan look correct?"             │
└────────────────────────┬───────────────────────────────────────┘
                         │  user approves ("looks good")
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 5 — Create Feature Branches (Bash: git)                  │
│                                                                 │
│  Frontend       feat/<id>-<slug>  from  dev                    │
│  Backend        feat/<id>-<slug>  from  coolify-dev-v3         │
│  AI Server      feat/<id>-<slug>  from  dev                    │
│  Notifications  feat/<id>-<slug>  from  notif_dev              │
│  AI Cron        feat/<id>-<slug>  from  dev                    │
│  Cron Jobs      feat/<id>-<slug>  from  jobs_dev               │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 6 — Write Code (Read → Edit / Write tools)               │
│                                                                 │
│  • Reads every file before editing — never blind edits         │
│  • Follows each repo's CLAUDE.md strictly                      │
│  • Type-checks after each repo (Bash: npx tsc-b / yarn type-check)│
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 7 — Self Code Review (Bash: git diff HEAD)               │
│                                                                 │
│  • All ACs covered? Edge cases handled?                        │
│  • Payload contracts match across repos?                       │
│  • No raw MUI / no console.log / no unused vars?               │
│  • Fixes any issues found before committing                    │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 8 — Commit + Push (Bash: git add / commit / push)        │
│                                                                 │
│  git add <specific files>  ← never git add .                   │
│  git commit -m "feat(<id>): ..."                               │
│  git push -u origin feat/<id>-<slug>                           │
└────────────────────────┬───────────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────────┐
│  STEP 9 — Raise PRs (Bash: gh pr create)                       │
│                                                                 │
│  gh pr create per repo with:                                   │
│  • Jira ticket link + Figma link                               │
│  • What changed per file                                       │
│  • AC checklist + manual test plan                             │
└────────────────────────┬───────────────────────────────────────┘
                         │
                         ▼
              ✅  Final summary — all PR URLs printed
```

---

## Tools Used

### MCP Plugins

| Plugin | npm package | What it does |
|--------|-------------|-------------|
| **Atlassian** | `atlassian-mcp` | Fetches Jira ticket — title, description, AC, status |
| **Figma** | `figma-developer-mcp` | Reads Figma designs linked in the ticket |
| **GitHub** | `api.githubcopilot.com/mcp/` | GitHub API access for PR creation |

### Claude Code Built-in Tools

| Tool | Used for |
|------|---------|
| `Bash` | git, gh CLI, tsc, yarn — any shell command |
| `Read` | Reading source files before editing |
| `Edit` | Making targeted edits to existing files |
| `Write` | Creating new files |
| `Glob` | Finding files by pattern across repos |
| `Grep` | Searching code for keywords, function names, event names |
| `Agent` | Spawning subagents for deep parallel codebase exploration |

### CLI Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `node` + `npx` | Runs MCP servers, type-check | https://nodejs.org |
| `git` | Branching, committing, pushing | https://git-scm.com |
| `gh` | GitHub CLI — creating PRs | https://cli.github.com |
| `yarn` | Frontend / backend package manager | `npm i -g yarn` |

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

## Quick Install

```bash
# 1. Clone the repo
git clone https://github.com/sudheer8177/claude-jira-prd.git
cd claude-jira-prd

# 2. Run the setup script
bash setup.sh
```

`setup.sh` will:
- Check all CLI dependencies (node, git, gh)
- Install Claude Code if missing
- Copy the skill to `~/.claude/commands/jira-prd.md`
- Copy MCP settings to `~/.claude/settings.json`
- Print instructions for secrets + CLAUDE.md placement

---

## Manual Setup

### 1. Install Claude Code
```bash
npm install -g @anthropic/claude-code
```

### 2. Install the skill
```bash
# Global (available in all projects)
cp skills/jira-prd.md ~/.claude/commands/jira-prd.md

# Or per-project only
cp skills/jira-prd.md <your-project>/.claude/commands/jira-prd.md
```

### 3. Configure MCP plugins (Jira + Figma + GitHub)

Full plugin details in [`mcp/README.md`](mcp/README.md).

```bash
# Copy settings template (uses ${VAR} env var references — no secrets in the file)
cp mcp/settings.json ~/.claude/settings.json
```

Add to `~/.zshrc` (or `~/.bashrc`) — see [`mcp/SECRETS.template.md`](mcp/SECRETS.template.md) for where to get each key:

```bash
export FIGMA_API_KEY="figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_API_TOKEN="ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_EMAIL="you@yourcompany.com"
export ATLASSIAN_DOMAIN="yourcompany.atlassian.net"

source ~/.zshrc
```

### 4. Place CLAUDE.md files in each repo

| File in this repo | Copy to |
|-------------------|---------|
| `claude-md/frontend.md` | `pw-react-client-v3/.claude/CLAUDE.md` |
| `claude-md/backend.md` | `pw-server-v3/CLAUDE.md` |
| `claude-md/ai-server.md` | `pw-ai-server/CLAUDE.md` |
| `claude-md/notifications.md` | `pw-notifications/CLAUDE.md` |
| `claude-md/ai-cron-server.md` | `ai-cron-server/CLAUDE.md` |
| `claude-md/cron-jobs.md` | `pw-cron-jobs/CLAUDE.md` |

### 5. Verify MCP plugins are connected

Start Claude Code inside any project and run:
```
/mcp
```
You should see `atlassian`, `figma`, and `github` listed as connected.

---

## Usage

```bash
# From any repo directory, start Claude Code
claude

# Then run the skill
/jira-prd PW-123

# Or with a full Jira URL
/jira-prd https://yourcompany.atlassian.net/browse/PW-123
```

The skill will stop and ask for approval before writing any code.

---

## File Structure

```
claude-jira-prd/
  setup.sh                      ← one-command install script
  skills/
    jira-prd.md                 ← the Claude Code skill (all 10 steps)
  mcp/
    settings.json               ← MCP config (Figma + Atlassian + GitHub)
    README.md                   ← how to get each API key
    SECRETS.template.md         ← template for ~/.claude/SECRETS.md
  claude-md/
    frontend.md                 ← pw-react-client-v3 conventions
    backend.md                  ← pw-server-v3 conventions
    ai-server.md                ← pw-ai-server conventions
    notifications.md            ← pw-notifications conventions
    ai-cron-server.md           ← ai-cron-server conventions
    cron-jobs.md                ← pw-cron-jobs conventions
  README.md
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
