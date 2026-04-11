---
description: Jira ticket → Claude router → plan → code → review → PR → Coolify preview
argument-hint: <TICKET-ID or Jira URL>  e.g. PW-123 or https://possibleworks.atlassian.net/browse/PW-123
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
---

You are the Claude router for PossibleWorks engineering.

The input is: $ARGUMENTS

Extract the ticket ID from the input (works with bare ID like `PW-123` or full Jira URL).

---

## REPOS

| Repo | Path | GitHub | Dev Branch |
|------|------|--------|------------|
| Frontend | `/Users/sudheer7781/Documents/pw-react-client-v3` | `PossibleWorks/pw-react-client-v3` | `dev` |
| Backend | `/Users/sudheer7781/Documents/pw-server-v3` | `PossibleWorks/pw-server-v3` | `coolify-dev-v3` |
| AI Server | `/Users/sudheer7781/Documents/pw-ai-server` | `PossibleWorks/pw-ai-server` | `dev` |
| Notifications | `/Users/sudheer7781/Documents/pw-notifications` | `PossibleWorks/pw-notifications` | `notif_dev` |
| AI Cron Server | `/Users/sudheer7781/Documents/ai-cron-server` | `PossibleWorks/ai-cron-server` | `dev` |
| Cron Jobs | `/Users/sudheer7781/Documents/pw-cron-jobs` | `PossibleWorks/pw-cron-jobs` | `jobs_dev` |

---

## STEP 1 — Fetch Jira Ticket

Use the `atlassian` MCP to fetch the full ticket for the extracted ID from `possibleworks.atlassian.net`.

Extract and display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ticket : <ID> — <Summary>
  Type   : <Bug | Story | Task | Sub-task>
  Status : <status>
  Reporter: <name>
  Assignee: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Description:
<full description>

Acceptance Criteria:
<AC items, one per line>

Figma Links:
<list any figma.com URLs found — or "None">
```

---

## STEP 2 — Fetch Figma Designs (if any)

If Figma links were found in the ticket, use the `figma` MCP to fetch each one.

For each design extract:
- Screen/component names
- Layout and interaction notes
- Any visible text, labels, states, colors

Display a design summary. If no Figma links → skip and note "No designs attached".

---

## STEP 3 — Route to Repos + Deep Codebase Exploration

### 3a — Route

Read the ticket summary, description, and AC. Decide which repos are affected:

**Routing rules:**
- UI changes, new screens, components, chat cards → **Frontend**
- API endpoints, socket events, DB/Prisma, services → **Backend**
- AI prompts, LLM logic, embeddings, agent flows → **AI Server**
- Push notifications, email notifications, in-app alerts → **Notifications**
- Scheduled AI jobs, initiative/goal automation → **AI Cron Server**
- Scheduled data jobs, reports, cron triggers → **Cron Jobs**
- A feature can affect multiple repos — include all that apply

Display routing result:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Repos affected:
  ✅ Frontend        (pw-react-client-v3)
  ✅ Backend         (pw-server-v3)
  ⬜ AI Server       (not needed)
  ⬜ Notifications   (not needed)
  ⬜ AI Cron Server  (not needed)
  ⬜ Cron Jobs       (not needed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3b — Deep Codebase Exploration (ALL affected repos)

For EVERY affected repo, perform thorough exploration BEFORE writing the plan. This is mandatory — do not skip.

For each affected repo:

1. **Read CLAUDE.md** at root or `.claude/CLAUDE.md` — understand conventions, patterns, forbidden patterns
2. **Search for related existing code** — grep for keywords from the ticket (feature name, entity name, domain terms) to find where similar logic already lives
3. **Read relevant existing files** — if the ticket touches e.g. "initiatives", read the existing initiative files (service, controller, component, socket handlers, types)
4. **Understand the data model** — if backend is affected, read the Prisma schema or relevant DB models
5. **Understand existing socket events** — if socket events are involved, read `src/models/enums/event-names-enum.ts` (Frontend) and the backend socket handler files
6. **Find cross-repo contracts** — identify API endpoints, socket event names, request/response shapes that must match between repos
7. **Check for existing patterns** — how are similar features implemented? Follow the same pattern exactly.

Exploration checklist per repo (run all that are relevant):
- `Glob("**/*.ts", repo_path)` + keyword grep to find relevant files
- Read the entity's service file (Backend)
- Read the entity's controller/router file (Backend)
- Read the entity's Prisma model (Backend)
- Read the existing component folder (Frontend)
- Read `src/constants/utils.ts` (Frontend) — CARD_EVENTS, ACTION_STATUS
- Read `src/models/enums/event-names-enum.ts` (Frontend) — EVENTNAMES_ENUM
- Read `src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts` (Frontend) — existing socket handlers
- Read the existing chat card for the nearest similar feature as a reference implementation

Display a brief exploration summary:
```
─── Codebase Exploration ────────────────────────────────
  Backend:
  - Found: src/services/InitiativeService.ts (existing logic)
  - Found: src/controllers/InitiativeController.ts
  - Prisma model: Initiative (fields: id, title, endDate, ...)
  - Existing socket events: initiative_update, initiative_create

  Frontend:
  - Found: src/components/molecules/InitiativeCard/index.tsx
  - EVENTNAMES_ENUM already has: INITIATIVE_UPDATE
  - CARD_EVENTS already has: initiative_update
  - useSocketEvents.ts: handles initiative_update at line 142
  - Reference card: ApplyLeaveCard (closest pattern match)
