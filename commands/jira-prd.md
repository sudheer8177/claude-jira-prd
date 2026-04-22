---
description: Jira ticket → Claude router → plan → code → review → PR → Coolify preview
argument-hint: <TICKET-ID or Jira URL>  e.g. PW-123 or https://possibleworks.atlassian.net/browse/PW-123
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__fetch, mcp__claude_ai_Atlassian__addCommentToJiraIssue, mcp__claude_ai_Atlassian__editJiraIssue, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Figma__get_design_context, mcp__claude_ai_Figma__get_screenshot
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

**First: determine the feature type for each repo.**

Grep for the core domain terms from the ticket (entity name, feature name, screen name) across the repo:

```bash
grep -r "<domain-term>" <repo-path>/src --include="*.ts" --include="*.tsx" -l
```

- **Files found** → **EXTENSION** mode — existing code will be extended
- **No files found** → **NEW FEATURE** mode — building from scratch, follow patterns

Label each repo as `[EXTENSION]` or `[NEW FEATURE]` and run the matching exploration path below.

---

#### Path A — EXTENSION (existing code found)

1. **Read CLAUDE.md** — conventions, patterns, forbidden patterns
2. **Read all related existing files** — service, controller, component, socket handlers, types for this domain
3. **Read the Prisma schema** — understand the existing model and relations
4. **Read socket event enums** — `src/models/enums/event-names-enum.ts` (FE), backend socket handlers
5. **Find cross-repo contracts** — existing API endpoints, socket event names and shapes
6. **Identify exactly what needs to change** — which methods to add, which fields to add, which components to extend

---

#### Path B — NEW FEATURE (no existing code found)

1. **Read CLAUDE.md** — understand file structure rules, naming conventions, forbidden patterns
2. **Find the reference feature** — identify the most similar existing feature in the codebase and read it completely:
   - Backend: read its service, controller, router, Prisma model, socket emitter
   - Frontend: read its component folder, hook, socket handler, card component, type definitions
   - This reference feature IS the template — the new feature must follow the exact same structure
3. **Read the Prisma schema** — understand existing models and relations the new feature will relate to
4. **Read socket event enums** — to understand naming conventions for new events
5. **Read `src/constants/utils.ts`** — to understand CARD_EVENTS and ACTION_STATUS naming patterns
6. **Map out the full new file structure** needed:
   - Backend: new service file, new controller file, new router file, new Prisma model, socket emit points
   - Frontend: new component folder structure, new hook, new type file, new EVENTNAMES_ENUM entries, new CARD_EVENTS entries, new chat card
7. **Identify all integration points** — where the new feature plugs into existing code (route registration, socket gateway, sidebar nav, etc.)

---

Exploration checklist (run all relevant):
- `Glob("**/*.ts", repo_path)` + keyword grep to find (or confirm absence of) existing code
- Read CLAUDE.md
- Read the entity's service / controller / Prisma model (Extension: the entity itself | New: the reference feature)
- Read `src/constants/utils.ts` — CARD_EVENTS, ACTION_STATUS
- Read `src/models/enums/event-names-enum.ts` — EVENTNAMES_ENUM
- Read `src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts`
- Read the nearest similar feature's chat card (both Extension and New Feature)

Display exploration summary — label each repo clearly:

```
─── Codebase Exploration ────────────────────────────────
  Backend: [EXTENSION]
  - Found: src/services/InitiativeService.ts
  - Found: src/controllers/InitiativeController.ts
  - Prisma model: Initiative { id, title, endDate, ... }
  - Socket events: initiative_update, initiative_create
  - Will extend: InitiativeService + add 1 new method

  Frontend: [NEW FEATURE]
  - No existing "Task" component/hook/event found
  - Reference pattern: LeaveRequest feature
    └─ src/components/molecules/LeaveRequestCard/index.tsx
    └─ src/hooks/useLeaveRequest.ts
    └─ EVENTNAMES_ENUM.LEAVE_REQUEST_UPDATE
  - New files needed: TaskCard/, useTask.ts, task.types.ts
  - Integration points: sidebar nav, useSocketEvents.ts, CARD_EVENTS
─────────────────────────────────────────────────────────
```

---

### 3c — Reusability & Pattern Analysis (Mandatory — do not skip)

Run the matching analysis for each repo based on its label from STEP 3b.

---

#### For [EXTENSION] repos — Reusability audit

Goal: **zero unnecessary new code** — extend, compose, reuse first.

**Backend:**
- Existing service method that does the same query? → reuse/extend, don't duplicate
- Existing middleware/guard/util for auth or validation needed here?
- Prisma schema already has the field/relation? → reuse, else add minimal new field
- Existing socket emitter helper or broadcast pattern? → use it
- Can new endpoint share a route file with a related controller?

