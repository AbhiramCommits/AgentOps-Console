#!/usr/bin/env python3
"""Generates a deterministic ~500-run demo dataset for screenshots.

Emits SQL on stdout; pipe it into the compose Postgres:

    python3 scripts/generate_demo_sql.py \\
        | docker compose -f infra/docker-compose.yml exec -T postgres \\
            psql -U agentops -d agentops -v ON_ERROR_STOP=1
"""

import random
import sys
import uuid

rng = random.Random(42)
uuid_rng = random.Random(42)

TOOLS = ["agentops-codex", "agentops-claude-code", "agentops-cursor-agent"]
MODELS = ["claude-sonnet-4", "gpt-4o", "gpt-4.1-mini", "claude-opus-4"]
REPOS = ["acme/webapp", "acme/api-gateway", "acme/payments-service", "acme/design-system", "acme/infra-terraform"]
BRANCHES = ["main", "main", "main", "feat/checkout-v2", "feat/rate-limiter", "fix/oauth-refresh", "chore/deps-upgrade"]
FILES = [
    "src/services/checkout.ts", "src/types/orders.ts", "src/components/CheckoutButton.tsx",
    "src/main/java/com/acme/gateway/RateLimiter.java", "payments/charges.py", "payments/refunds.py",
    "infra/terraform/ecs.tf", "src/styles/theme.css", "config/gateway.json",
]
VARIANTS = [
    ("47bf29f5-b5b6-4be6-a1e6-1f3f961e7514", 0.42),
    ("d05feebe-e6a4-4749-b3e6-3c3f20b29cd9", 0.55),
    ("f52241c3-3dc2-4220-98bc-e15e68f485af", 0.63),
    ("2061075f-0569-4567-98cc-6646702b4578", 0.70),
    ("e9b82887-82ce-4b2f-8adc-6a73b9065b91", 0.78),
    ("d10fc0ae-f633-4ba5-a159-c59178707efa", 0.84),
    ("11923220-1fd9-44f3-a4bf-76a2dde79c19", 0.89),
    ("d715cb99-6dec-4001-804e-321b300792a0", 0.94),
]
REVIEWERS = ["alice", "bob", "charlie", "diana", "ci-review-bot", "security-bot"]
OVERRIDES = [
    "Bot flagged a flaky test as the cause; manually verified it passes in isolation.",
    "Hotfix approved manually despite the coverage drop.",
    "Manual override: the diff only touched generated files.",
]


def uuid4():
    return str(uuid.UUID(int=uuid_rng.getrandbits(128), version=4))


def diff_text(path):
    h1, h2 = f"{rng.getrandbits(32):08x}", f"{rng.getrandbits(32):08x}"
    line = rng.randint(8, 300)
    lines = [
        f"   const payload = buildPayload({rng.randint(1, 9)});",
        f"   const total = items.reduce((sum, item) => sum + item.price, 0);",
    ]
    adds = [
        f"+  if (response.status === 429 && attempt < {rng.choice([3, 5])}) {{",
        "+    return runWithRetry(items, attempt + 1);",
        "+  }",
    ]
    dels = [f"-  const fee = total * {rng.choice([0.02, 0.015, 0.03])};"]
    body = "".join(f"{p}{t}\n" for p, t in
                   [(" ", l) for l in lines] + [("-", d[1:]) for d in dels] + [("+", a[1:]) for a in adds])
    old_n = len(lines) + len(dels)
    new_n = len(lines) + len(adds)
    return (f"diff --git a/{path} b/{path}\nindex {h1}..{h2} 100644\n"
            f"--- a/{path}\n+++ b/{path}\n@@ -{line},{old_n} +{line},{new_n} @@\n{body}")


def out(sql):
    sys.stdout.write(sql + "\n")


out("-- AgentOps demo dataset: ~500 runs with patches and verdicts (generated).")
out("INSERT INTO agent_run (id, tool, repo, branch, model, prompt_variant_id, "
    "started_at, finished_at, total_cost_usd, total_tokens, status) VALUES")
run_rows = []
patch_rows = []
verdict_rows = []
for r in range(500):
    variant_id, accept_rate = VARIANTS[r % len(VARIANTS)]
    status = "RUNNING" if r < 25 else "FAILED" if r % 9 == 0 else "SUCCEEDED"
    started_h = r * 7.2 + rng.uniform(0, 5)
    n_patches = rng.randint(4, 7)
    run_id = uuid4()
    cost = 0.0
    tokens = 0
    for k in range(n_patches):
        patch_id = uuid4()
        path = FILES[rng.randrange(len(FILES))]
        adds = rng.randint(2, 9)
        dels = rng.randint(1, 4)
        latency = rng.randint(1500, 60000)
        p_cost = round(rng.uniform(0.15, 2.8), 6)
        cost += p_cost
        tokens += rng.randint(1500, 15000)
        created_h = max(0.1, started_h - (k + 1) * 0.12 - rng.uniform(0, 0.05))
        patch_rows.append(
            f"  ('{patch_id}', '{run_id}', '{path}', "
            f"$${diff_text(path)}$$, {adds}, {dels}, {latency}, {p_cost}, "
            f"NOW() - INTERVAL '{created_h:.2f} hours')")
        if r >= 25 and rng.random() < 0.72:
            decision = "ACCEPTED" if rng.random() < accept_rate else "REJECTED"
            reviewer = rng.choice(REVIEWERS)
            override = "NULL"
            if decision == "REJECTED" and rng.random() < 0.25:
                override = f"'{rng.choice(OVERRIDES)}'"
            decided_h = max(0.05, created_h - rng.uniform(0.5, 40))
            verdict_rows.append(
                f"  ('{uuid4()}', '{patch_id}', '{reviewer}', '{decision}', {override}, "
                f"NOW() - INTERVAL '{decided_h:.2f} hours')")
    finished_h = None if status == "RUNNING" else max(0.1, started_h - rng.uniform(1, 5))
    finished = "NULL" if finished_h is None else f"NOW() - INTERVAL '{finished_h:.2f} hours'"
    run_rows.append(
        f"  ('{run_id}', '{rng.choice(TOOLS)}', '{rng.choice(REPOS)}', '{rng.choice(BRANCHES)}', "
        f"'{rng.choice(MODELS)}', '{variant_id}', NOW() - INTERVAL '{started_h:.2f} hours', "
        f"{finished}, {round(cost, 6)}, {tokens + rng.randint(500, 4000)}, '{status}')")
out(",\n".join(run_rows) + ";")
out("")
out("INSERT INTO patch (id, run_id, file_path, diff_unified, lines_added, lines_removed, "
    "latency_ms, cost_usd, created_at) VALUES")
out(",\n".join(patch_rows) + ";")
out("")
out("INSERT INTO review_verdict (id, patch_id, reviewer, decision, override_reason, decided_at) VALUES")
out(",\n".join(verdict_rows) + ";")
