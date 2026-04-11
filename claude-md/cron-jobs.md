# PossibleWorks Cron Jobs

## Project Overview
TypeScript scheduled job server for data automation — goal reminders, attendance reports, leave summaries, email triggers, Google Sheets sync, and other periodic data operations for the PossibleWorks platform.

## Tech Stack
- **Runtime:** Node.js + TypeScript
- **ORM:** Sequelize (PostgreSQL)
- **Scheduler:** node-cron / cron
- **Email:** Nodemailer, SendGrid (`@sendgrid/mail`)
- **Google:** googleapis (Sheets, Calendar)
- **AI:** OpenAI, LangChain (for smart job features)
- **Logging:** Winston
- **Build:** `tsc`

## Commands
- `npm run dev` — Dev mode with nodemon
- `npm run build` — Compile TypeScript
- `npm start` — Build + run `dist/src/functions/scheduleJobs.js`

## Project Structure
```
src/
  config/     — DB config, Google/SendGrid/OpenAI client setup
  constants/  — Job names, email templates, shared enums
  models/     — Sequelize model definitions
  functions/  — Core data processing functions + scheduleJobs.ts (entry)
  jobs/       — Individual cron job definitions
  helpers/    — Utility functions (date, email formatting, etc.)
  logger/     — Winston logger configuration
dist/         — Compiled output
```

## Code Conventions

### Entry Point
- `src/functions/scheduleJobs.ts` — registers all cron jobs
- Each job imported from `src/jobs/`

### Cron Jobs
- Use `node-cron` syntax: `'0 9 * * 1'` (9am every Monday)
- Every job must: log start → execute → log success/error
- Jobs must be idempotent — safe to re-run
- Each job isolated: one job failing must not affect others

### Email Jobs
- Use SendGrid for transactional emails
- Use Nodemailer for internal/SMTP emails
- Always use HTML templates from `src/helpers/` — never inline HTML in jobs
- Log each email send attempt with recipient and outcome

### Google Integration
- Google Sheets sync via `googleapis`
- Credentials via env vars — never hardcode
- Handle quota errors gracefully with retry logic

### DB Access (Sequelize)
- One model file per table in `src/models/`
- Use transactions for multi-table writes
- Never raw SQL

### Naming
- Files: `camelCase.ts`
- Job files: `fooJob.ts`
- Constants: `SCREAMING_SNAKE_CASE`

## Do NOT
- Put logic directly in the scheduler — use jobs/ and functions/
- Hardcode tenant IDs, user IDs, or email addresses
- Send emails without logging the result
- Skip error handling — wrap every job in try/catch
- Commit `.env` files or Google service account JSON
- Use `any` type
