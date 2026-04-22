# ERP Module

> Read this before touching any finance-related code across any repo.
> For implementation details, follow the repo-level spec pointers in Section 7.

---

## 1. What This Module Is

PossibleWorks embeds Frappe/ERPNext as its finance and operations layer. Users interact with ERP entirely inside PossibleWorks — forms, approvals, document scanning, and master creation all happen within the PW single screen. Frappe is the data store and business logic engine. PossibleWorks is the UI and workflow layer on top of it.

Every ERP form is a constant config file — one file per doctype — that declares all fields, calculations, mappings, and triggers. The engine components are generic and never change per doctype. Adding a new doctype means writing one new config file, nothing else.

---

## 2. Data Flow

```
PW Frontend  ──────────────────────→  Frappe REST API    (all form CRUD, direct)
                                            │
                                            │  webhook on every doc state change
                                            ↓
                                      pw-server-v3        (approval tiles, permissions)

PW Frontend  ──────────────────────→  pw-ai-server       (OCR scan, master enrich)
pw-ai-server ──────────────────────→  Frappe REST API    (master lookups during OCR)
```

- Frontend talks to Frappe directly for all form operations — pw-server-v3 is not in that path
- Frappe notifies pw-server-v3 via webhook on every document state change
- Frontend calls pw-ai-server for OCR and supplier/customer enrichment
- pw-ai-server calls Frappe independently to ground master data during scan

---

## 3. Repo Responsibilities

**Frontend (`pw-react-client-v3`)**
Owns the entire form layer — the config-driven engine, all ERP screens, OCR scan UI, chat workflow tiles, and inline master creation. All Frappe calls originate here.

Involved when: form UI changes, new doctype config, OCR flow, downstream mapping, master picker, chat tile display.

**Backend (`pw-server-v3`)**
Two things only: returns per-user doctype permissions to the frontend, and receives Frappe webhooks to create and resolve approval tiles in PW chat. The same code path runs whether the user acts from PW or directly from Frappe UI.

Involved when: webhook handling, approval tile creation/resolution, doctype permission checks.

**AI Server (`pw-ai-server`)**
Two things only: OCR scan pipeline (PDF/image + doctype → AI agent → structured ERP JSON streamed via SSE), and master enrich (GSTIN + website → pre-filled Supplier or Customer payload).

Involved when: OCR pipeline changes, new doctype scan support, supplier/customer enrich flow.

---

## 4. Finance Modules & Doctypes

| Module              | Status     | Doctypes                                                                                                                             |
| ------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Accounts Payable    | ✅ Live    | Material Request, Request for Quotation, Supplier Quotation, Purchase Order, Purchase Receipt, Landed Cost Voucher, Purchase Invoice |
| Payments            | ✅ Live    | Payment Entry, Payment Request, Payment Order                                                                                        |
| Accounts Receivable | 🔲 Planned | Quotation, Sales Order, Delivery Note, Sales Invoice                                                                                 |
| Cash & Bank         | 🔲 Planned | Bank Transaction, Bank Reconciliation Tool, Payment Reconciliation                                                                   |
| Expenses            | 🔲 Planned | Expense Claim                                                                                                                        |
| GL & Period-End     | 🔲 Planned | Journal Entry, Period Closing Voucher                                                                                                |

---

## 5. Document Chain

Documents chain into each other. A submitted doc becomes a chat tile, and from that tile the user can create the next document in the chain — which opens pre-filled.

AP buy cycle example:

```
Material Request → Request for Quotation → Supplier Quotation
  → Purchase Order → Purchase Receipt → Purchase Invoice → Payment Entry
```

Two mechanisms drive chaining:

- **Get Items From** — user pulls line items from a previous doc into the current form
- **Downstream mapping** — after submission, the chat tile offers to create the next doc with fields pre-mapped

---

## 6. Key User Flows

**Create a document** — user picks a module and doctype, form opens from the config, user fills and submits, Frappe saves and fires a webhook, pw-server-v3 creates an approval tile in chat for the correct approver.

**Scan a document** — user uploads a file or uses camera, frontend sends it to pw-ai-server, the AI agent runs Frappe-grounded tools and streams phases back via SSE, on complete the form opens pre-filled, unmatched masters appear as "Create?" chips.

**Approve a document** — approver sees a tile in chat, clicks Approve/Reject, pw-server-v3 calls Frappe apply_workflow, Frappe fires on_update, pw-server-v3 resolves the tile and creates the next one if the workflow has more levels.

**Enrich a master** — user enters GSTIN or website in the master picker, pw-ai-server fetches GST registry data and scrapes the website in parallel, returns a pre-filled Supplier or Customer payload.

---

## 7. Repo-Level Specs

For implementation details — file maps, component behaviour, config keys, pipeline steps — read the spec for the affected repo:

| Repo      | Spec                                                                          |
| --------- | ----------------------------------------------------------------------------- |
| Frontend  | `/Users/mohdamankhan/Desktop/Possibleworks/pw-react-client-v3/.claude/ERP.md` |
| Backend   | `/Users/mohdamankhan/Desktop/Possibleworks/pw-server-v3/.claude/ERP.md`       |
| AI Server | `/Users/mohdamankhan/Desktop/Possibleworks/pw-ai-server/.claude/ERP.md`       |

---

## 8. Trigger Keywords _(jira-prd routing)_

purchase order, sales order, invoice, supplier, customer, payment entry, payment request, payment order, journal entry, quotation, delivery note, purchase receipt, landed cost voucher, expense claim, material request, request for quotation, supplier quotation, frappe, erpnext, doctype, OCR, scan, GST, GSTIN, enrich, bank reconciliation, bank transaction, period closing

---

## 9. Routing Guide _(jira-prd routing)_

Use this to narrow the ACTIVE REPO SET for the specific ticket — don't default to all three repos unless the ticket genuinely spans all three.

| Ticket type                                                   | Repos                          |
| ------------------------------------------------------------- | ------------------------------ |
| New doctype config, form UI change, field layout, child table | Frontend                       |
| OCR pipeline change, new doctype scan support                 | AI Server + Frontend           |
| Supplier / customer enrich flow                               | AI Server + Frontend           |
| Webhook handling, approval tile creation/resolution           | Backend                        |
| Doctype permission check or user role access                  | Backend                        |
| End-to-end feature (form + approval flow)                     | Frontend + Backend             |
| End-to-end feature with scan                                  | Frontend + Backend + AI Server |
