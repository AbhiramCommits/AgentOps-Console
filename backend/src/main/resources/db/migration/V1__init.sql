-- V1: AgentOps Console core schema
-- Prompt variants, agent runs, patches and review verdicts with real foreign keys.

CREATE TABLE prompt_variant (
    id          uuid PRIMARY KEY,
    name        text NOT NULL UNIQUE,
    template    text NOT NULL,
    description text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE agent_run (
    id                uuid PRIMARY KEY,
    tool              text NOT NULL,
    repo              text NOT NULL,
    branch            text NOT NULL,
    model             text NOT NULL,
    prompt_variant_id uuid NOT NULL REFERENCES prompt_variant (id),
    started_at        timestamptz NOT NULL,
    finished_at       timestamptz,
    total_cost_usd    numeric(10, 6),
    total_tokens      int,
    status            text NOT NULL DEFAULT 'RUNNING'
                      CONSTRAINT agent_run_status_check
                      CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
    CONSTRAINT agent_run_times_check CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE TABLE patch (
    id            uuid PRIMARY KEY,
    run_id        uuid NOT NULL REFERENCES agent_run (id) ON DELETE CASCADE,
    file_path     text NOT NULL,
    diff_unified  text NOT NULL,
    lines_added   int NOT NULL DEFAULT 0,
    lines_removed int NOT NULL DEFAULT 0,
    latency_ms    int NOT NULL,
    cost_usd      numeric(10, 6) NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE review_verdict (
    id              uuid PRIMARY KEY,
    patch_id        uuid NOT NULL UNIQUE REFERENCES patch (id) ON DELETE CASCADE,
    reviewer        text NOT NULL,
    decision        text NOT NULL
                    CONSTRAINT review_verdict_decision_check
                    CHECK (decision IN ('ACCEPTED', 'REJECTED')),
    override_reason text,
    decided_at      timestamptz NOT NULL
);

-- Serves: dashboard recent-runs list — GET /api/runs ordered by started_at DESC
CREATE INDEX idx_agent_run_started_at ON agent_run (started_at DESC);

-- Serves: runs filtered by variant — GET /api/runs?variantId=... ordered by started_at DESC
-- (also backs the agent_run -> prompt_variant foreign key lookups)
CREATE INDEX idx_agent_run_variant_started_at ON agent_run (prompt_variant_id, started_at);

-- Serves: patches of a single run — GET /api/runs/{id}/patches ordered by created_at
CREATE INDEX idx_patch_run_id ON patch (run_id);

-- Serves: acceptance stats over time — GET /api/dashboard/summary filtering by decision and decided_at
CREATE INDEX idx_review_verdict_decision_decided_at ON review_verdict (decision, decided_at);
