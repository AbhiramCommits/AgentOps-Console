-- V3: Review audit trail.
-- review_verdict keeps only the current state of a patch's review; every
-- change (initial review or amendment) is appended to review_audit instead
-- of overwriting history.

CREATE TABLE review_audit (
    id              uuid PRIMARY KEY,
    patch_id        uuid NOT NULL REFERENCES patch (id) ON DELETE CASCADE,
    reviewer        text NOT NULL,
    decision        text NOT NULL
                    CONSTRAINT review_audit_decision_check
                    CHECK (decision IN ('ACCEPTED', 'REJECTED')),
    override_reason text,
    action          text NOT NULL
                    CONSTRAINT review_audit_action_check
                    CHECK (action IN ('CREATED', 'AMENDED')),
    changed_at      timestamptz NOT NULL DEFAULT now()
);

-- Serves: per-patch review history — audit trail lookup ordered by changed_at
CREATE INDEX idx_review_audit_patch_changed_at ON review_audit (patch_id, changed_at);