**Frontend:**
- Existing component (atom/molecule) that renders this UI pattern? → reuse it
- Existing hook that fetches/manages this data? → extend, don't create new
- Existing utility in `src/constants/utils.ts` or `src/utils/`? → call it
- Same socket event already in `EVENTNAMES_ENUM`? → do NOT duplicate
- Same card action already in `CARD_EVENTS`? → do NOT duplicate
- New feature addable to existing component as a prop/variant?

**Cross-repo:**
- Existing socket event missing just one field? → add the field, don't create a new event
- Existing API endpoint returns adjacent data? → extend response shape, don't add endpoint

---

#### For [NEW FEATURE] repos — Pattern mapping

Goal: **mirror the reference feature's structure exactly** — new feature must feel native to the codebase.

**Backend pattern map** (read from reference feature):
- Service file location and naming: `src/services/<Entity>Service.ts`
- Controller file location: `src/controllers/<Entity>Controller.ts`
- Router registration point: where to add the new router in the app entry
- Prisma model conventions: naming, required fields, soft-delete pattern, tenant relations
- Socket emit pattern: which gateway class to use, how events are emitted, room/namespace

**Frontend pattern map** (read from reference feature):
- Component folder structure: `src/components/molecules/<Feature>/index.tsx` + sub-components
- Hook naming and location: `src/hooks/use<Feature>.ts`
- Type file location: `src/types/<feature>.types.ts` or co-located
- EVENTNAMES_ENUM naming convention: `<ENTITY>_<ACTION>` pattern
- CARD_EVENTS naming convention: `<entity>_<action>` snake_case
- Chat card structure: how props flow, how socket data maps to card state
- Socket handler registration: where and how in `useSocketEvents.ts`

**Integration points** (where new code plugs into existing):
- Backend: route file registration, socket gateway, middleware chain
- Frontend: sidebar nav item, `useSocketEvents.ts` handler block, `CARD_EVENTS` entry

---

Display a unified report for both repo types:

```
─── Analysis ────────────────────────────────────────────
  Backend: [EXTENSION]
  ♻️  REUSE: InitiativeService.getById() — add 1 select field
  ♻️  REUSE: existing broadcast helper in SocketGateway
  🆕  NEW:   InitiativeService.updateEndDate() — no existing method
  🆕  NEW:   Prisma field resolvedAt: DateTime? on Initiative
  ⚠️  AVOID: do NOT new socket event — extend initiative_update

  Frontend: [NEW FEATURE]
  📐 PATTERN: mirrors LeaveRequest feature structure
  🆕  NEW FILE: src/components/molecules/TaskCard/index.tsx
  🆕  NEW FILE: src/hooks/useTask.ts
  🆕  NEW FILE: src/types/task.types.ts
  🆕  ENUM:    EVENTNAMES_ENUM.TASK_CREATE, TASK_UPDATE
  🆕  CONST:   CARD_EVENTS.task_create, task_update
  ♻️  REUSE:  PWStatusBadge, PWButton, PWTypography atoms
  🔌 PLUG IN: sidebar nav, useSocketEvents.ts, CARD_EVENTS map
─────────────────────────────────────────────────────────
```

---

## STEP 3.5 — Enhance Jira Ticket + Create Sub-tasks

🚀 AUTO — run immediately after STEP 3. Do not stop or ask for confirmation.

This is the most important step for keeping Jira as the source of truth. Using everything learned from STEPS 1, 2, and 3, enrich the ticket and break it into sub-tasks so any engineer can pick it up with full context.

---

### 3.5a — Edit the ticket description

```
Tool: mcp__claude_ai_Atlassian__editJiraIssue
issueIdOrKey: "<TICKET-ID>"
```

Update the `description` field. The enhanced description must contain two parts:

**Part 1 — Original content preserved exactly:**
Do not alter, shorten, or reword anything the reporter wrote. Keep the original description and AC verbatim.

**Part 2 — Technical Context block (appended after original, clearly separated):**

```
---
🤖 Technical Context (added by Claude after codebase analysis)

Repos affected:
- Backend (pw-server-v3): <why affected — which domain, which service>
- Frontend (pw-react-client-v3): <why affected — which component/screen>
- <other repos if applicable>

Key files to change:
- <repo>: <confirmed file path> — <EXTEND | NEW> — <what changes>
- <repo>: <confirmed file path> — <EXTEND | NEW> — <what changes>

Cross-repo contracts:
- Socket event: <event_name> [NEW | EXTENDED] — payload: { field: type, ... }
- API endpoint: <METHOD /path> [NEW | EXTENDED] — request/response shape

Reuse opportunities found:
- <existing component/hook/service that handles part of this>
- <existing event/endpoint that can be extended instead of duplicated>

Schema changes required:
- <model>: add field <name>: <type> (default: <value>) — or "None"

Additional ACs discovered during exploration:
- <any AC not in the original ticket that the codebase reveals is needed>
- <e.g. "Must call socket.off() cleanup for the new event handler">
```

