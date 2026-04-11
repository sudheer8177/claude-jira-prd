# PossibleWorks Notifications Server

## Project Overview
Node.js notification service handling push notifications (FCM/web-push/OneSignal), email, and in-app alerts for the PossibleWorks platform. Listens for events and dispatches notifications across all channels.

## Tech Stack
- **Runtime:** Node.js (JavaScript — no TypeScript)
- **Framework:** Express.js + Socket.IO
- **ORM:** Sequelize (PostgreSQL)
- **Push:** Firebase Admin (FCM), web-push, OneSignal, AWS SNS
- **Email:** Nodemailer / AWS SES / SendGrid
- **Logging:** Winston
- **Dev:** nodemon

## Commands
- `npm start` — Start with nodemon (dev mode)

## Project Structure
```
src/
  constants/    — Event names, notification types, templates
  providers/    — Channel integrations (FCM, OneSignal, SES, web-push)
  models/       — Sequelize model definitions
  controllers/  — Route handlers
  routes/       — Express route definitions
  helpers/      — Utility functions
logs/           — Winston log files
```

## Code Conventions

### Notification Channels
- **FCM/Firebase** — Mobile push via `firebase-admin`
- **Web Push** — Browser push via `web-push`
- **OneSignal** — Cross-platform push
- **Email** — via nodemailer / SES / SendGrid
- Each channel has its own provider file in `src/providers/`

### Adding a New Notification Type
1. Add the event/type constant in `src/constants/`
2. Create or update the template in `src/helpers/`
3. Add the provider call in the appropriate handler
4. Register the route in `src/routes/`

### Models (Sequelize)
- One model file per table in `src/models/`
- Use Sequelize associations — never raw JOINs
- Always define `timestamps: true` on models

### Error Handling
- Always catch provider errors (FCM, SES can fail silently)
- Log all notification send attempts with outcome
- Never crash the process on single notification failure

### Naming
- Files: `camelCase.js`
- Constants: `SCREAMING_SNAKE_CASE`
- Routes: `kebab-case` paths

## Do NOT
- Send notifications synchronously in request handlers — queue or async
- Hardcode FCM server keys or email credentials
- Skip logging of notification send results
- Commit `.env` files
