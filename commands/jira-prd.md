---
description: Jira ticket → Claude router → plan → code → review → PR → Coolify preview
argument-hint: <TICKET-ID or Jira URL>  e.g. PW-123 or https://possibleworks.atlassian.net/browse/PW-123
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__fetch, mcp__claude_ai_Atlassian__addCommentToJiraIssue, mcp__claude_ai_Figma__get_design_context, mcp__claude_ai_Figma__get_screenshot
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

## STEP 1 — Fetch Jira Ticket (Full Context)

Use the `atlassian` MCP to fetch the full ticket for the extracted ID from `possibleworks.atlassian.net`.

### 1a — Core Ticket Data

```
Tool: mcp__claude_ai_Atlassian__getJiraIssue
issueIdOrKey: "<TICKET-ID>"
```

Extract and display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ticket  : <ID> — <Summary>
  Type    : <Bug | Story | Task | Sub-task>
  Status  : <status>
  Reporter: <name>
  Assignee: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Description:
<full description>

Acceptance Criteria:
<AC items, one per line>

Figma Links:
<list any figma.com URLs found in description/comments — or "None">

Attachments:
<list all attachments with type: screenshot | PDF | doc | other>

Sub-tasks:
<list sub-task IDs + summaries — or "None">

Comments:
<count> comments found
```

### 1b — Fetch All Comments

The `getJiraIssue` response includes comments in the `fields.comment.comments` array — read them directly from the already-fetched ticket data. No additional API call needed.

Read every comment on the ticket. Extract:
- **UI feedback / bug reports** — descriptions of broken behaviour, wrong layout, wrong colour, missing elements
- **Screenshot references** — any comment mentioning a screenshot or containing an image attachment
- **Additional context** — any clarifications from the reporter, PM, or designer that add to or override the description
- **Decision log** — any "agreed to do X instead of Y" type comments

Display:
```
─── Comments ────────────────────────────────────────
  [<author> — <date>]
  <comment body — full text, do not truncate>

  [<author> — <date>]
  <comment body>
─────────────────────────────────────────────────────
```

### 1c — Fetch Attachments (screenshots, PDFs, docs)

From the ticket's `attachment` field, collect every attachment. For each:

**Screenshots / images (PNG, JPG, GIF, WEBP):**
- Use `mcp__claude_ai_Atlassian__fetch` to download and view the image
- Describe what is shown: screen name, UI element highlighted, error state, layout issue, red annotations, arrows
- If it is a bug screenshot — note exactly what looks wrong visually
- Label it: `[Screenshot: <filename> — <what it shows>]`

**PDFs:**
- Use `mcp__claude_ai_Atlassian__fetch` to fetch the PDF URL
- Read and summarise the content: requirements, flow diagrams, spec pages
- Label it: `[PDF: <filename> — <summary of content>]`

**Other docs (DOCX, XLSX, TXT, CSV):**
- Fetch and summarise relevant content
- Label it: `[Doc: <filename> — <summary>]`

Display:
```
─── Attachments ─────────────────────────────────────
  [Screenshot: error-state.png]
  Shows the initiative card in error state — red border
  visible, "Failed" badge overlapping the title text.
  Red arrow pointing to the badge. This is the bug to fix.

  [PDF: flow-spec.pdf]
  3-page spec describing the approval flow for leave requests.
  Key constraint: manager must approve within 48h or auto-rejected.
─────────────────────────────────────────────────────
```

### 1d — Fetch Sub-tasks (if any)

For each sub-task listed on the parent ticket:

```
Tool: mcp__claude_ai_Atlassian__getJiraIssue
issueIdOrKey: "<SUB-TASK-ID>"
```

Extract for each sub-task:
- Summary, status, assignee
- Full description and AC
- Comments (repeat 1b for each sub-task)
- Attachments (repeat 1c for each sub-task)

Display:
```
─── Sub-task: <ID> — <Summary> ──────────────────────
  Status   : <status>
  Assignee : <name>
  Description: <full text>
  AC: <items>
  Comments: <if any>
  Attachments: <if any — describe screenshots>
