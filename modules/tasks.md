# Tasks Module

> Read this before touching any task-related code across any repo.
> For implementation details, follow the repo-level spec pointers in Section 7.

---

## 1. What This Module Is

Tasks are the execution layer of PossibleWorks — standalone actionable items that users create, track, and manage inside the PW single screen chat interface. Tasks are independent entities, not linked to Goals or OKRs. They appear as chat tiles, have assignees, due dates, priority levels, status tracking, comments, and attachments. Tasks can be created manually or via AI suggestions.

Every task action (create, update, status change, comment, assignment) produces a real-time socket event that updates all connected users instantly.

---

## 2. Data Flow

```
PW Frontend  ──────────────────────→  pw-server-v3        (all CRUD, REST + Socket)
                                            │
                                            │  socket broadcast on every change
                                            ↓
                                      PW Frontend          (real-time tile update)

pw-server-v3 ──────────────────────→  pw-notifications    (assignment, due date, status alerts)

PW Frontend  ──────────────────────→  pw-ai-server        (on-demand AI task suggestions)

ai-cron-server ────────────────────→  pw-server-v3        (AI-extracted tasks from Teams/Outlook/GChat/Gmail)

pw-cron-jobs ──────────────────────→  pw-server-v3        (recreate expired tasks as new task records)
```

- Frontend talks to pw-server-v3 for all task CRUD (REST) and receives real-time updates via socket
- pw-server-v3 broadcasts socket events to all users in the relevant room on any state change
- Status changes and assignments trigger notifications via pw-notifications
- ai-cron-server connects to Teams, Outlook, GChat, and Gmail — extracts actionable tasks using AI and creates them via pw-server-v3 API
- pw-cron-jobs runs scheduled jobs for due date reminders, overdue detection, and stale task flagging
- pw-ai-server handles on-demand AI suggestions (suggest task breakdown, auto-fill details)

---

## 3. Repo Responsibilities

**Frontend (`pw-react-client-v3`)**
Owns the task UI — the chat tile cards, the create/edit forms, the status badge, the priority indicator, the assignee picker, the comments section, and the task detail view. Registers socket event handlers for all task events. Manages CARD_EVENTS and EVENTNAMES_ENUM entries for this domain.

Involved when: task card UI changes, status badge, priority display, form fields, assignee UI, comments, attachments, socket handler registration, new chat tile type, filter/sort in task list.

**Backend (`pw-server-v3`)**
Owns all task business logic — CRUD API endpoints, Prisma model, status transition rules, socket event emission, and the REST API consumed by Frontend, ai-cron-server, and pw-notifications.

Involved when: new API endpoint, new Prisma field/model, status logic, socket event changes, permission/role checks, assignee logic, comment/attachment handling.

**Notifications (`pw-notifications`)**
Sends push and in-app notifications for task events: new assignments, due date reminders, status changes, comments mentioning a user.

Involved when: new notification type for a task event, changes to existing task notification templates, notification trigger conditions.

**AI Cron Server (`ai-cron-server`)**
Runs AI-powered scheduled jobs to extract tasks from connected communication channels — Microsoft Teams, Outlook emails, Google Chat, and Gmail. Parses messages/emails using AI to detect actionable items, creates tasks via pw-server-v3 REST API. Does not own any Prisma models.

Involved when: changes to email/chat task extraction logic, new channel support (Teams/Outlook/GChat/Gmail), AI parsing prompt changes, extraction schedule changes, any AI-driven task creation from external sources.

**Cron Jobs (`pw-cron-jobs`)**
Runs one scheduled job for tasks: detects expired tasks and recreates them. When a task's due date passes, this job creates a fresh copy of the task so it reappears for the assignee. Does not own any Prisma models — calls Backend REST API only.

Involved when: changes to the expired task recreation logic, recreation schedule, or what fields are carried over to the new task.

**AI Server (`pw-ai-server`)**
Handles on-demand AI features: task breakdown suggestions, auto-fill from description, smart recommendations. Called directly by Frontend via REST.

Involved when: on-demand AI task suggestions, task auto-generation from user input, smart recommendations.

---

## 4. Feature Areas

| Feature Area | Status | What It Covers |
|---|---|---|
| Task CRUD | ✅ Live | Create, read, update, delete standalone tasks |
| Status Tracking | ✅ Live | todo, in-progress, done, cancelled — with manual updates |
| Assignee Management | ✅ Live | Assign tasks to one or more users |
| Priority Levels | ✅ Live | low, medium, high, urgent |
| Due Dates | ✅ Live | Set and track task due dates |
| Chat Tile | ✅ Live | Task appears as a card in the PW single screen chat |
| Socket Real-time | ✅ Live | All changes broadcast instantly to connected users |
| Attachments | ✅ Live | File attachments on tasks |
| Notifications | ✅ Live | Push + in-app alerts for assignments and due dates |
| Expired Task Recreation | ✅ Live | pw-cron-jobs recreates expired tasks as new records |
| AI Task Suggestions | 🔲 Planned | On-demand task breakdown from pw-ai-server |
| Recurring Tasks | 🔲 Planned | Schedule tasks to repeat on a cadence |

