# HRIS Module

> Read this before touching any HR-related code across any repo.
> For implementation details, follow the repo-level spec pointers in Section 7.

---

## 1. What This Module Is

PossibleWorks embeds Frappe HRMS as its HR and attendance data layer. Users interact with HRIS entirely inside PossibleWorks — leave applications, attendance regularization, compensatory requests, payslips, and holiday calendars all happen within the PW single screen chat interface. Frappe is the authoritative data store and workflow engine. PossibleWorks is the UI, workflow card, and AI layer on top of it.

Unlike ERP (where Frontend calls Frappe directly), HRIS routes all requests through **pw-server-v3** which calls Frappe on the backend. Every approval action (leave, regularization, compensatory) produces a real-time socket event that updates all connected users instantly. The AI HRIS agent handles natural language queries about attendance, leave, and check-ins.

---

## 2. Data Flow

```
PW Frontend  ──────────────────────→  pw-server-v3        (all HRIS actions, REST + Socket)
                                            │
                                            │  calls Frappe REST API for all data
                                            ↓
                                        Frappe HRMS         (authoritative data store)
                                            │
                                            │  webhook on every doc state change
                                            ↓
                                      pw-server-v3          (resolves workflow tiles in chat)
                                            │
                                            │  socket broadcast on every change
                                            ↓
                                      PW Frontend           (real-time card update)

pw-server-v3 ──────────────────────→  pw-notifications     (leave/attendance alerts)

PW Frontend  ──────────────────────→  pw-ai-server         (natural language HRIS queries)
pw-ai-server ──────────────────────→  pw-server-v3         (HRIS data via MCP tools)
```

- Frontend talks to pw-server-v3 for all HRIS actions — pw-server-v3 calls Frappe internally
- Frappe notifies pw-server-v3 via webhook on every document state change
- pw-server-v3 broadcasts socket events and resolves/creates approval tiles in chat
- pw-ai-server exposes an HRIS agent that handles natural language queries (attendance, leave balance, check-ins) using MCP tools backed by pw-server-v3

---

## 3. Repo Responsibilities

**Frontend (`pw-react-client-v3`)**
Owns the HRIS UI — the dashboard action cards, leave application form, attendance regularization form, compensatory request form, holiday list card, payslip viewer, attendance analytics, leave analytics, and all approval workflow cards in chat. Registers socket event handlers for all HRIS events.

Involved when: HRIS card UI changes, new action card, analytics chart, leave form fields, approval card layout, holiday display, payslip UI, socket handler registration, new HRIS chat tile type.

**Backend (`pw-server-v3`)**
Owns all HRIS business logic — REST API endpoints (28+), Frappe REST integration, socket event emission, workflow state machine (approve/reject/withdraw for leaves, regularization, compensatory), and Frappe webhook handler. Acts as the middleware between Frontend and Frappe HRMS. Owns Prisma models for: Department, Designation, EmployeeType, EmployeeCurrentCompensation, EmployeeProjectedCompensation, EmployeeVariablePayout.

Involved when: new API endpoint, new Frappe doctype integration, workflow action change, webhook handler, socket event changes, role/permission checks, analytics data, payslip download.

**AI Server (`pw-ai-server`)**
Owns the HRIS AI agent — a dedicated subagent (Mastra framework) that answers natural language HR queries using 6 MCP tools: `getAttendance`, `getCheckins`, `getLeaveBalance`, `getLeaveApplications`, `getRegularizationDetails`, `getHolidayList`. Called directly by Frontend via REST/SSE.

Involved when: HRIS agent prompt changes, new MCP tool for HRIS, changes to attendance/leave/check-in data resolution logic, date parsing rules, scope rules (self vs. team vs. span).

**Notifications (`pw-notifications`)**
Sends push and in-app notifications for HRIS events: leave approval/rejection, regularization approval/rejection, compensatory request outcomes.

Involved when: new notification type for HRIS event, changes to leave/attendance notification templates, notification trigger conditions.

**Cron Jobs (`pw-cron-jobs`)**
Has a scheduled job related to HRIS user invite flow (`feat/userinvite-hris`). Handles any scheduled HRIS maintenance that calls pw-server-v3 REST API.

