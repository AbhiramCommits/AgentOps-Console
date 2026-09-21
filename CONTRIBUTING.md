# Contributing

## Prerequisites

- Docker + Docker Compose v2 (everything can run containerised)
- For local dev: JDK 21 + Maven 3.9, Node 20+, Python 3 (demo seed generator)

## The local dev loop

```bash
# 1. Start Postgres only (schema comes from the backend's Flyway migrations)
docker compose -f infra/docker-compose.yml up -d postgres

# 2. Backend — applies migrations, restarts on :8080
cd backend
mvn spring-boot:run          # http://localhost:8080, Swagger at /swagger-ui

# 3. Frontend — Vite dev server on :5173, proxies /api to :8080
cd frontend
npm ci
npm run dev

# 4. Optional: load the 500-run demo dataset (screenshots/demos)
./scripts/seed-demo.sh
```

Iterate with hot reload on the frontend; restart the backend after Java
changes. Watch the app at http://localhost:5173.

## Running tests

```bash
# Backend: unit + @WebMvcTest slices + Testcontainers integration, with a
# JaCoCo gate (80% line coverage on service/controller packages)
cd backend && mvn verify

# Frontend: typecheck, lint, Vitest + MSW tests
cd frontend && npx tsc --noEmit && npm run lint && npm test

# E2E: boots the compose stack, rejects a patch, asserts the rate drop
cd e2e && npx playwright test

# Regenerate README screenshots (needs the stack + demo seed running)
cd e2e && npm run screenshots
```

This mirrors `.github/workflows/ci.yml`, which runs all of the above on every
push and PR.

## Conventions

- **Migrations** go in `backend/src/main/resources/db/migration/` as
  `V<n>__description.sql`; never edit an applied migration — add a new one.
- **Layering**: entities stay in `domain/` and are never serialised; services
  own business rules; controllers return DTOs from `api/dto/response`.
- **Errors** are RFC 7807 `ProblemDetail`s thrown from
  `api/error/ApiExceptionHandler` — no `ResponseStatusException` anywhere.
- **Frontend**: typed API client (`src/api/types.ts` + `client.ts`, no `any`),
  CSS Modules with design tokens in `src/styles/tokens.css`; new UI tests mock
  the API with MSW, not `vi.mock` of the client.
- **Coverage** must stay ≥ 80% line coverage on `service` and `api` packages,
  or `mvn verify` fails.
- Commit messages: one-line imperative summary with a bulleted body.