---

### 3.5b — Create sub-tasks (one per affected repo)

For each repo that is affected, create a sub-task linked to the parent ticket.

```
Tool: mcp__claude_ai_Atlassian__createJiraIssue
```

Required fields per sub-task:
- `issueType`: `Sub-task`
- `project`: same project as parent ticket
- `parent`: `<TICKET-ID>`
- `summary`: `[<REPO-SHORT>] <parent ticket summary>`
  - Repo short names: `BE`, `FE`, `AI`, `NOTIF`, `AI-CRON`, `CRON`
  - Example: `[BE] PW-123: Replace initiatives with tasks`
- `description`: full technical breakdown for that repo:

```
Scope for <Repo Name> (pw-<repo>)

Branch: feat/<ticket-id>-<slug>  (from <dev-branch>)

Files to change:
1. <confirmed file path>  [EXTEND]
   - <exactly what to add: method name, params, return type, socket event>
   - AC covered: <which parent AC>

2. <confirmed file path>  [NEW FILE]
   - <what this file does and why it's needed>
   - AC covered: <which parent AC>

Dependencies:
- Depends on: <other sub-task ID or "none"> — <reason>
- Required by: <other sub-task ID or "none"> — <reason>

Cross-repo contract this sub-task owns:
- <socket event / API endpoint this repo is responsible for emitting/exposing>
- Payload: { field: type }

Definition of done:
- [ ] <specific testable outcome 1>
- [ ] <specific testable outcome 2>
- [ ] Type-check passes (npx tsc -b)
```

Create all sub-tasks before moving to STEP 4.

---

### 3.5c — Confirm and display

After enhancing the ticket and creating sub-tasks, display:

```
─── Jira Ticket Enhanced ────────────────────────────────
  ✅ Ticket <ID> description updated with technical context
  ✅ Sub-tasks created:
     └─ <SUB-ID>: [BE] <summary>
     └─ <SUB-ID>: [FE] <summary>
     └─ <SUB-ID>: [AI] <summary>  (if applicable)
     └─ <SUB-ID>: [NOTIF] <summary>  (if applicable)
  Jira: https://possibleworks.atlassian.net/browse/<TICKET-ID>
─────────────────────────────────────────────────────────
```

Proceed immediately to STEP 3.6 — do not wait for user input.

---

## STEP 3.6 — Pre-Plan Clarification Questions

⛔ MANDATORY STOP — ask questions before writing the plan. Do not skip this step even if the ticket seems clear.

After reading the ticket, exploring the codebase, and enhancing Jira, you will always have ambiguities. Surface them now — a bad assumption here means bad code later.

---

### How to generate good questions

Go through each category below. For every item where you are not 100% certain, add a question. Skip categories where you are genuinely confident.

**Scope & boundaries:**
- Is X included in this ticket or out of scope? (When the ticket says "replace initiatives with tasks" — does that mean delete the old initiative code or keep it behind a flag?)
- Should the old behaviour/data be migrated or can it be dropped?
- Are there related tickets that overlap with this one?

**Design & UX:**
- Figma designs are missing / incomplete for state X — how should it look?
- The ticket mentions component Y but the design shows Z — which takes priority?
- How should empty states, loading states, and error states look for this feature?

**Business logic & edge cases:**
- What happens when [edge case found in codebase]?
- Should [condition] be validated on frontend, backend, or both?
- What is the expected behaviour when a user has no permissions for this?

**Technical approach (when two valid paths exist):**
- The codebase has both [approach A] and [approach B] patterns for this — which should this feature follow?
- Should this extend the existing `<socket_event>` payload or create a new event?
- Should this be a new Prisma field or can we reuse `<existing_field>`?

**Data & API:**
- What data does the frontend need that isn't already returned by the existing endpoint?
- Should deleted/archived items be included or excluded from this feature?
- Is pagination required for this list?

**Cross-repo contracts:**
- Is the payload shape for `<event>` finalised, or is there flexibility?
- Does the notification need to be sent in real-time (socket) or is a poll acceptable?

---

### Format

Display questions like this — group by category, number them:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Clarification needed before planning
  <TICKET-ID> — <Summary>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scope
  1. The ticket says "replace initiatives with tasks" — should the existing
     Initiative model and all related API endpoints be removed, or kept for
     backward compatibility during this sprint?

  2. Does this include migrating existing initiative data to tasks, or only
     new data going forward?

Design / UX
  3. The Figma shows a "Tasks" tab on the sidebar but no empty state design.
     Should the empty state match the existing Initiatives empty state, or
     is there a new design coming?