---

## 5. Key User Flows

**Create a task** — user clicks "New Task" in the chat or task panel, fills the form (title, description, assignee, due date, priority), submits. Backend creates the Prisma record, emits a socket event. All connected users see the new tile appear in chat in real time. The assignee receives a notification.

**Update task status** — user clicks the status badge on the task tile, selects a new status (todo / in-progress / done / cancelled). Backend updates the record, emits `task_update` socket event, triggers a notification to the assignee if relevant.

**Assign a task** — user picks an assignee from the assignee picker. Backend updates the assignee field, emits `task_update`, sends an assignment notification to the newly assigned user.

**Expired task recreation** — pw-cron-jobs runs on a schedule, detects tasks whose due date has passed, and recreates them as new task records via pw-server-v3 API. The new task is a copy of the expired one, assigned to the same user, so it resurfaces in their task list.

**Email/chat task extraction** — ai-cron-server connects to Teams, Outlook, GChat, and Gmail on a schedule, uses AI to parse messages and emails for actionable items, and creates tasks via pw-server-v3 API. Users see new task tiles appear automatically from their communication channels.

---

## 6. Key Concepts & Constraints

- **Tasks are standalone** — tasks have no parent goal, OKR, or initiative. They are first-class independent entities.
- **Socket events are the source of truth for real-time UI** — Backend emits after every write. Frontend must register `socket.off()` cleanup for every `socket.on()` handler.
- **Status transitions are open** — unlike initiatives, tasks allow flexible status movement (todo → done, in-progress → cancelled, etc.) without threshold checks.
- **ai-cron-server and pw-cron-jobs only call REST** — neither has direct DB access. All task mutations go through pw-server-v3 API endpoints.
- **ai-cron-server owns communication channel integrations** — Teams, Outlook, GChat, Gmail extraction logic lives here exclusively. Do not put scheduled reminder logic here.
- **pw-cron-jobs owns expired task recreation** — when a task expires, this job recreates it as a new task. Do not put AI/channel extraction logic here.
- **Soft-delete only** — tasks are never hard-deleted. Use `deletedAt` timestamp. Deleted tasks must not appear in lists or socket broadcasts.
- **CARD_EVENTS and EVENTNAMES_ENUM must stay in sync** — if a new socket event is added on Backend, the Frontend enum and card event map must be updated in the same PR.
- **Notifications on assignment and mentions** — notify the assignee when a task is assigned or reassigned. Notify mentioned users in comments.
- **Tasks vs Initiatives** — PW-2252 is replacing the `Initiative` model with `Task`. During the transition, both may coexist. Do not mix them — check the ticket scope to know which model to touch.

---

## 7. Repo-Level Specs

For implementation details — file maps, component structure, socket event list, Prisma model, cron job schedule — read the spec for the affected repo:

| Repo | Spec |
|------|------|
| Frontend | `/Users/sudheer7781/Documents/pw-react-client-v3/.claude/TASKS.md` |
| Backend | `/Users/sudheer7781/Documents/pw-server-v3/.claude/TASKS.md` |
| AI Cron Server | `/Users/sudheer7781/Documents/ai-cron-server/.claude/TASKS.md` |
| Cron Jobs | `/Users/sudheer7781/Documents/pw-cron-jobs/.claude/TASKS.md` |
| Notifications | `/Users/sudheer7781/Documents/pw-notifications/.claude/TASKS.md` |

_(Create these spec files if they don't exist yet — one per repo, describing the file map and implementation details for that repo's task code)_

---

## 8. Trigger Keywords _(jira-prd routing)_

task, tasks, task card, task tile, task status, task list, task detail, create task, update task, delete task, assign task, assignee, task assignee, due date, task due date, overdue, task priority, priority, task comment, task attachment, task notification, task reminder, task board, task management, todo, in-progress, done, cancelled, PW-2252, replace initiatives, task filter, task sort

---

## 9. Routing Guide _(jira-prd routing)_

Use this to narrow the ACTIVE REPO SET for the specific ticket — don't include a repo unless the ticket genuinely requires it.

| Ticket type | Repos |
|-------------|-------|
| Task card UI change, status badge, priority display, assignee UI | Frontend |
| New task field, API endpoint, Prisma model change | Backend |
| Socket event change (new event or payload change) | Backend + Frontend |
| New notification type for task event | Backend + Notifications |
| Expired task recreation (recreate when due date passes) | Cron Jobs + Backend |
| Email/chat task extraction (Teams, Outlook, GChat, Gmail) | AI Cron Server + Backend |
| On-demand AI feature (task suggestions, auto-fill) | AI Server + Frontend |
| End-to-end feature (UI + API + socket) | Frontend + Backend |
| End-to-end with notifications | Frontend + Backend + Notifications |
| Tasks replacing initiatives (PW-2252 scope) | Frontend + Backend |
