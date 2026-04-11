# PossibleWorks AI Cron Server

## Project Overview
TypeScript scheduled job server running AI-powered automations — initiative suggestions, goal progress analysis, feedback generation, and other LLM-driven background tasks for the PossibleWorks platform.

## Tech Stack
- **Runtime:** Node.js + TypeScript
- **AI:** OpenAI API, LangChain
- **ORM:** Sequelize (PostgreSQL)
- **Scheduler:** node-cron / cron
- **OCR:** tesseract.js
- **Logging:** Winston
- **Build:** `tsc`

## Commands
- `npm run dev` — Dev mode with nodemon
- `npm run build` — Compile TypeScript
- `npm start` — Build + run `dist/src/functions/scheduleJobs.js`

## Project Structure
```
src/
  config/     — DB config, OpenAI client, env setup
  constants/  — Job names, prompt constants, shared enums
  models/     — Sequelize model definitions
  prompts/    — LLM prompt templates per feature
  functions/  — Core functions (AI logic, data processing)
  jobs/       — Cron job definitions (scheduleJobs.ts is the entry)
  helpers/    — Utility functions
  logger/     — Winston logger configuration
dist/         — Compiled output
```

## Code Conventions

### Entry Point
- `src/functions/scheduleJobs.ts` — registers all cron jobs
- Each job imported from `src/jobs/`

### Cron Jobs
- Define schedule, function, and error handler per job
- Use `node-cron` syntax: `'0 9 * * *'` format
- Every job must: log start → execute → log result/error
- Jobs must be idempotent — safe to re-run if they fail mid-way

### Prompts
- One file per AI feature in `src/prompts/`
- Use clearly named template variables
- Never hardcode model names — use constants from `src/constants/`

### AI Functions
- Validate all LLM output before using it
- Handle OpenAI errors: rate limit (429), timeout, empty response
- Log token usage per job run

### DB Access (Sequelize)
- Define all models in `src/models/`
- Use transactions for multi-table writes
- Never use raw SQL

### Naming
- Files: `camelCase.ts`
- Job files: `fooJob.ts`
- Prompt files: `fooPrompt.ts`
- Constants: `SCREAMING_SNAKE_CASE`

## Do NOT
- Put business logic directly in job scheduler — use functions/
- Hardcode model names, tenant IDs, or user IDs
- Skip error handling on any job — a failing job must not crash others
- Commit `.env` files
- Use `any` type
