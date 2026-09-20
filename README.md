# AgentOps Console

Dashboard for tracking AI coding-agent runs: prompt variants, patches, costs, and
review verdicts.

```
┌─────────────┐     ┌──────────────────────┐     ┌──────────────┐
│  frontend   │     │       backend        │     │   postgres   │
│ React 18 +  │ ──► │ Spring Boot 3.3      │ ──► │  postgres:16 │
│ Vite/nginx  │ /api│ Java 21 + Flyway     │ JDBC│  Flyway V1-V3│
│    :5173    │     │        :8080         │     │    :5435     │
└─────────────┘     └──────────┬───────────┘     └──────────────┘
                               │ /actuator/prometheus
                        ┌──────▼──────┐
                        │ prometheus  │
                        │    :9090    │
                        └─────────────┘
```

## Layout

| Path        | Contents                                                                     |
| ----------- | ---------------------------------------------------------------------------- |
| `backend/`  | Spring Boot 3.3 (Java 21, Maven): web, data-jpa, validation, actuator, flyway, postgresql, testcontainers |
| `frontend/` | React 18 + TypeScript + Vite, React Router, TanStack Query, Vitest + React Testing Library |
| `infra/`    | `docker-compose.yml` (postgres, backend, frontend, prometheus) + prometheus config |

## Frontend

All API payloads are typed in `frontend/src/api/types.ts`; the fetch wrapper in
`frontend/src/api/client.ts` is fully typed (no `any`; `tsc --noEmit` is part of
the build). Styling is plain CSS Modules with design tokens
(`src/styles/tokens.css`: color, spacing, type scale) and automatic dark mode
via `prefers-color-scheme`.

| Route         | Description                                                                   |
| ------------- | ----------------------------------------------------------------------------- |
| `/`           | Runs list — filters (variant, status, date range), server-side pagination, loading skeletons, empty state |
| `/runs/:id`   | Run detail — expandable side-by-side diff view (parsed unified diffs with `+`/`-` gutters), Accept / Reject with optimistic updates; Reject requires an override reason in a `<dialog>` modal |
| `/compare`    | Pick two prompt variants — acceptance rate, median latency, cost per accepted patch, with deltas |
| `/metrics`    | Live SVG line charts (acceptance, cost, latency per variant), polls every 15s with a "last updated" timestamp |

## Prerequisites

- Docker with Docker Compose v2 (`docker compose version`)
- Optional, for local dev outside Docker: JDK 21 + Maven 3.9, Node 20+

## Quick start

```bash
docker compose -f infra/docker-compose.yml up --build
```

The first build takes a few minutes (Maven + npm). Flyway applies the migrations
automatically on first backend startup, including the seed data.

| Service    | URL                                   |
| ---------- | ------------------------------------- |
| Frontend   | http://localhost:5173                 |
| Backend    | http://localhost:8080                 |
| Postgres   | `localhost:5435` (user/pass/db: `agentops`) |
| Prometheus | http://localhost:9090                 |

Verify:

```bash
curl -s http://localhost:8080/actuator/health
# {"status":"UP", ...}

curl -s http://localhost:8080/api/runs | head -c 200
curl -s http://localhost:5173/api/metrics/acceptance?bucket=week | head -c 200
```

Stop it:

```bash
docker compose -f infra/docker-compose.yml down
# add -v to also delete the Postgres data volume (migrations re-run on next up)
```

### Port conflicts

Postgres is published on host port **5435** (5432–5434 are reserved by Docker
Desktop on macOS). The backend/frontend/prometheus ports can be overridden
without editing the compose file:

```bash
BACKEND_PORT=18080 FRONTEND_PORT=15173 docker compose -f infra/docker-compose.yml up
```

## Database schema (Flyway)

Migrations live in `backend/src/main/resources/db/migration/`.

### `V1__init.sql`

| Table             | Purpose                                                        |
| ----------------- | -------------------------------------------------------------- |
| `prompt_variant`  | Named prompt templates being A/B tested                        |
| `agent_run`       | One agent run; references the prompt variant used; status check (`RUNNING`/`SUCCEEDED`/`FAILED`) |
| `patch`           | A diff produced by a run; FK to `agent_run` with `ON DELETE CASCADE` |
| `review_verdict`  | Current verdict on a patch; unique FK to `patch`; decision check (`ACCEPTED`/`REJECTED`) |
| `review_audit`    | Audit trail — every verdict change (create/amend) appended, history never overwritten |

Indexes (each commented with the query it serves):

| Index                                    | Serves                                              |
| ---------------------------------------- | --------------------------------------------------- |
| `agent_run (started_at DESC)`            | dashboard recent-runs list — `GET /api/runs`        |
| `agent_run (prompt_variant_id, started_at)` | runs filtered by variant — `GET /api/runs?variantId=` |
| `patch (run_id)`                         | patches of a run — `GET /api/runs/{id}`             |
| `review_verdict (decision, decided_at)`  | acceptance stats over time — `GET /api/metrics/acceptance` |
| `review_audit (patch_id, changed_at)`    | per-patch review history (V3)                       |

### `V2__seed.sql`

Deterministic seed data so the dashboard is populated on first boot:

- 8 prompt variants with realistic templates (baseline → aggressive-refactor)
- 40 agent runs (34 succeeded, 4 failed, 2 running) spread over ~45 days
- 200 patches with genuine unified-diff text; `lines_added`/`lines_removed` match the diffs
- 140 review verdicts (~70% of patches); acceptance rates vary per variant (43% → 94%)

Timestamps are relative to `NOW()` so the data always looks fresh.

