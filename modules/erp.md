# Module: ERP

> Loaded automatically when a Jira ticket matches ERP domain keywords.
> This file overrides default routing and provides ERP-specific exploration context.

---

## Affected Repos

Start from this list, then narrow to only repos the ticket actually touches:

| Repo Key | Scope in ERP |
|----------|-------------|
| Backend | ERP API endpoints, Frappe/ERPNext integration, doctype sync, OCR processing, bank reconciliation logic, journal entries |
| Frontend | ERP UI screens, purchase/sales order forms, invoice views, bank reconciliation UI, document upload/scan UI |
| AI Server | OCR document parsing, GST/GSTIN enrichment, AI-assisted data extraction from scanned documents |
| Cron Jobs | Scheduled sync with ERPNext, periodic bank statement fetch, period closing automation |

> Notifications and AI Cron Server are rarely needed for ERP tickets — include only if the ticket explicitly involves alerts or AI-scheduled jobs.

---

## Routing Guide

Use this to narrow the ACTIVE REPO SET beyond what the default routing would suggest:

| Ticket involves... | Repos needed |
|--------------------|-------------|
| Creating/editing a doctype form (PO, SO, Invoice, etc.) | Frontend + Backend |
| Syncing a doctype to/from ERPNext | Backend only |
| OCR scan + data extraction | AI Server + Backend |
| GST/GSTIN enrichment | AI Server + Backend |
| Bank reconciliation (matching entries) | Backend + Frontend |
| Bank transaction import | Backend + Cron Jobs |
| Period closing | Backend + Cron Jobs |
| Payment flow (entry, request, order) | Backend + Frontend |
| Expense claim | Backend + Frontend |

---

## Exploration Checklist (replaces default STEP 3c checklist for ERP tickets)

For each repo in the ACTIVE REPO SET, run this ERP-specific checklist:

### Backend
- [ ] Read `CLAUDE.md` — ERP conventions, Frappe client usage, forbidden patterns
- [ ] Find the existing ERPNext integration layer: `src/erp/` or `src/integrations/frappe/`
- [ ] Read the relevant doctype handler: e.g. `PurchaseOrderService.ts`, `InvoiceService.ts`
- [ ] Read the Frappe client wrapper to understand how API calls to ERPNext are structured
- [ ] Read the Prisma schema — find models that mirror ERPNext doctypes (e.g. `PurchaseOrder`, `SalesOrder`)
- [ ] Check if the doctype already has a sync job or webhook handler
- [ ] Find where document status transitions are handled (submitted, cancelled, amended)
- [ ] Check OCR pipeline if ticket involves scanning: `src/ocr/` or `src/services/OcrService.ts`
- [ ] Check GST enrichment service if ticket involves GSTIN: `src/services/GstService.ts`
- [ ] Find bank reconciliation logic if relevant: `src/services/BankReconciliationService.ts`

### Frontend
- [ ] Read `CLAUDE.md` — ERP UI conventions, component rules
- [ ] Find existing ERP screens: `src/pages/erp/` or `src/components/erp/`
- [ ] Read the nearest similar doctype form (e.g. if PO → read existing SO form as reference)
- [ ] Check shared ERP form components: field renderers, status badges, action buttons
- [ ] Check how document attachments/uploads are handled (for OCR/scan tickets)
- [ ] Read `src/constants/erp-utils.ts` or equivalent for doctype constants
- [ ] Check routing: where ERP routes are registered

### AI Server
- [ ] Read `CLAUDE.md`
- [ ] Find OCR service: parsing pipeline, supported document types
- [ ] Find GSTIN lookup/enrichment flow
- [ ] Read how extracted data is returned to Backend (API shape, confidence scores)

### Cron Jobs
- [ ] Read `CLAUDE.md`
- [ ] Find existing ERPNext sync jobs
- [ ] Read how job scheduling and retry logic works
- [ ] Check bank statement fetch job if relevant

---

## Key Concepts & Constraints

- **Frappe/ERPNext** is the ERP system. All doctype data flows through the Frappe REST API.
- **Doctypes** are ERPNext entities (Purchase Order, Sales Invoice, etc.). Each has a lifecycle: Draft → Submitted → Cancelled.
- **Sync direction**: ERPNext is the source of truth for financials. The PW backend mirrors data into Prisma for fast querying.
- **OCR flow**: Scanned document → AI Server extracts fields → Backend validates → creates/updates ERPNext doctype
- **GST/GSTIN**: GSTIN enrichment fetches business info from government APIs. Cache results — don't call on every request.
- **Bank Reconciliation**: Match bank transactions (from statement import) against journal entries in ERPNext.
- **Period Closing**: Month-end/year-end process that locks accounting periods. Requires careful ordering of operations.
- **Never hard-delete** financial documents — always cancel/amend through ERPNext's lifecycle.
- **Multi-company**: ERPNext supports multiple companies. Always pass `company` context in API calls.

---

## Common Patterns to Follow

When the ticket is [EXTENSION]:
- Extend the existing doctype service rather than creating a new one
- Use the existing Frappe client wrapper — never call Frappe REST directly from new code
- Follow the existing sync pattern (fetch → upsert Prisma → return)

When the ticket is [NEW FEATURE]:
- Reference pattern: look at an existing similar doctype implementation end-to-end
- New Backend service: `src/services/erp/<DocType>Service.ts`
- New Frontend screen: `src/pages/erp/<doctype>/index.tsx`
- Register new route in the ERP router, not the main app router

---

## Additional Clarification Questions for STEP 3.6 (ERP-specific)

Always ask these for ERP tickets, in addition to the standard questions:

1. Should this sync bidirectionally (PW ↔ ERPNext) or unidirectionally?
2. Should the document be created in ERPNext as Draft or Submitted?
3. Is there an existing ERPNext doctype for this, or does it need a custom doctype?
4. Should changes trigger a real-time socket update to the frontend, or is a page refresh acceptable?
5. Are there multi-company considerations — does this need to work across all companies or just one?