Involved when: HRIS-related scheduled job changes, user invite + HRIS provisioning.

---

## 4. Feature Areas

| Feature Area | Status | What It Covers |
|---|---|---|
| Leave Management | ✅ Live | Apply, approve, reject, withdraw, revoke leaves via Frappe Leave Application |
| Attendance Tracking | ✅ Live | Day-level attendance status (Present, Absent, On Leave, Half Day, Holiday) |
| Check-in / Check-out | ✅ Live | Granular entry/exit event logs from Frappe |
| Attendance Regularization | ✅ Live | Employee requests correction; manager approves/rejects; overrides attendance |
| Compensatory Leave | ✅ Live | Request, approve, reject compensatory leave claims |
| Holiday Calendar | ✅ Live | Company and optional holiday list from Frappe |
| Payslip Delivery | ✅ Live | View payslip periods and download payslip PDF from Frappe |
| Attendance Analytics | ✅ Live | Charts and trends for attendance across cycles |
| Leave Analytics | ✅ Live | Leave usage charts across cycles |
| HRIS AI Agent | ✅ Live | Natural language queries for attendance, leave, check-ins via pw-ai-server |
| Organization Details | ✅ Live | Employee org structure, department, designation from Frappe |
| Manager Team View | ✅ Live | Managers can view team attendance, leave, regularization |
| Frappe Webhook Sync | ✅ Live | Frappe fires webhook on every doc change → pw-server-v3 resolves workflow tiles |
| Exit Application Status | ✅ Live | Offboarding/exit status check |

---

## 5. Key User Flows

**Apply for leave** — employee opens HRIS dashboard, clicks ApplyLeaveCard, fills form (leave type, from/to date, reason). Frontend emits `REQUEST_LEAVE` socket event → pw-server-v3 calls Frappe `POST /api/resource/Leave Application`, creates a PENDING action record, emits socket message to manager's chat. Manager sees LeaveApplicationChatCard, clicks Approve → `APPROVE_LEAVE` socket → pw-server-v3 calls Frappe `applyWorkflowAction('Approve')` → Frappe auto-creates attendance record (On Leave) → socket broadcasts approval.

**Attendance regularization** — employee notices missing/incorrect attendance, opens regularization form, submits reason. Frontend emits `REQUEST_ATTENDANCE_REGULARIZATION` → pw-server-v3 creates Frappe Attendance Regularization Request, emits to manager. Manager approves → Frappe overrides attendance record → socket confirms.

**Compensatory leave** — employee worked on a holiday, opens CompensatoryRequestCard, submits claim. `REQUEST_COMPENSATORY_REQUEST` → Frappe Compensatory Leave Request created → manager approves → compensatory leave balance credited.

**AI HRIS query** — employee types "How many leaves do I have left?" → Frontend calls pw-ai-server HRIS agent → agent calls `getLeaveBalance(userIds)` MCP tool → pw-server-v3 fetches from Frappe → agent formats and returns natural language response streamed via SSE.

**Manager team view** — manager opens HRIS dashboard, selects team member → Frontend calls attendance/leave endpoints with teamMember scope → pw-server-v3 checks authorization (must be direct report or span member) → fetches from Frappe → renders analytics for that employee.

**Payslip** — employee clicks payslip section, selects cycle → pw-server-v3 calls Frappe payslip periods and details → employee downloads PDF via `/download-payslip` endpoint.

**Frappe webhook sync** — Frappe fires POST to `/frappe/workflow-events` on any document update (Leave Application, Attendance Request, Compensatory Request, Regularization Request) → pw-server-v3 `updateWorkFlowHris()` checks doctype, applies workflow action, creates socket message, updates action history in DB.

---

## 6. Key Concepts & Constraints