─────────────────────────────────────────────────────
```

### 1e — Synthesise All Context

After fetching everything, produce a single consolidated understanding block:

```
─── Synthesised Understanding ───────────────────────
  Core requirement: <1-2 sentences — what needs to be built/fixed>

  UI issues to fix (from screenshots/comments):
  - <exact visual problem 1 and where it appears>
  - <exact visual problem 2>

  Additional constraints from comments:
  - <any PM/designer clarification that overrides description>

  Sub-task scope:
  - <ID>: <what it covers — include or exclude from this implementation>

  Open questions (if any):
  - <anything ambiguous — will be surfaced in plan's Out of Scope>
─────────────────────────────────────────────────────
```

Do NOT stop here. Continue automatically to STEP 2. Open questions are carried forward and shown in the plan's Out of Scope section at the STEP 4 approval gate.

---

## STEP 2 — Fetch Figma Designs (if any)

If Figma links were found in the ticket (description, comments, or attachments), use the `figma` MCP to fetch each one.

For each design extract:
- Screen/component names
- Layout and interaction notes
- Any visible text, labels, states, colors
- Any designer annotations or constraints

Cross-reference with screenshots from STEP 1c — if a screenshot shows a bug against a Figma design, note the exact delta.

Display a design summary. If no Figma links → skip and note "No designs attached".

----


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

### 3c — Reusability Analysis (Mandatory — do not skip)

Before writing the plan, explicitly audit every part of the feature for reuse opportunities. The goal is **zero unnecessary new code** — extend, compose, and reuse first.

For each affected repo, answer these questions by reading the actual code:

**Backend:**
- Is there an existing service method that does the same or similar query? → reuse/extend it, don't duplicate
- Is there an existing middleware, guard, or util already solving auth/validation needed here?
- Does the Prisma schema already have the field/relation needed, or does it truly need a new field?
- Is there an existing socket emitter helper or broadcast pattern? → use it
- Can the new endpoint share a route file with a related controller, or does it need a new file?

**Frontend:**
- Is there an existing component (atom, molecule) that already renders this UI pattern? → reuse it
- Is there an existing hook that fetches/manages this data? → extend it, don't create a new one
- Is there an existing utility function in `src/constants/utils.ts` or `src/utils/` that handles the logic? → call it
- Does the same socket event already exist in `EVENTNAMES_ENUM`? → do NOT add a duplicate
- Does the same card action already exist in `CARD_EVENTS`? → do NOT add a duplicate
- Can the new feature be added to an existing component as a prop/variant rather than a new component?

**Cross-repo:**
- Is there an existing socket event that carries the needed data but is just missing a field? → add the field to the existing event rather than creating a new event
- Is there an existing API endpoint that returns adjacent data? → extend the response shape rather than a new endpoint

Display a reusability report:
```
─── Reusability Analysis ────────────────────────────────
  ♻️  REUSE (no new code needed):
  - Backend: InitiativeService.getById() → reuse directly, add 1 field to select
  - Frontend: PWStatusBadge component → reuse for status display
  - Frontend: EVENTNAMES_ENUM.INITIATIVE_UPDATE already exists → no new enum entry
  - Frontend: useInitiativeSocket hook exists → extend, not replace

  🆕  NEW (genuinely required):
  - Backend: new method InitiativeService.updateEndDate() — no existing method covers this
  - Frontend: new EndDatePicker sub-component — no existing date picker fits this layout
  - DB: new optional field `resolvedAt` on Initiative — not present in schema

  ⚠️  AVOID (would be duplication/over-engineering):
  - Do NOT create a new socket event — extend existing initiative_update payload
  - Do NOT create a new hook — extend useInitiativeSocket