─────────────────────────────────────────────────────────
```

---

## STEP 4 — Generate Implementation Plan

Using everything learned in STEP 3, generate a concrete plan with exact file paths (confirmed by exploration, not guessed):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  IMPLEMENTATION PLAN — <TICKET-ID>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branches:
  Frontend        → feat/<ticket-id>-<slug>  (from dev)
  Backend         → feat/<ticket-id>-<slug>  (from coolify-dev-v3)
  Notifications   → feat/<ticket-id>-<slug>  (from notif_dev)
  AI Cron Server  → feat/<ticket-id>-<slug>  (from dev)
  Cron Jobs       → feat/<ticket-id>-<slug>  (from jobs_dev)

─── Cross-Repo Contract ──────────────────────────────────
  Socket event: <event_name>
  Payload shape (Backend → Frontend):
    { field1: type, field2: type, ... }
  API endpoint (if REST): <METHOD /path>
  Request body: { ... }
  Response shape: { ... }

─── Backend Changes (pw-server-v3) ──────────────────────
1. <confirmed file path from exploration>
   - <exactly what to add/change and why>
2. prisma/schema.prisma  (if DB changes needed)
   - <field/model change>
...

─── Frontend Changes (pw-react-client-v3) ───────────────
1. <confirmed file path from exploration>
   - <exactly what to add/change and why>
2. src/models/enums/event-names-enum.ts
   - Add: <NEW_EVENT = 'new_event'>  (only if new event needed)
3. src/constants/utils.ts
   - Add: <NEW_EVENT: 'New Event Label'>  (only if new event needed)
4. src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts
   - Register handler for <event> (only if new socket handler needed)
...

─── Notifications Changes (pw-notifications) ────────────
1. <confirmed file path>
   - <what and why>
...

─── AI Cron Server Changes (ai-cron-server) ─────────────
1. <confirmed file path>
   - <what and why>
...

─── Cron Jobs Changes (pw-cron-jobs) ────────────────────
1. <confirmed file path>
   - <what and why>
...

─── Acceptance Criteria Coverage ────────────────────────
✅ AC 1: <exactly how each AC is satisfied>
✅ AC 2: <exactly how each AC is satisfied>

─── Out of Scope ─────────────────────────────────────────
- <anything NOT being done and why>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask:
> **Does this plan look correct?**
> Reply with changes/additions — or say **"looks good"** to start coding.

⛔ STOP HERE. Do not write any code until the user approves.

---

## STEP 5 — Revise Plan (if needed)

If the user requests changes, update the plan and show it again.
Repeat until they say **"looks good"** / **"approved"** / **"yes"** / **"proceed"**.

---

## STEP 6 — Create Feature Branches

For each affected repo, checkout its dev branch, pull latest, then create the feature branch:

```bash
# Frontend
cd /Users/sudheer7781/Documents/pw-react-client-v3
git checkout dev && git pull origin dev
git checkout -b feat/<ticket-id>-<slug>

# Backend
cd /Users/sudheer7781/Documents/pw-server-v3
git checkout coolify-dev-v3 && git pull origin coolify-dev-v3
git checkout -b feat/<ticket-id>-<slug>

# AI Server (if needed)
cd /Users/sudheer7781/Documents/pw-ai-server
git checkout dev && git pull origin dev
git checkout -b feat/<ticket-id>-<slug>

# Notifications (if needed)
cd /Users/sudheer7781/Documents/pw-notifications
git checkout notif_dev && git pull origin notif_dev
git checkout -b feat/<ticket-id>-<slug>

# AI Cron Server (if needed)
cd /Users/sudheer7781/Documents/ai-cron-server
git checkout dev && git pull origin dev
git checkout -b feat/<ticket-id>-<slug>

