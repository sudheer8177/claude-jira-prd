# PossibleWorks AI Server

## Project Overview
Node.js + TypeScript AI service for the PossibleWorks platform. Handles LLM-powered features — goal generation, feedback analysis, summaries, embeddings, and AI-driven chat responses.

## Tech Stack
- **Runtime:** Node.js + TypeScript (ESM)
- **Framework:** Express.js
- **AI:** OpenAI API, LangChain
- **ORM:** Prisma (multi-schema)
- **Scheduler:** node-cron / cron
- **Package Manager:** Yarn

## Commands
- `yarn dev` — Start dev server with nodemon + tsx
- `yarn build` — Compile TypeScript (`tsc`)
- `yarn type-check` — Type-check only (`tsc --noEmit`)
- `yarn lint` — Run ESLint
- `yarn prisma:generate` — Regenerate Prisma clients

## Project Structure
```
src/
  config/     — App config, env vars, OpenAI client setup
  constants/  — Shared constants
  models/     — Prisma-based data models / DB access
  prompts/    — LLM prompt templates (one file per feature)
  functions/  — Core AI feature functions (goal gen, feedback, etc.)
  jobs/       — Scheduled cron job definitions
  helpers/    — Utility functions
  logger/     — Winston logger setup
```

## Code Conventions

### Prompts
- Each feature has its own prompt file in `src/prompts/`
- Prompts use template literals with clear `{{variable}}` placeholders
- Always include system role + user role separation
- Keep prompts versioned with comments if changed significantly

### AI Functions
- Each function in `src/functions/` handles one AI task
- Always handle OpenAI errors explicitly — rate limits, token limits, timeouts
- Log token usage for cost tracking
- Validate and sanitize LLM output before returning to caller

### Cron Jobs
- Job definitions in `src/jobs/`
- Use `node-cron` syntax for schedules
- Each job must log start, completion, and any errors
- Jobs must be idempotent — safe to run multiple times

### DB Access
- Use Prisma — never raw SQL
- Always use `$transaction` for multi-step writes

### Naming
- Files: `camelCase.ts`
- Constants: `SCREAMING_SNAKE_CASE`
- Prompt files: `fooPrompt.ts`
- Job files: `fooJob.ts`

## Do NOT
- Hardcode OpenAI model names — use constants
- Ignore LLM response validation — always check for null/empty
- Commit `.env` files or API keys
- Use `any` type
- Skip error handling on OpenAI calls