Business Logic
  4. When a task is deleted, should it be soft-deleted (archived) or hard-
     deleted? The existing Initiative model uses soft-delete.

Technical Approach
  5. The codebase has two patterns for list updates — socket broadcast and
     REST polling. Which should the task list use?

─────────────────────────────────────────────────────────
Answer any/all of the above, or say "skip" to proceed with
my best assumptions (assumptions will be listed in the plan).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Rules for this step

- **Minimum 3 questions, maximum 8** — if you genuinely have fewer than 3, you have not explored deeply enough. If you have more than 8, group or prioritise.
- Every question must be **specific and actionable** — no vague "can you clarify the requirements?" style questions
- Every question must come from a **concrete finding** — a gap in the ticket, an ambiguity in the Figma, a fork in the codebase, a missing edge case
- If the user says **"skip"** or **"proceed"** — list your best assumptions at the top of the plan and continue
- Do NOT generate the plan until you receive answers (or an explicit skip)

⛔ WAIT for user response before proceeding to STEP 4.

---

## STEP 4 — Generate Implementation Plan

**Plan quality rules — apply before writing:**
- Incorporate every answer from STEP 3.6 — the plan must reflect what was clarified
- If user skipped STEP 3.6 — list assumptions at the very top of the plan before anything else
- Every file path must be confirmed from STEP 3 exploration — no guesses
- Every item in the plan must map directly to an AC — if it doesn't satisfy an AC, it shouldn't be in the plan
- **[EXTENSION] repos**: prefer extending existing files; never duplicate logic that already exists
- **[NEW FEATURE] repos**: every new file must mirror the reference feature's structure; note which reference file it follows
- The plan must be the minimum viable set of changes to satisfy all ACs — nothing more
- Sort changes within each repo: safest first, schema/model changes last
- For new features: list integration points explicitly (where new code plugs into existing app shell)
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

─── Feature Type ────────────────────────────────────────
  Backend:  [EXTENSION | NEW FEATURE]
  Frontend: [EXTENSION | NEW FEATURE]
  <other repos if applicable>

─── Assumptions (if user skipped STEP 3.6) ──────────────
  - <assumption 1 and what it affects>
  - <assumption 2> — or "None (all questions answered)"

─── New Feature: Reference Pattern ──────────────────────
  (include this section only if any repo is [NEW FEATURE])
  Backend reference:  src/services/<RefFeature>Service.ts
  Frontend reference: src/components/molecules/<RefFeature>/
  New file structure:
    BE: src/services/<NewFeature>Service.ts
        src/controllers/<NewFeature>Controller.ts
        src/routes/<newFeature>.routes.ts
    FE: src/components/molecules/<NewFeature>/index.tsx
        src/components/molecules/<NewFeature>/<Sub>.tsx
        src/hooks/use<NewFeature>.ts
        src/types/<newFeature>.types.ts

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
1. <confirmed file path>  [EXTEND | NEW FILE — mirrors: <reference file>]
   - AC coverage: <which AC this satisfies>
   - <exactly what to add/change — method name, params, return shape>
   - Reuse: <what existing code is called internally>
2. prisma/schema.prisma  [only if schema change truly required]
   - <model name, fields, relations, defaults>
...
N. Integration points:  [NEW FEATURE only]
   - Register route: <file where router is mounted> — add 1 line
   - Socket gateway: <file> — register new event emitter
...

─── Frontend Changes (pw-react-client-v3) ───────────────
  [ordered: safest changes first]
1. <confirmed file path>  [EXTEND | NEW FILE — mirrors: <reference file>]
   - AC coverage: <which AC this satisfies>
   - <exactly what to add/change — prop, state, handler, render>
   - Reuse: <existing atom/hook/util being used>
2. src/models/enums/event-names-enum.ts  [only if truly new event]
   - Add: <NEW_EVENT = 'new_event'>
3. src/constants/utils.ts  [only if truly new label/constant]
   - Add: <NEW_KEY: 'Label'>
4. src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts
   - Register handler for <event>  [only if new socket handler needed]
N. Integration points:  [NEW FEATURE only]
   - Sidebar nav: <file> — add nav item for new feature
   - CARD_EVENTS: <file> — register new card event key
   - App router: <file> — add route for new screen (if applicable)
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

- **There are TWO mandatory stops**: STEP 3.6 (clarification questions) and STEP 4 (plan approval) — everything else runs automatically
- **STEP 3.6 is non-negotiable** — always ask clarification questions before generating the plan, minimum 3 questions, every time
- **STEP 3.5 is mandatory** — ticket enhancement and sub-task creation must happen before questions and plan, every time
- If user says "skip" at STEP 3.6 — list assumptions at the top of the plan and continue
- Once the plan is approved, execute STEPS 6 → 7 → 7.5 → 8 → 9 → 10 → 11 → 12 in one continuous run
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