─────────────────────────────────────────────────────────
```

---

## STEP 4 — Generate Implementation Plan

**Plan quality rules — apply before writing:**
- Every file path must be confirmed from STEP 3 exploration — no guesses
- Every item in the plan must map directly to an AC — if it doesn't satisfy an AC, it shouldn't be in the plan
- Prefer extending existing files over creating new ones
- Prefer reusing existing components, hooks, services over writing new ones (per reusability analysis)
- Prefer adding a field to an existing event/endpoint over creating a new one
- The plan must be the minimum viable set of changes to satisfy all ACs — nothing more
- Sort changes within each repo from lowest to highest risk (schema changes last)
- Call out explicitly when something is intentionally NOT changing and why

Using everything learned in STEPS 3b and 3c, generate a concrete plan with exact file paths (confirmed by exploration, not guessed):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  IMPLEMENTATION PLAN — <TICKET-ID>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branches:  [only list repos that are actually affected]
  Frontend        → feat/<ticket-id>-<slug>  (from dev)           [if affected]
  Backend         → feat/<ticket-id>-<slug>  (from coolify-dev-v3) [if affected]
  AI Server       → feat/<ticket-id>-<slug>  (from dev)           [if affected]
  Notifications   → feat/<ticket-id>-<slug>  (from notif_dev)     [if affected]
  AI Cron Server  → feat/<ticket-id>-<slug>  (from dev)           [if affected]
  Cron Jobs       → feat/<ticket-id>-<slug>  (from jobs_dev)      [if affected]

─── Reuse Summary ────────────────────────────────────────
  ♻️  Reusing (no new code):
  - <component/hook/service/event being reused and how>

  🆕  New (genuinely required):
  - <only what cannot be satisfied by existing code>

─── Cross-Repo Contract ──────────────────────────────────
  Socket event: <event_name>  [NEW | EXTENDED — field added]
  Payload shape (Backend → Frontend):
    { field1: type, field2: type, ... }
  API endpoint (if REST): <METHOD /path>  [NEW | EXTENDED]
  Request body: { ... }
  Response shape: { ... }

─── Backend Changes (pw-server-v3) ──────────────────────
  [ordered: safest changes first, schema changes last]
1. <confirmed file path>  [EXTEND | NEW FILE]
   - AC coverage: <which AC this satisfies>
   - <exactly what to add/change — method name, params, return shape>
   - Reuse: <what existing code is called internally>
2. prisma/schema.prisma  [only if schema change truly required]
   - <field/model/relation — name, type, default, nullable>
...

─── Frontend Changes (pw-react-client-v3) ───────────────
  [ordered: safest changes first]
1. <confirmed file path>  [EXTEND | NEW FILE]
   - AC coverage: <which AC this satisfies>
   - <exactly what to add/change — prop, state, handler, render>
   - Reuse: <existing atom/hook/util being used>
2. src/models/enums/event-names-enum.ts  [only if truly new event]
   - Add: <NEW_EVENT = 'new_event'>
3. src/constants/utils.ts  [only if truly new label/constant]
   - Add: <NEW_KEY: 'Label'>
4. src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts
   - Register handler for <event>  [only if new socket handler needed]
...

─── Notifications Changes (pw-notifications) ────────────
1. <confirmed file path>  [EXTEND | NEW FILE]
   - AC coverage: <which AC>
   - <what and why>
...

─── AI Cron Server Changes (ai-cron-server) ─────────────
1. <confirmed file path>  [EXTEND | NEW FILE]
   - AC coverage: <which AC>
   - <what and why>
...

─── Cron Jobs Changes (pw-cron-jobs) ────────────────────
1. <confirmed file path>  [EXTEND | NEW FILE]
   - AC coverage: <which AC>
   - <what and why>
...

─── Acceptance Criteria Coverage ────────────────────────
✅ AC 1: <file:method that satisfies it + how>
✅ AC 2: <file:method that satisfies it + how>

─── Optimization Notes ───────────────────────────────────
- <any decision made to reduce code size, avoid duplication, or reuse>
- <any AC that is satisfied "for free" by reusing existing behavior>

─── Out of Scope ─────────────────────────────────────────
- <anything NOT being done and why — tie to AC if relevant>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask:
> **Does this plan look correct?**
> Reply with changes/additions — or say **"looks good"** to start coding.

⛔ STOP HERE — this is the ONLY point where you wait for user input. Do not write any code until the user approves.

---

## STEP 5 — Revise Plan (if needed)

If the user requests changes, update the plan and show it again.
Repeat until they say **"looks good"** / **"approved"** / **"yes"** / **"proceed"**.

✅ Once approved — immediately and automatically proceed through STEPS 6 → 7 → 7.5 → 8 → 9 → 10 → 11 without pausing or asking for confirmation (the only pause is 11d — Dockerfile UI confirmation inside the coolify-deploy skill).

---

## STEP 6 — Create Feature Branches

🚀 AUTO — do not stop or ask for confirmation. Execute immediately.

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

🚀 AUTO — do not stop or ask for confirmation. Execute immediately.

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

🚀 AUTO — do not stop or ask for confirmation. Execute immediately.

After writing all code and passing type-check, perform a thorough self-review of every changed file before committing.

For each repo with changes, run:
```bash
cd <repo-path>
git status                  # see all new + modified files
git diff                    # unstaged changes to tracked files
git diff --cached           # staged changes
# new (untracked) files: read them directly with the Read tool
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

