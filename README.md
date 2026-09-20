# AgentOps Console

Dashboard for tracking AI coding-agent runs: prompt variants, patches, costs, and
review verdicts.

```
┌─────────────┐     ┌──────────────────────┐     ┌──────────────┐
│  frontend   │     │       backend        │     │   postgres   │
│ React 18 +  │ ──► │ Spring Boot 3.3      │ ──► │  postgres:16 │
│ Vite/nginx  │ /api│ Java 21 + Flyway     │ JDBC│  Flyway V1+V2│
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
curl -s http://localhost:5173/api/dashboard/summary
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
| `review_verdict`  | Human/bot verdict on a patch; unique FK to `patch`; decision check (`ACCEPTED`/`REJECTED`) |

Indexes (each commented with the query it serves):

| Index                                    | Serves                                              |
| ---------------------------------------- | --------------------------------------------------- |
| `agent_run (started_at DESC)`            | dashboard recent-runs list — `GET /api/runs`        |
| `agent_run (prompt_variant_id, started_at)` | runs filtered by variant — `GET /api/runs?variantId=` |
| `patch (run_id)`                         | patches of a run — `GET /api/runs/{id}/patches`     |
| `review_verdict (decision, decided_at)`  | acceptance stats over time — `GET /api/dashboard/summary` |

### `V2__seed.sql`

Deterministic seed data so the dashboard is populated on first boot:

- 8 prompt variants with realistic templates (baseline → aggressive-refactor)
- 40 agent runs (34 succeeded, 4 failed, 2 running) spread over ~45 days
- 200 patches with genuine unified-diff text; `lines_added`/`lines_removed` match the diffs
- 140 review verdicts (~70% of patches); acceptance rates vary per variant (43% → 94%)

Timestamps are relative to `NOW()` so the data always looks fresh.

## API

| Endpoint                     | Description                                   |
| ---------------------------- | --------------------------------------------- |
| `GET /api/runs`              | Runs, newest first; `?variantId=` and `?status=` filters |
| `GET /api/runs/{id}`         | One run                                       |
| `GET /api/runs/{id}/patches` | Patches of a run, each with its verdict       |
| `GET /api/variants`          | Variants with acceptance stats                |
| `GET /api/dashboard/summary` | Totals: costs, tokens, verdicts, 14-day window |
| `GET /actuator/health`       | Health (liveness/readiness probes)            |
| `GET /actuator/prometheus`   | Metrics scraped by Prometheus                 |

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
# Backend — Testcontainers spins up postgres:16, verifies migrations + seed + indexes
cd backend && mvn test

# Frontend — Vitest + React Testing Library
cd frontend && npm test && npm run build
```
