# PossibleWorks Backend Server v3

## Project Overview
Node.js + TypeScript REST API and Socket.IO server for the PossibleWorks HR/Performance platform. Handles all business logic, chat actions, leave management, goals, feedback, and HRIS integrations.

## Tech Stack
- **Runtime:** Node.js + TypeScript (ESM)
- **Framework:** Express.js
- **ORM:** Prisma (multi-schema: `common-schema.prisma` + `schema.prisma`)
- **Realtime:** Socket.IO
- **Package Manager:** Yarn

## Commands
- `yarn dev` — Start dev server with nodemon + tsx
- `yarn build` — Compile TypeScript
- `yarn type-check` — Type-check only (no emit)
- `yarn lint` — Run ESLint
- `yarn prisma:generate` — Regenerate Prisma clients

## Project Structure
```
src/
  controllers/   — Express route handlers
  routes/v1/     — Express route definitions
  services/      — Business logic (one file per domain)
  helpers/       — Utility functions by domain (chat, leave, goal, email, etc.)
  middleware/    — Auth, error handling, tenant context
  providers/     — Third-party integrations (frappe, docusign, etc.)
  constants/     — Shared constants and enums
  utils/         — Generic utilities
  types/         — TypeScript type declarations
  config/        — App configuration
  db/            — Prisma client setup, seeders
  migrations/    — DB migrations
  secrets/       — Secret management
prisma/
  schema.prisma         — Tenant schema
  common-schema.prisma  — Common/shared schema
```

## Code Conventions

### Services
- One service file per domain: `leaveService.ts`, `goalService.ts`, etc.
- All DB access goes through Prisma — never raw SQL
- Use `$transaction` for multi-step operations that must be atomic
- Always use `findMany` with explicit `select` — never fetch all fields

### Socket Events
- Socket event names match `EVENTNAMES_ENUM` in the frontend
- Emit to users via `io.to(socketId).emit(eventName, payload)`
- Socket callback pattern: `({ status, message, responseMessage })`
- Always emit error with `status: 'error'` and a `message` string

### Controllers
- Thin controllers — delegate to services
- Always `try/catch` in controllers, return `res.status(500).json({ message })`
- Auth middleware attaches `req.user` with `uuid`, `role`, `tenantId`

### Card Data Pattern (Chat Actions)
- Card messages stored in DB with `message.card.data` containing all action state
- `eventName` on card data identifies the card type
- `status` field: `PENDING`, `COMPLETED`, `EXPIRED`, `INVERSE_COMPLETED`
- `isWithdrawn`, `isRevoked` flags used for leave/revoke flow

### Naming
- Files: `camelCase.ts`
- Services: `fooService.ts`
- Constants: `SCREAMING_SNAKE_CASE`
- DB models: PascalCase (Prisma convention)

### Error Handling
- Throw typed errors from services, catch in controllers
- Log errors with context (userId, tenantId, operation)

## Do NOT
- Use raw SQL — always use Prisma
- Skip `$transaction` for multi-step DB writes
- Hardcode tenant IDs or user IDs
- Commit `.env` files
- Use `any` type — define proper TypeScript interfaces