**Reusability:**
- [ ] Is every new file/class/function actually necessary, or could an existing one be extended?
- [ ] Are existing utility functions, hooks, and services being called rather than reimplemented?
- [ ] No duplicated logic that already exists elsewhere in the codebase?
- [ ] No new socket event or API endpoint created when an existing one could be extended with an extra field?
- [ ] No new component created when an existing atom/molecule already covers this UI pattern?

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

🚀 AUTO — do not stop or ask for confirmation. Execute immediately.

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

🚀 AUTO — do not stop or ask for confirmation. Execute immediately.

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

## STEP 10 — Final Summary (before Coolify deploy)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅  <TICKET-ID> — Code Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Branches created:
  Frontend        → feat/<ticket-id>-<slug>  (if applicable)
  Backend         → feat/<ticket-id>-<slug>  (if applicable)
  AI Server       → feat/<ticket-id>-<slug>  (if applicable)
  Notifications   → feat/<ticket-id>-<slug>  (if applicable)
  AI Cron Server  → feat/<ticket-id>-<slug>  (if applicable)
  Cron Jobs       → feat/<ticket-id>-<slug>  (if applicable)

  Pull Requests:
  Frontend        → <PR URL>  (if applicable)
  Backend         → <PR URL>  (if applicable)
  AI Server       → <PR URL>  (if applicable)
  Notifications   → <PR URL>  (if applicable)
  AI Cron Server  → <PR URL>  (if applicable)
  Cron Jobs       → <PR URL>  (if applicable)

  Code Review: ✅ passed (all issues fixed before commit)

  ⏭️  Proceeding to Coolify preview deployment…
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## STEP 11 — Coolify Preview Deployment

🚀 AUTO — run immediately after PRs are raised. Deploy ALL repos that were actually changed.

**Invoke the `/coolify-deploy` skill** passing just the single feature branch name:

```
/coolify-deploy feat/<ticket-id>-<slug>
```

The skill auto-detects which repos contain this branch (via GitHub API) and only deploys those. No need to pass multiple args or specify which repos changed.

The skill:
1. Checks each of the 6 repos on GitHub for the branch — deploys where found, uses default dev URL where not
2. Resolves the correct FQDN for every service (deployed → new preview URL, not found → default dev URL)
3. Checks for existing Coolify apps; creates new ones where needed (strict order: BE → AI → NOTIF → AI-CRON → CRON → FE)
4. Sets Dockerfile location to `/Dockerfile` automatically via API — no manual UI step
5. Sets ALL env vars from `~/.claude/SECRETS.md` as the base, then overrides inter-service URLs with the correct FQDNs
6. Deploys each service in order, waiting for each to finish before starting the next
7. Returns all preview URLs