### `V3__review_audit.sql`

Append-only audit trail for review verdicts. `review_verdict` always holds the
current state; every create or amend also inserts a row into `review_audit`
(`action` = `CREATED`/`AMENDED`) so the full history is preserved.

## API

All errors are RFC 7807 `application/problem+json` `ProblemDetail` responses
(type/title/status/detail/instance + field errors for validation failures).

| Endpoint                     | Description                                   |
| ---------------------------- | --------------------------------------------- |
| `GET /api/runs`              | Paginated, sorted by `started_at` desc; filters `?variantId=&status=&from=&to=&page=&size=` |
| `GET /api/runs/{id}`         | Run detail with its patches and each patch's verdict |
| `POST /api/runs`             | Ingest a run with its patches in one transaction (atomic) |
| `GET /api/patches/{id}`      | Single patch with full diff and verdict       |
| `POST /api/patches/{id}/review` | Record first verdict `{reviewer, decision, overrideReason}` — 409 if already reviewed |
| `PUT /api/patches/{id}/review`  | Amend the verdict; previous state kept in `review_audit` |
| `GET /api/variants`          | All prompt variants                           |
| `POST /api/variants`         | Create a prompt variant                       |
| `GET /api/metrics/acceptance?bucket=day\|week` | Acceptance rate per variant per time bucket (native SQL, `date_trunc` + `GROUP BY`) |
| `GET /api/metrics/cost-latency?bucket=day\|week` | p50/p95 latency and summed cost per variant per bucket (native SQL, `percentile_cont`) |
| `GET /actuator/health`       | Health (liveness/readiness probes)            |
| `GET /actuator/prometheus`   | Prometheus metrics: JVM/HTTP + custom `agentops_patches_reviewed_total{decision=}` counter and `agentops_run_ingest_seconds` timer |

Review rules: a `REJECTED` decision requires a non-blank `overrideReason`
(400 otherwise); a patch can only be reviewed once via `POST` (409 on repeat,
use `PUT` to amend). The two metrics endpoints are implemented as native SQL
with `date_trunc`/`percentile_cont` + `GROUP BY` (no in-memory aggregation);
the SQL comments show the `EXPLAIN` plans using the V1 indexes.

## Local development (without Docker)

```bash
# 1. Start Postgres only
docker compose -f infra/docker-compose.yml up -d postgres

# 2. Backend (Flyway applies migrations on startup)
cd backend
mvn spring-boot:run        # http://localhost:8080

# 3. Frontend (Vite dev server, proxies /api -> :8080)
cd frontend
npm install
npm run dev                # http://localhost:5173
```

## Tests

```bash
# Backend — full suite incl. JaCoCo coverage gate (80%+ line coverage on
# the service and controller packages; the build fails below it)
cd backend && mvn verify
#    unit tests:      Mockito service tests (review rules, 409, rate math)
#    slice tests:     @WebMvcTest asserting status codes + ProblemDetail shape
#    integration:     Testcontainers postgres:16 running the real Flyway
#                     migrations + seed, with a month of fixture data asserting
#                     date_trunc buckets and percentile_cont p50/p95

# Frontend — Vitest + React Testing Library, API mocked with MSW
cd frontend && npm ci && tsc --noEmit && npm run lint && npm test && npm run build

# E2E — boots the docker-compose stack (globalSetup), opens a run, rejects a
# patch with an override reason, asserts the acceptance rate drops, and wipes
# the data volume afterwards (teardown)
cd e2e && npm ci && npx playwright install chromium && npx playwright test
```

## CI

`.github/workflows/ci.yml` runs on every push and PR:

- **backend** — `mvn verify` on ubuntu-latest (Docker preinstalled for
  Testcontainers), Maven cache via `setup-java`
- **frontend** — `npm ci && tsc --noEmit && npm run lint && npm test`, npm cache
  via `setup-node`
- **e2e** — Playwright with Chromium; the suite boots the compose stack itself

## Monitoring

Prometheus scrapes the backend at `/actuator/prometheus` (JVM/HTTP metrics plus
the custom `agentops_patches_reviewed_total{decision=}` counter and
`agentops_run_ingest_seconds` timer).

The compose stack also scrapes the existing CopilotGuard and AgentDiff
exporters when configured — host/port come from env vars and the jobs are
optional (dropped when the host is unset, so the stack still starts without
them):

```bash
COPILOTGUARD_HOST=copilotguard.internal COPILOTGUARD_PORT=9190 \
AGENTDIFF_HOST=agentdiff.internal     AGENTDIFF_PORT=9200 \
docker compose -f infra/docker-compose.yml up
```

`infra/prometheus/rules.yml` defines
`AgentOpsAcceptanceRateTooLow`: fires when the share of accepted patches over
the trailing hour drops below 50% (5m `for`).

## Backend architecture

Layered design in `backend/src/main/java/com/agentops/console`:

| Package           | Responsibility                                                        |
| ----------------- | --------------------------------------------------------------------- |
| `domain/`         | JPA `@Entity` classes (never exposed over HTTP)                       |
| `repo/`           | Spring Data repositories                                              |
| `service/`        | Business rules (review workflow, atomic ingest, native-SQL metrics)   |
| `api/`            | `@RestController` endpoints                                          |
| `api/dto/request` | Request DTOs with Bean Validation (`@NotBlank`, `@Min`, …)            |
| `api/dto/response`| Response DTOs (entities are mapped before leaving the service layer)  |
| `api/error/`      | `@RestControllerAdvice` mapping errors to RFC 7807 `ProblemDetail`    |
