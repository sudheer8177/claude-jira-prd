# PossibleWorks React Client v3

## Project Overview
HR/Performance management platform built with React 18, TypeScript, Vite, Recoil, MUI, Emotion, and Socket.IO.

## Tech Stack
- **Framework:** React 18 + TypeScript 5
- **Build:** Vite 5 (`yarn build` runs `tsc -b && vite build`)
- **State:** Recoil (atoms, selectors, loadables)
- **UI:** MUI + Emotion (styled components)
- **Realtime:** Socket.IO (event-driven chat/actions)
- **Forms:** react-hook-form
- **Package Manager:** Yarn

## Commands
- `yarn dev` — Start dev server
- `yarn build` — Type-check + production build
- `npx tsc -b` — Type-check only

## Project Structure
```
src/
  api/           — API service functions (one per domain)
  assets/        — SVGs, images
  components/
    atoms/       — Base UI components (PWButton, PWIcon, PWTypography, etc.)
    molecules/   — Composite components (ApplyLeaveCard, CompensatoryRequest, etc.)
  constants/     — Shared constants (utils.ts has CARD_EVENTS, ACTION_STATUS, etc.)
  context/       — React contexts (SocketContext)
  helpers/       — Utility functions
  hooks/         — Custom React hooks
  models/
    enums/       — TypeScript enums (EVENTNAMES_ENUM for socket events)
  pages/         — Route-level page components
  recoil/        — Recoil atoms, selectors, queries
```

## Code Conventions

### Socket Events
- All socket event names are defined in `src/models/enums/event-names-enum.ts` as `EVENTNAMES_ENUM`
- Card event names for UI display are in `src/constants/utils.ts` as `CARD_EVENTS`
- Socket handlers go in `src/components/molecules/SingleScreen/Chat/hooks/useSocketEvents.ts`
- Always register both `socket.on()` AND `socket.off()` cleanup for every event

### State Management
- Use Recoil `useRecoilValueLoadable` for async data, check `.state === 'hasValue'` before accessing `.contents`
- Atom/selector naming: `fooQuery` for selectors, `fooAtom` for atoms
- Chat messages stored as `Map<string, SocketMessage>`

### Component Patterns
- Styled components use Emotion (imported from `@emotion/react` or local `./style` files)
- Use `PWTypography`, `PWButton`, `PWIcon` atoms — never raw MUI components
- Form state managed with `react-hook-form` (`Controller` + `useForm`)
- Loading states use `ClipLoader` or MUI `CircularProgress`

### Naming
- Enum values: `SCREAMING_SNAKE_CASE`
- Constants: `SCREAMING_SNAKE_CASE`
- Components: `PascalCase`
- Files: `index.tsx` inside named folders for components
- Socket event strings: `snake_case` (e.g., `'request_revoke_leave'`)

### Error Handling
- Socket callbacks: `({ status, message, responseMessage }) => { ... }`
- Always show snack on error: `setSnackText({ title: msg, type: 'error' })`
- Wrap socket emits in try/catch

## Do NOT
- Create new files unless absolutely necessary — edit existing ones
- Use raw HTML elements when PW atoms exist
- Skip socket cleanup (`.off()`) in useEffect return
- Call `refreshChatUsers()` more than once per handler
- Add comments or docstrings unless logic is non-obvious
