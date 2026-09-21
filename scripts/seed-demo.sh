#!/usr/bin/env bash
# Loads a larger demo dataset (~500 runs, ~3k patches, ~2k verdicts) into the
# compose Postgres so screenshots and demos have a busy dashboard.
# Idempotent-ish: appends to whatever is already seeded.
set -euo pipefail
cd "$(dirname "$0")/.."

# Boot the full stack so the backend applies the Flyway migrations before we
# load data (the compose Postgres has no schema until the backend starts).
docker compose -f infra/docker-compose.yml up -d --build >/dev/null

echo "Waiting for the backend (Flyway migrations)…"
for _ in $(seq 1 60); do
  if docker compose -f infra/docker-compose.yml exec -T backend \
      wget -q -O - http://localhost:8080/actuator/health 2>/dev/null | grep -q '"UP"'; then
    break
  fi
  sleep 5
done

python3 scripts/generate_demo_sql.py \
  | docker compose -f infra/docker-compose.yml exec -T postgres \
      psql -U agentops -d agentops -v ON_ERROR_STOP=1 -q

docker compose -f infra/docker-compose.yml exec -T postgres psql -U agentops -d agentops -t -A -c \
  "SELECT count(*) || ' runs, ' || (SELECT count(*) FROM patch) || ' patches, ' || (SELECT count(*) FROM review_verdict) || ' verdicts' FROM agent_run;"