- **Frappe is the data authority** — all leave, attendance, check-in, regularization, and payslip records live in Frappe HRMS. pw-server-v3 only caches Department, Designation, and compensation models locally in Prisma.
- **Frontend never calls Frappe directly for HRIS** — unlike ERP forms, all HRIS requests go through pw-server-v3 which calls Frappe internally. Never bypass this.
- **Record hierarchy** — Check-ins → Attendance → overridden by Approved Regularization. Leave Application approval auto-creates Attendance (On Leave). Keep this order in mind when debugging data discrepancies.
- **Leave Application ≠ Attendance** — a Leave Application is a request. Only when approved does Frappe auto-create the corresponding Attendance record.
- **Socket events must stay in sync** — `CARD_EVENTS` and `EVENTNAMES_ENUM` on Frontend must match socket event names emitted by Backend. Update both in the same PR.
- **Access control: self vs. team vs. span** — employees see only their own data. Managers see direct reports (`teamMembers`) or full span (`spanMembers`). Always enforce this in service layer, never trust client-side scope claims.
- **Multi-tenancy** — all HRIS queries include `tenantId`. Use `getTenantPrismaClient(tenantId)` and tenant-specific Frappe connection (`tenantConnection.frappe_url`, `frappe_user_auth`).
- **OAuth with Frappe** — authenticate with Frappe using `frappe_user_auth` (access_token, refresh_token) per tenant. Never hardcode credentials.
- **HRIS AI agent tool scope** — agent tools are: `getAttendance`, `getCheckins`, `getLeaveBalance`, `getLeaveApplications`, `getRegularizationDetails`, `getHolidayList`. `getCheckins` is single-user/single-date only. `getAttendance` supports batch. Do not use cross-tool data as input without resolving cycle IDs first.
- **Soft-delete only** — never hard-delete any HRIS-related Prisma records.

---

## 7. Repo-Level Specs

For implementation details — file maps, component structure, socket event list, Prisma models, Frappe API calls, MCP tools — read the spec for the affected repo:

| Repo | Spec |
|------|------|
| Frontend | `/Users/sudheer7781/Documents/pw-react-client-v3/.claude/HRIS.md` |
| Backend | `/Users/sudheer7781/Documents/pw-server-v3/.claude/HRIS.md` |
| AI Server | `/Users/sudheer7781/Documents/pw-ai-server/.claude/HRIS.md` |
| Notifications | `/Users/sudheer7781/Documents/pw-notifications/.claude/HRIS.md` |
| Cron Jobs | `/Users/sudheer7781/Documents/pw-cron-jobs/.claude/HRIS.md` |

_(Create these spec files if they don't exist yet — one per repo, describing the file map and implementation details for that repo's HRIS code)_

---

## 8. Trigger Keywords _(jira-prd routing)_

hris, HRIS, leave, leave application, leave balance, leave type, leave approval, leave rejection, leave withdrawal, leave revoke, attendance, attendance regularization, regularization, check-in, check-out, checkin, checkout, compensatory, compensatory leave, payslip, payroll, salary slip, holiday, holiday list, optional holiday, employee, department, designation, org chart, organization, exit application, offboarding, attendance analytics, leave analytics, team attendance, manager view, frappe hrms, frappe user, apply leave, approve leave, reject leave

---

## 9. Routing Guide _(jira-prd routing)_

Use this to narrow the ACTIVE REPO SET for the specific ticket — don't include a repo unless the ticket genuinely requires it.

| Ticket type | Repos |
|-------------|-------|
| HRIS card UI change, new action card, form field, analytics chart | Frontend |
| New API endpoint, new Frappe doctype integration, workflow change | Backend |
| Frappe webhook handler, workflow state machine change | Backend |
| Socket event change (new event or payload change) | Backend + Frontend |
| New notification type for HRIS event | Backend + Notifications |
| HRIS AI agent prompt change, new MCP tool, data resolution logic | AI Server |
| Natural language HRIS query feature (end-to-end) | AI Server + Frontend |
| Permission/role check, team vs. span access | Backend |
| Payslip, org details, exit status | Backend + Frontend |
| End-to-end HRIS feature (form + approval workflow + socket) | Frontend + Backend |
| End-to-end with AI agent | Frontend + Backend + AI Server |
| Scheduled HRIS job, user invite + HRIS provisioning | Cron Jobs + Backend |