---

## STEP 12 — Update Jira Ticket with Deployment Info

🚀 AUTO — run immediately after Coolify deploy completes. Do not stop or ask for confirmation.

Post a comment on the Jira ticket with all deployment details using:

```
Tool: mcp__claude_ai_Atlassian__addCommentToJiraIssue
issueIdOrKey: "<TICKET-ID>"
```

Comment body (use this exact format):

```
🚀 *Feature Branch Deployed — Ready for Review*

*Branches:*
• Frontend: `feat/<ticket-id>-<slug>` → [PR](<frontend-pr-url>)
• Backend: `feat/<ticket-id>-<slug>` → [PR](<backend-pr-url>)
[include only the repos that were changed]

*Preview URLs:*
• Frontend: <frontend-preview-url>
• Backend: <backend-preview-url>
[include only the repos that were deployed]

*Pull Requests:*
• Frontend: <frontend-pr-url>
• Backend: <backend-pr-url>
[include only the repos that have PRs]

*Status:* ✅ Deployed and running on Coolify dev environment
```

After posting the comment, display the final end-to-end summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅  <TICKET-ID> — Done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Branches:
  Frontend        → feat/<ticket-id>-<slug>
  Backend         → feat/<ticket-id>-<slug>

  Pull Requests:
  Frontend        → <PR URL>
  Backend         → <PR URL>

  Preview URLs:
  Backend         → https://<be-app-name>.erwrds.com
  Frontend        → https://<fe-app-name>.erwrds.com

  Jira Comment:   ✅ posted on <TICKET-ID>
  Code Review:    ✅ passed
  Coolify Deploy: ✅ running
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## HARD RULES

- **STEP 4 is the ONLY full stop** — all other steps run automatically without pausing, except STEP 11d (Dockerfile UI — mandatory user confirmation)
- Once the plan is approved, execute STEPS 6 → 7 → 7.5 → 8 → 9 → 10 → 11 → 12 in one continuous run (pausing only at 11d for UI confirmation)
- Never write code before plan is approved
- Plan must be based on actual file reads — never guess file paths
- **Reusability is mandatory** — always complete STEP 3c before writing the plan; the plan must reflect what is reused vs what is new
- **Plan must be optimized** — minimum files, minimum new code, maximum reuse; every planned change must satisfy at least one AC
- Never create a new component, hook, service, event, or endpoint if an existing one can be extended to meet the requirement
- Never use `git add .` or `git add -A` — always stage specific files
- Never force push
- Never skip type-check before committing
- Never skip the code review (STEP 7.5) — it is mandatory
- Never commit .env or secret files
- If push is rejected — investigate, do not force
- Cross-repo payloads (socket events, API responses) must be verified to match on both ends before committing
- **Coolify — NEVER touch prod (`os4ok8oco488gg4c8s8kgc4k`) or UAT (`qoocsssso88g0ooss0ggkco8`) environments** — dev only (`tscgoggowo8cwwgko4gooo4k`)
- **Coolify — NEVER restart or redeploy** `FRONTEND_PARENT` (`qosws0k84g44kkcooo08owgo`) or `BACKEND_PARENT` (`m4wkosg48c0okgw4coos80wo`)
- **Coolify — always use `create_github`**, never `create_public` (private repos need GitHub App auth)
- **Coolify — always deploy backend before frontend** when both are affected (frontend needs backend FQDN for env vars)
- **Coolify — never set `dockerfile_location` via API** (known bug) — always ask user to set it in the UI (step 11d)
- **Coolify — never retry a failed deploy automatically** — report the error and ask the user how to proceed