# Cron Jobs (if needed)
cd /Users/sudheer7781/Documents/pw-cron-jobs
git checkout jobs_dev && git pull origin jobs_dev
git checkout -b feat/<ticket-id>-<slug>
```

---

## STEP 7 — Write the Code

For each affected repo, implement exactly what the approved plan says:

- Read every file before editing — never edit blindly
- Follow the repo's CLAUDE.md conventions strictly
- Never use raw MUI — use PWButton, PWTypography, PWIcon (Frontend)
- Always register socket.off() for every socket.on() (Frontend/Backend)
- No comments, docstrings, or extra logging unless the ticket requires it
- No refactoring beyond what the plan says
- Cross-repo payloads must match exactly — if Backend sends `{ endDate: string }`, Frontend must read `endDate`

After all changes in a repo, type-check:
- **Frontend**: `npx tsc -b` in `pw-react-client-v3` — fix ALL errors before proceeding
- **Backend**: check its CLAUDE.md for the type-check command — fix ALL errors
- **Others**: verify no syntax errors

---

## STEP 7.5 — Code Review (Mandatory — do not skip)

After writing all code and passing type-check, perform a thorough self-review of every changed file before committing.

For each repo with changes, run:
```bash
cd <repo-path>
git diff HEAD
```

Review each diff against these criteria:

**Correctness:**
- [ ] Does the code fully implement every AC from the ticket?
- [ ] Are all edge cases handled (null/undefined, empty arrays, loading states, error states)?
- [ ] Are socket payloads shaped correctly and matching what the other repo sends/expects?
- [ ] Are async operations awaited correctly? No unhandled promise rejections?

**Conventions (per CLAUDE.md):**
- [ ] Frontend: No raw MUI — only PWButton, PWTypography, PWIcon atoms used?
- [ ] Frontend: Every socket.on() has a matching socket.off() in cleanup?
- [ ] Frontend: No duplicate refreshChatUsers() calls?
- [ ] Backend: Follows existing service/controller pattern exactly?
- [ ] No comments or docstrings added unless logic is non-obvious?
- [ ] No console.log left in code?

**Quality:**
- [ ] No unnecessary re-renders or missing dependency arrays in useEffect?
- [ ] No hardcoded strings that should be constants?
- [ ] No new files created when an existing file should have been edited?
- [ ] Code is minimal — no over-engineering, no unused variables?

**If any issue is found** — fix it immediately before committing. Do not note it and move on.

Display a review summary:
```
─── Code Review ─────────────────────────────────────────
  Backend:
  ✅ All ACs covered
  ✅ Null checks present for optional fields
  ✅ Follows service pattern
  🔧 Fixed: missing await on prisma call in InitiativeService.ts

  Frontend:
  ✅ PWButton/PWTypography used throughout
  ✅ socket.off() cleanup present
  ✅ No raw MUI
  🔧 Fixed: useEffect dependency array was missing `initiativeId`
  ✅ Type-check passes
─────────────────────────────────────────────────────────
```

---

## STEP 8 — Commit and Push

For each repo with changes:

```bash
# Stage only the changed files explicitly — never git add . or git add -A
git add <specific files>

git commit -m "feat(<ticket-id>): <concise description>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

git push -u origin feat/<ticket-id>-<slug>
```

---

## STEP 9 — Raise PRs

For each repo use `gh pr create` targeting the correct dev branch:

| Repo | PR target branch |
|------|-----------------|
| Frontend | `dev` |
| Backend | `coolify-dev-v3` |
| AI Server | `dev` |
| Notifications | `notif_dev` |
| AI Cron Server | `dev` |
| Cron Jobs | `jobs_dev` |

**Title:** `feat(<ticket-id>): <Jira summary>`

**Body:**
```markdown
## Jira Ticket
[<TICKET-ID>](https://possibleworks.atlassian.net/browse/<TICKET-ID>) — <Summary>

## What Changed
- <bullet per file/area changed>

## Figma Design
<link or N/A>

## Acceptance Criteria
- [ ] <AC 1>
- [ ] <AC 2>

## Test Plan
- [ ] <manual step 1>
- [ ] <manual step 2>

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

---

## STEP 10 — Final Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅  <TICKET-ID> — Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Branches created:
  Frontend        → feat/<ticket-id>-<slug>
  Backend         → feat/<ticket-id>-<slug>
  Notifications   → feat/<ticket-id>-<slug>  (if applicable)
  AI Cron Server  → feat/<ticket-id>-<slug>  (if applicable)
  Cron Jobs       → feat/<ticket-id>-<slug>  (if applicable)

  Pull Requests:
  Frontend        → <PR URL>
  Backend         → <PR URL>
  Notifications   → <PR URL>  (if applicable)

  Code Review: ✅ passed (all issues fixed before commit)

  Coolify will auto-deploy coolify-dev-v3 on merge.
  Preview URL will appear in Coolify dashboard after merge.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

- Never write code before plan is approved
- Plan must be based on actual file reads — never guess file paths
- Never use `git add .` or `git add -A` — always stage specific files
- Never force push
- Never skip type-check before committing
- Never skip the code review (STEP 7.5) — it is mandatory
- Never commit .env or secret files
- If push is rejected — investigate, do not force
- Cross-repo payloads (socket events, API responses) must be verified to match on both ends before committing
