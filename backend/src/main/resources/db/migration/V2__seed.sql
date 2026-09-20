-- V2: Seed data for the AgentOps Console.
-- 8 prompt variants, 40 agent runs, 200 patches, 140 review verdicts (~70% of patches).
-- Timestamps are relative to migration time so the dashboard always looks fresh.

INSERT INTO prompt_variant (id, name, template, description, created_at) VALUES
  ('47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', 'baseline-v1', $tpl$You are an expert software engineer. Fix the issue described in the task.
Make the smallest change that satisfies the acceptance criteria.
Write or update tests where relevant.
Do not refactor unrelated code.$tpl$, 'Original production prompt used as the control for all experiments.', NOW() - INTERVAL '90 days'),
  ('d05feebe-e6a4-4749-b3e6-3c3f20b29cd9', 'spec-driven-v2', $tpl$You are an expert software engineer working in a large monorepo.
REQUIREMENTS:
- Resolve the issue described in the task.
- Preserve backwards compatibility for all public APIs.
CONSTRAINTS:
- Do not add new dependencies.
- Keep the diff under 200 lines.
Then implement the fix and run the relevant test suite.$tpl$, 'Adds an explicit requirements and constraints section before instructions.', NOW() - INTERVAL '82 days'),
  ('f52241c3-3dc2-4220-98bc-e15e68f485af', 'chain-of-thought', $tpl$You are a senior engineer. Before writing any code, think step by step:
1. Restate the problem in your own words.
2. List the files likely involved.
3. Identify the root cause.
4. Describe your fix and why it is correct.
5. Only then, produce the patch.
Be explicit about any assumptions you make.$tpl$, 'Instructs the model to reason step by step before emitting a patch.', NOW() - INTERVAL '74 days'),
  ('2061075f-0569-4567-98cc-6646702b4578', 'test-first', $tpl$You are a test-driven engineer.
1. Write a failing test that reproduces the issue.
2. Confirm it fails for the right reason.
3. Implement the minimal fix to make it pass.
4. Include both test and implementation in the same patch.
Do not skip the test step.$tpl$, 'Requires a failing test to be added before the implementation change.', NOW() - INTERVAL '66 days'),
  ('e9b82887-82ce-4b2f-8adc-6a73b9065b91', 'minimal-diff', $tpl$You are a careful engineer doing a hotfix on a stable branch.
The smaller the diff, the better. Prefer editing a single file.
Do not reformat, rename, or reorganise anything you are not asked to change.
Every line you touch must be justified in a short comment on the patch.$tpl$, 'Strongly penalises large diffs and unrelated changes.', NOW() - INTERVAL '58 days'),
  ('d10fc0ae-f633-4ba5-a159-c59178707efa', 'doc-aware', $tpl$You are an engineer joining this codebase for the first time.
Before editing, read README.md, docs/, and any ADRs that touch the affected module.
Follow the documented conventions exactly, even if you disagree with them.
Then implement the requested change.$tpl$, 'Asks the model to read repository docs and ADRs before editing.', NOW() - INTERVAL '50 days'),
  ('11923220-1fd9-44f3-a4bf-76a2dde79c19', 'self-review', $tpl$You are an engineer with a strict reviewer persona available.
1. Produce an initial patch for the task.
2. Review it as if you were a sceptical maintainer: look for edge cases, races, and style violations.
3. Fix any issues you find.
4. Output the improved patch and a short list of the issues you fixed.$tpl$, 'Model produces a patch, then critiques it as a strict reviewer and improves it.', NOW() - INTERVAL '42 days'),
  ('d715cb99-6dec-4001-804e-321b300792a0', 'aggressive-refactor', $tpl$You are a senior engineer improving a legacy module.
Fix the issue, and while you are in the file, feel free to refactor nearby code
where it improves clarity or removes duplication.
Keep behaviour identical. Update tests to match the new structure.$tpl$, 'Encourages refactoring surrounding code where it improves clarity.', NOW() - INTERVAL '34 days');

INSERT INTO agent_run (id, tool, repo, branch, model, prompt_variant_id, started_at, finished_at, total_cost_usd, total_tokens, status) VALUES
  ('5b1eb014-7ff8-4ec2-914a-21ae85ef6be7', 'agentops-codex', 'acme/webapp', 'main', 'claude-sonnet-4', '47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', NOW() - INTERVAL '18 hours 36 minutes', NULL, 4.503868, 26815, 'RUNNING'),
  ('13b083d7-9ad7-42da-863d-63598812983f', 'agentops-claude-code', 'acme/api-gateway', 'main', 'gpt-4o', 'd05feebe-e6a4-4749-b3e6-3c3f20b29cd9', NOW() - INTERVAL '47 hours 45 minutes', NULL, 2.186359, 26681, 'RUNNING'),
  ('6f690561-4558-4f60-bb4e-40520213bd25', 'agentops-cursor-agent', 'acme/payments-service', 'main', 'gpt-4.1-mini', 'f52241c3-3dc2-4220-98bc-e15e68f485af', NOW() - INTERVAL '69 hours 15 minutes', NOW() - INTERVAL '67 hours 59 minutes', 6.538565, 57446, 'SUCCEEDED'),
  ('2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'agentops-codex', 'acme/design-system', 'feat/checkout-v2', 'claude-opus-4', '2061075f-0569-4567-98cc-6646702b4578', NOW() - INTERVAL '96 hours 36 minutes', NOW() - INTERVAL '95 hours 34 minutes', 7.154201, 58911, 'SUCCEEDED'),
  ('5dbc616a-6e71-40f6-9aae-a09115ac0968', 'agentops-claude-code', 'acme/infra-terraform', 'feat/rate-limiter', 'claude-sonnet-4', 'e9b82887-82ce-4b2f-8adc-6a73b9065b91', NOW() - INTERVAL '116 hours 30 minutes', NOW() - INTERVAL '115 hours 23 minutes', 7.51593, 45269, 'SUCCEEDED'),
  ('038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'agentops-cursor-agent', 'acme/webapp', 'fix/oauth-refresh', 'gpt-4o', 'd10fc0ae-f633-4ba5-a159-c59178707efa', NOW() - INTERVAL '146 hours 43 minutes', NOW() - INTERVAL '142 hours 58 minutes', 5.391127, 56268, 'FAILED'),
  ('1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'agentops-codex', 'acme/api-gateway', 'chore/deps-upgrade', 'gpt-4.1-mini', '11923220-1fd9-44f3-a4bf-76a2dde79c19', NOW() - INTERVAL '176 hours 4 minutes', NOW() - INTERVAL '175 hours', 5.933156, 43031, 'SUCCEEDED'),
  ('c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'agentops-claude-code', 'acme/payments-service', 'main', 'claude-opus-4', 'd715cb99-6dec-4001-804e-321b300792a0', NOW() - INTERVAL '202 hours 21 minutes', NOW() - INTERVAL '201 hours 5 minutes', 8.87822, 38983, 'SUCCEEDED'),
  ('af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'agentops-cursor-agent', 'acme/design-system', 'main', 'claude-sonnet-4', '47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', NOW() - INTERVAL '222 hours 39 minutes', NOW() - INTERVAL '221 hours 33 minutes', 5.946017, 38089, 'SUCCEEDED'),
  ('f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'agentops-codex', 'acme/infra-terraform', 'main', 'gpt-4o', 'd05feebe-e6a4-4749-b3e6-3c3f20b29cd9', NOW() - INTERVAL '258 hours 16 minutes', NOW() - INTERVAL '257 hours 14 minutes', 5.455709, 56539, 'SUCCEEDED'),
  ('2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'agentops-claude-code', 'acme/webapp', 'feat/checkout-v2', 'gpt-4.1-mini', 'f52241c3-3dc2-4220-98bc-e15e68f485af', NOW() - INTERVAL '286 hours 33 minutes', NOW() - INTERVAL '285 hours 29 minutes', 7.359487, 45914, 'SUCCEEDED'),
  ('8301eda0-fe3f-46b8-b525-872fa8a89cea', 'agentops-cursor-agent', 'acme/api-gateway', 'feat/rate-limiter', 'claude-opus-4', '2061075f-0569-4567-98cc-6646702b4578', NOW() - INTERVAL '308 hours 9 minutes', NOW() - INTERVAL '306 hours 55 minutes', 4.045622, 52376, 'SUCCEEDED'),
  ('69864d1d-c096-41e0-9870-ba359529be3a', 'agentops-codex', 'acme/payments-service', 'fix/oauth-refresh', 'claude-sonnet-4', 'e9b82887-82ce-4b2f-8adc-6a73b9065b91', NOW() - INTERVAL '329 hours 46 minutes', NOW() - INTERVAL '326 hours 5 minutes', 9.13837, 52120, 'FAILED'),
  ('3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'agentops-claude-code', 'acme/design-system', 'chore/deps-upgrade', 'gpt-4o', 'd10fc0ae-f633-4ba5-a159-c59178707efa', NOW() - INTERVAL '359 hours 14 minutes', NOW() - INTERVAL '358 hours 13 minutes', 9.554698, 47125, 'SUCCEEDED'),
  ('7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'agentops-cursor-agent', 'acme/infra-terraform', 'main', 'gpt-4.1-mini', '11923220-1fd9-44f3-a4bf-76a2dde79c19', NOW() - INTERVAL '396 hours 4 minutes', NOW() - INTERVAL '394 hours 47 minutes', 8.571735, 45083, 'SUCCEEDED'),
  ('1d877834-1cdd-4436-b500-46040199d8ca', 'agentops-codex', 'acme/webapp', 'main', 'claude-opus-4', 'd715cb99-6dec-4001-804e-321b300792a0', NOW() - INTERVAL '419 hours 43 minutes', NOW() - INTERVAL '418 hours 26 minutes', 10.37826, 52249, 'SUCCEEDED'),
  ('55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'agentops-claude-code', 'acme/api-gateway', 'main', 'claude-sonnet-4', '47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', NOW() - INTERVAL '436 hours 51 minutes', NOW() - INTERVAL '435 hours 49 minutes', 7.591893, 52063, 'SUCCEEDED'),
  ('170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'agentops-cursor-agent', 'acme/payments-service', 'feat/checkout-v2', 'gpt-4o', 'd05feebe-e6a4-4749-b3e6-3c3f20b29cd9', NOW() - INTERVAL '464 hours 16 minutes', NOW() - INTERVAL '462 hours 54 minutes', 6.860573, 44156, 'SUCCEEDED'),
  ('c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'agentops-codex', 'acme/design-system', 'feat/rate-limiter', 'gpt-4.1-mini', 'f52241c3-3dc2-4220-98bc-e15e68f485af', NOW() - INTERVAL '490 hours 5 minutes', NOW() - INTERVAL '489 hours 4 minutes', 7.931279, 44739, 'SUCCEEDED'),
  ('18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'agentops-claude-code', 'acme/infra-terraform', 'fix/oauth-refresh', 'claude-opus-4', '2061075f-0569-4567-98cc-6646702b4578', NOW() - INTERVAL '517 hours 12 minutes', NOW() - INTERVAL '515 hours 24 minutes', 7.659808, 50443, 'FAILED'),
  ('0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'agentops-cursor-agent', 'acme/webapp', 'chore/deps-upgrade', 'claude-sonnet-4', 'e9b82887-82ce-4b2f-8adc-6a73b9065b91', NOW() - INTERVAL '559 hours 39 minutes', NOW() - INTERVAL '558 hours 32 minutes', 7.835475, 36846, 'SUCCEEDED'),
  ('f2e4d414-9e52-4ddd-954a-504fa07440ae', 'agentops-codex', 'acme/api-gateway', 'main', 'gpt-4o', 'd10fc0ae-f633-4ba5-a159-c59178707efa', NOW() - INTERVAL '580 hours 4 minutes', NOW() - INTERVAL '579 hours 3 minutes', 10.806363, 41224, 'SUCCEEDED'),
  ('c7003914-3f4b-4acb-bde5-d1f22415bd88', 'agentops-claude-code', 'acme/payments-service', 'main', 'gpt-4.1-mini', '11923220-1fd9-44f3-a4bf-76a2dde79c19', NOW() - INTERVAL '606 hours 41 minutes', NOW() - INTERVAL '605 hours 36 minutes', 7.564694, 41683, 'SUCCEEDED'),
  ('729a8b08-e3f4-4948-9091-d69a32a68afa', 'agentops-cursor-agent', 'acme/design-system', 'main', 'claude-opus-4', 'd715cb99-6dec-4001-804e-321b300792a0', NOW() - INTERVAL '638 hours 21 minutes', NOW() - INTERVAL '637 hours 6 minutes', 4.626443, 34029, 'SUCCEEDED'),
  ('b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'agentops-codex', 'acme/infra-terraform', 'feat/checkout-v2', 'claude-sonnet-4', '47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', NOW() - INTERVAL '654 hours 24 minutes', NOW() - INTERVAL '653 hours 11 minutes', 8.924819, 53108, 'SUCCEEDED'),
  ('73982e98-db5b-4ece-8b79-7937293721e7', 'agentops-claude-code', 'acme/webapp', 'feat/rate-limiter', 'gpt-4o', 'd05feebe-e6a4-4749-b3e6-3c3f20b29cd9', NOW() - INTERVAL '687 hours 7 minutes', NOW() - INTERVAL '685 hours 56 minutes', 4.444372, 38946, 'SUCCEEDED'),
  ('afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'agentops-cursor-agent', 'acme/api-gateway', 'fix/oauth-refresh', 'gpt-4.1-mini', 'f52241c3-3dc2-4220-98bc-e15e68f485af', NOW() - INTERVAL '719 hours 16 minutes', NOW() - INTERVAL '717 hours 39 minutes', 9.5052, 28120, 'FAILED'),
  ('7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'agentops-codex', 'acme/payments-service', 'chore/deps-upgrade', 'claude-opus-4', '2061075f-0569-4567-98cc-6646702b4578', NOW() - INTERVAL '744 hours 1 minute', NOW() - INTERVAL '742 hours 47 minutes', 6.441067, 41240, 'SUCCEEDED'),
  ('52b8bb22-657b-4a95-ac24-4de85c91b646', 'agentops-claude-code', 'acme/design-system', 'main', 'claude-sonnet-4', 'e9b82887-82ce-4b2f-8adc-6a73b9065b91', NOW() - INTERVAL '773 hours 38 minutes', NOW() - INTERVAL '772 hours 32 minutes', 8.003765, 43852, 'SUCCEEDED'),
  ('21164d90-e913-464a-b931-b1d99c97deb9', 'agentops-cursor-agent', 'acme/infra-terraform', 'main', 'gpt-4o', 'd10fc0ae-f633-4ba5-a159-c59178707efa', NOW() - INTERVAL '801 hours 42 minutes', NOW() - INTERVAL '800 hours 28 minutes', 5.131745, 34658, 'SUCCEEDED'),
  ('da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'agentops-codex', 'acme/webapp', 'main', 'gpt-4.1-mini', '11923220-1fd9-44f3-a4bf-76a2dde79c19', NOW() - INTERVAL '816 hours 14 minutes', NOW() - INTERVAL '814 hours 51 minutes', 8.711138, 54558, 'SUCCEEDED'),
  ('2744bc27-d26e-421b-85c3-c819150ae6a7', 'agentops-claude-code', 'acme/api-gateway', 'feat/checkout-v2', 'claude-opus-4', 'd715cb99-6dec-4001-804e-321b300792a0', NOW() - INTERVAL '847 hours 45 minutes', NOW() - INTERVAL '846 hours 31 minutes', 8.66404, 43403, 'SUCCEEDED'),
  ('fe2063c6-0670-471d-bbac-b66dc86c663b', 'agentops-cursor-agent', 'acme/payments-service', 'feat/rate-limiter', 'claude-sonnet-4', '47bf29f5-b5b6-4be6-a1e6-1f3f961e7514', NOW() - INTERVAL '870 hours 19 minutes', NOW() - INTERVAL '869 hours 7 minutes', 7.02611, 40937, 'SUCCEEDED'),
  ('377a70cf-5d3a-4f30-a81d-86e6edb47783', 'agentops-codex', 'acme/design-system', 'fix/oauth-refresh', 'gpt-4o', 'd05feebe-e6a4-4749-b3e6-3c3f20b29cd9', NOW() - INTERVAL '891 hours 22 minutes', NOW() - INTERVAL '890 hours 19 minutes', 4.424433, 40753, 'SUCCEEDED'),
  ('7b0c5574-32b5-407e-a126-5d0ec1731263', 'agentops-claude-code', 'acme/infra-terraform', 'chore/deps-upgrade', 'gpt-4.1-mini', 'f52241c3-3dc2-4220-98bc-e15e68f485af', NOW() - INTERVAL '933 hours 22 minutes', NOW() - INTERVAL '932 hours 16 minutes', 7.350868, 44361, 'SUCCEEDED'),
  ('648bea9d-3d3a-4c77-83d6-2919fe753729', 'agentops-cursor-agent', 'acme/webapp', 'main', 'claude-opus-4', '2061075f-0569-4567-98cc-6646702b4578', NOW() - INTERVAL '959 hours 11 minutes', NOW() - INTERVAL '957 hours 58 minutes', 8.29709, 43829, 'SUCCEEDED'),
  ('0c2adf49-205f-4668-9e8c-17547f20fb8b', 'agentops-codex', 'acme/api-gateway', 'main', 'claude-sonnet-4', 'e9b82887-82ce-4b2f-8adc-6a73b9065b91', NOW() - INTERVAL '991 hours 16 minutes', NOW() - INTERVAL '989 hours 55 minutes', 10.514441, 62125, 'SUCCEEDED'),
  ('2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'agentops-claude-code', 'acme/payments-service', 'main', 'gpt-4o', 'd10fc0ae-f633-4ba5-a159-c59178707efa', NOW() - INTERVAL '1017 hours 11 minutes', NOW() - INTERVAL '1016 hours 4 minutes', 6.361346, 30985, 'SUCCEEDED'),
  ('f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'agentops-cursor-agent', 'acme/design-system', 'feat/checkout-v2', 'gpt-4.1-mini', '11923220-1fd9-44f3-a4bf-76a2dde79c19', NOW() - INTERVAL '1044 hours 11 minutes', NOW() - INTERVAL '1043 hours 11 minutes', 7.755797, 40762, 'SUCCEEDED'),
  ('3522db69-2300-43ba-9326-aab1bf653ee8', 'agentops-codex', 'acme/infra-terraform', 'feat/rate-limiter', 'claude-opus-4', 'd715cb99-6dec-4001-804e-321b300792a0', NOW() - INTERVAL '1055 hours 4 minutes', NOW() - INTERVAL '1053 hours 56 minutes', 9.936565, 58260, 'SUCCEEDED');

INSERT INTO patch (id, run_id, file_path, diff_unified, lines_added, lines_removed, latency_ms, cost_usd, created_at) VALUES
  ('ec08ecea-7e45-430c-a0dc-71042f5dfa3c', '5b1eb014-7ff8-4ec2-914a-21ae85ef6be7', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index d05feebe..68f485af 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -240,13 +240,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 30915, 1.01885, NOW() - INTERVAL '18 hours 25 minutes'),
  ('385f5c1f-e615-4daf-8f60-e2147a4f572b', '5b1eb014-7ff8-4ec2-914a-21ae85ef6be7', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index 4adc6a73..82ce1b2f 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -190,11 +190,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 55719, 2.389378, NOW() - INTERVAL '18 hours 16 minutes'),
  ('cbc20535-a761-41bf-b198-7b8152affc73', '5b1eb014-7ff8-4ec2-914a-21ae85ef6be7', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index d715cb99..2f5dfa3c 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -43,11 +43,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v1/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 5) {
+    await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 33511, 1.09564, NOW() - INTERVAL '18 hours 4 minutes'),
  ('6b3655ba-8c23-42ec-ba74-ee2a778120d3', '13b083d7-9ad7-42da-863d-63598812983f', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index 6b3655ba..9ebe8070 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -15,8 +15,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 30000,
+  "timeoutMs": 20000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 11906, 0.704866, NOW() - INTERVAL '47 hours 31 minutes'),
  ('25ea09d0-08c4-465b-b785-e47d9ebe8070', '13b083d7-9ad7-42da-863d-63598812983f', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index 44934525..2e1e22cd 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -99,7 +99,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 21490, 0.651278, NOW() - INTERVAL '47 hours 25 minutes'),
  ('ad209018-905c-4a8f-b197-73885b6266e5', '13b083d7-9ad7-42da-863d-63598812983f', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index fa476c53..85b88bb8 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -25,5 +25,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(15)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 48236, 0.830215, NOW() - INTERVAL '47 hours 17 minutes'),
  ('2e1e22cd-4493-4525-8f16-6f1cac99d6b2', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 8dec5d5c..62511e1b 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -123,4 +123,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 44062, 0.888446, NOW() - INTERVAL '69 hours 4 minutes'),
  ('30740151-4b5a-434e-b84f-b54b31daacaf', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index cf93e3ec..104a8209 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -196,6 +196,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 49355, 0.913643, NOW() - INTERVAL '68 hours 54 minutes'),
  ('dfad59cd-15c9-4d30-bf2d-1ac1aeaf35e2', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 2f1159e6..7f357e68 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -132,4 +132,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 7313, 0.92796, NOW() - INTERVAL '68 hours 48 minutes'),
  ('85b88bb8-fa47-4c53-a87f-3e7e382fcfda', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index d89f29a2..46757041 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -26,6 +26,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 12130, 2.214816, NOW() - INTERVAL '68 hours 36 minutes'),
  ('b1558b38-b3d4-48e8-8922-ff3444c8780c', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 1aaea091..6e7180f6 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -36,6 +36,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 29910, 1.066097, NOW() - INTERVAL '68 hours 26 minutes'),
  ('7fe29ca0-12fe-49ea-aa93-0be1e58bf09b', '6f690561-4558-4f60-bb4e-40520213bd25', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 8d8f0e3f..476f3210 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -64,4 +64,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 19267, 0.527603, NOW() - INTERVAL '68 hours 16 minutes'),
  ('922ca333-15bb-4f00-ac25-e4a972ddd9ad', '2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index b133c49b..9cda972b 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -196,13 +196,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 5928, 0.959295, NOW() - INTERVAL '96 hours 24 minutes'),
  ('62511e1b-8dec-4d5c-b17d-6f9caf58395d', '2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 15be1337..9c503b84 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -8,5 +8,5 @@
 :root {
-  --space-md: 8px;
+  --space-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 23868, 0.870619, NOW() - INTERVAL '96 hours 14 minutes'),
  ('91d68fc0-a386-4295-b770-30554af16b40', '2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index a73f737b..1b979a6c 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -8,5 +8,5 @@
 :root {
-  --space-md: 16px;
+  --space-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 30979, 1.669108, NOW() - INTERVAL '96 hours 7 minutes'),
  ('cf93e3ec-b5a2-4cc1-b972-698834064891', '2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 86556531..a625897d 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -35,13 +35,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 5656, 1.47723, NOW() - INTERVAL '95 hours 55 minutes'),
  ('b8339f3d-bb43-422e-8d9b-c711104a8209', '2b4b80b6-c7da-4aba-a4f0-a04d0654d8df', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 31901cd6..de14b04b 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -22,5 +22,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 14914, 2.177949, NOW() - INTERVAL '95 hours 47 minutes'),
  ('4f1f8059-7f35-4e68-af11-59e67a884223', '5dbc616a-6e71-40f6-9aae-a09115ac0968', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index f602f2f8..707fb018 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -31,6 +31,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 25990, 1.764357, NOW() - INTERVAL '116 hours 21 minutes'),
  ('4d4d5404-9de6-4649-93f9-8f1c70f5c12d', '5dbc616a-6e71-40f6-9aae-a09115ac0968', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index da09ddc1..344efdd1 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -37,6 +37,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 54722, 1.371799, NOW() - INTERVAL '116 hours 8 minutes'),
  ('46757041-d89f-49a2-8bec-48747c77207b', '5dbc616a-6e71-40f6-9aae-a09115ac0968', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 2c8d6e21..f135159e 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -34,6 +34,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 22430, 1.876091, NOW() - INTERVAL '116 hours 3 minutes'),
  ('c9ce0528-26ca-4b76-a1c4-f161d740d572', '5dbc616a-6e71-40f6-9aae-a09115ac0968', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index eac74eab..ce3793da 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -65,6 +65,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 21922, 0.987396, NOW() - INTERVAL '115 hours 52 minutes'),
  ('cd41e8ec-df9b-4f0a-8d62-8c709f8df148', '5dbc616a-6e71-40f6-9aae-a09115ac0968', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 34fd3037..7006796f 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -42,6 +42,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 22080, 1.516287, NOW() - INTERVAL '115 hours 43 minutes'),
  ('15678dd9-f181-4b08-ac3e-5cbb4faa5535', '038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index b85c0b94..2eb5f6ec 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -101,11 +101,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 24552, 0.534612, NOW() - INTERVAL '146 hours 29 minutes'),
  ('eb07bdcf-15a9-4104-9c50-9b25854e0ace', '038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index fa1f3d71..643d29a3 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -20,5 +20,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 9981, 1.046328, NOW() - INTERVAL '146 hours 24 minutes'),
  ('8d8f0e3f-36af-4244-b88c-4d27f9c1621a', '038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index 8a8fff0b..47565a3c 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -259,13 +259,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 12391, 1.014459, NOW() - INTERVAL '146 hours 14 minutes'),
  ('deb961b6-74f6-441f-a4c5-71e6476f3210', '038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index aba53aa3..18e3eec8 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -124,13 +124,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 10423, 0.254109, NOW() - INTERVAL '146 hours 2 minutes'),
  ('f1ec47a8-5e1f-44ea-9360-62ba42ab0208', '038b258e-eaf0-4655-adf1-e8e3ee30cb7f', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index f65d309f..8fab0aca 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -254,11 +254,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v1/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 3) {
+    await new Promise((resolve) => setTimeout(resolve, 250 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 51233, 2.541619, NOW() - INTERVAL '145 hours 55 minutes'),
  ('3d2e0ce1-d7e5-4558-af69-902ec8b4a4b0', '1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index 21df5284..da5df14d 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -49,7 +49,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 39099, 0.472088, NOW() - INTERVAL '175 hours 55 minutes'),
  ('0fdff30b-a25a-4cfb-bb6f-c7d8543457fc', '1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 137f392b..314df77d 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -119,5 +119,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(1)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 11065, 2.40863, NOW() - INTERVAL '175 hours 41 minutes'),
  ('bada54ec-036a-47c2-8f2d-e3687cb6a4e6', '1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index 3283314e..e6a32a70 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -7,8 +7,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 45000,
+  "timeoutMs": 20000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 24315, 0.48605, NOW() - INTERVAL '175 hours 32 minutes'),
  ('ef8f7aa1-5270-4763-9cda-972bb133c49b', '1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 8179896f..24259746 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -2,6 +2,7 @@
 ALTER TABLE webhooks
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_webhooks_processed_at ON webhooks (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_webhooks_processed_at;
--- ALTER TABLE webhooks DROP COLUMN processed_at;
$diff$, 4, 3, 51385, 1.964564, NOW() - INTERVAL '175 hours 24 minutes'),
  ('a596ef83-13d0-4bc7-abbc-071a0e9031ff', '1536a35a-1424-4aeb-b61d-e20b5f875ad9', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index e65aa41b..3257115b 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -157,7 +157,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 38702, 0.601824, NOW() - INTERVAL '175 hours 15 minutes'),
  ('15be1337-8b83-47da-ba11-e4cf0430d39e', 'c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index c3453b43..5a99cdb5 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -78,4 +78,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 36533, 2.268067, NOW() - INTERVAL '202 hours 9 minutes'),
  ('54a49233-39a0-4d82-890e-a2e29c503b84', 'c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 4669c2e0..c856fc42 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -72,4 +72,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 50397, 0.801588, NOW() - INTERVAL '202 hours 1 minute'),
  ('155f1eb6-63bf-48c3-be24-0b3156859e95', 'c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 18a6ac6f..805daa5a 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -22,4 +22,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 33168, 2.596902, NOW() - INTERVAL '201 hours 53 minutes'),
  ('d14d1d49-be37-43c3-b125-601336a9a411', 'c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index e9924c63..82de95bf 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -106,6 +106,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 2576, 1.932179, NOW() - INTERVAL '201 hours 43 minutes'),
  ('9d8685d4-1b97-4a6c-a73f-737b41d462c0', 'c07eadce-f075-4765-b06b-4b3f69f1ab3e', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 9da7ea58..928747ce 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -88,4 +88,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 29166, 1.279484, NOW() - INTERVAL '201 hours 32 minutes'),
  ('1999ecb8-057d-48c3-b13f-ee619995d5ac', 'af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 016cd551..a07440ae 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -108,13 +108,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 22701, 2.19626, NOW() - INTERVAL '222 hours 24 minutes'),
  ('c5ccc136-893a-48c1-a625-897d86556531', 'af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 3551fe3c..9ccb76a2 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -180,13 +180,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 43415, 0.754705, NOW() - INTERVAL '222 hours 15 minutes'),
  ('4ab83e77-868a-43af-b375-6d680d80344f', 'af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 5442788a..98108574 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -79,13 +79,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 11437, 0.2343, NOW() - INTERVAL '222 hours 6 minutes'),
  ('9c13a804-e3a6-4c1f-8e42-328da673c89e', 'af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 2682d2df..54e9c95b 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -16,5 +16,5 @@
 :root {
-  --radius-md: 8px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 31680, 1.017783, NOW() - INTERVAL '222 hours 1 minute'),
  ('de14b04b-3190-4cd6-9ca9-b3adb6cea86f', 'af48b788-31aa-4b4c-bdb0-6d8ed35a73a6', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 8a4ee31f..0fd20269 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -48,13 +48,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 38949, 1.742969, NOW() - INTERVAL '221 hours 52 minutes'),
  ('dcee3c89-a076-405e-bed0-751932bd87ac', 'f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 0b29d105..1a34c849 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -49,6 +49,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 12696, 0.456282, NOW() - INTERVAL '258 hours 4 minutes'),
  ('f5daf044-5413-4f04-90c7-b503976d6a61', 'f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index c86b5175..3a1a5388 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -44,6 +44,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 12623, 1.235754, NOW() - INTERVAL '257 hours 55 minutes'),
  ('18d1d52b-dd94-4d87-8796-1f5640996266', 'f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 454427bf..79e64706 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -10,6 +10,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 18078, 0.732042, NOW() - INTERVAL '257 hours 43 minutes'),
  ('4afa3b5d-34c9-49db-89c8-4f70c7a5789b', 'f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 93bda9c2..0944df40 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -40,6 +40,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 31085, 1.046841, NOW() - INTERVAL '257 hours 38 minutes'),
  ('821eea03-9825-464d-bbd0-e98edea0c25d', 'f602f2f8-0ffe-461d-a4c9-adcdeae14227', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 2356c845..42ee3e49 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -72,6 +72,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 42738, 1.98479, NOW() - INTERVAL '257 hours 29 minutes'),
  ('5cee4bfe-5c10-4414-a799-f3e4707fb018', '2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index 5c030aad..7c44a681 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -196,13 +196,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 51320, 2.116346, NOW() - INTERVAL '286 hours 18 minutes'),
  ('4077da39-3ddd-4f0c-99ae-674a9ebf0526', '2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 4d65e40b..010189c5 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -27,13 +27,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 17645, 1.533894, NOW() - INTERVAL '286 hours 9 minutes'),
  ('344efdd1-da09-4dc1-8f85-386209e8fbd6', '2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index eca39a4a..85b507de 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -73,13 +73,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 25897, 1.923225, NOW() - INTERVAL '286 hours'),
  ('1c180a04-cd2a-43a2-b80f-5e117e131848', '2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 7a741350..4b176c98 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -187,13 +187,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 15530, 1.401372, NOW() - INTERVAL '285 hours 56 minutes'),
  ('3a0cf435-9b3f-47eb-912b-590f82f28d45', '2c8d6e21-456b-44e6-920b-78ad6e321fe8', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index 34ca4019..b108a2fa 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -6,8 +6,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 60000,
+  "timeoutMs": 20000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 29013, 0.38465, NOW() - INTERVAL '285 hours 42 minutes'),
  ('4f06c137-68c3-4e9a-b36b-d157f135159e', '8301eda0-fe3f-46b8-b525-872fa8a89cea', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 6b8f1c10..2cef5f55 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -62,5 +62,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/inventory")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(1)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 38279, 0.741316, NOW() - INTERVAL '307 hours 54 minutes'),
  ('57dbfbb0-bc18-4936-9c67-33e259cfb90b', '8301eda0-fe3f-46b8-b525-872fa8a89cea', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 5bb46a32..1757c963 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -6,6 +6,7 @@
 ALTER TABLE webhooks
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_webhooks_processed_at ON webhooks (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_webhooks_processed_at;
--- ALTER TABLE webhooks DROP COLUMN processed_at;
$diff$, 4, 3, 41407, 0.377465, NOW() - INTERVAL '307 hours 45 minutes'),
  ('739e0025-eb04-4c56-b89f-f8cada056218', '8301eda0-fe3f-46b8-b525-872fa8a89cea', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index 626b8ab4..a3b9274a 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -111,7 +111,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 19291, 0.44998, NOW() - INTERVAL '307 hours 40 minutes'),
  ('556914f5-ce37-43da-aac7-4eab28822c17', '8301eda0-fe3f-46b8-b525-872fa8a89cea', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index d26e521b..2744bc27 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -89,7 +89,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 47316, 1.246959, NOW() - INTERVAL '307 hours 28 minutes'),
  ('5c7a5069-4d0a-4b94-9a8b-ecceaa0dfccc', '8301eda0-fe3f-46b8-b525-872fa8a89cea', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index e64ca982..94cac93c 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -36,5 +36,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v2/products")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 43244, 1.229902, NOW() - INTERVAL '307 hours 19 minutes'),
  ('3d79f098-4bfe-4106-8a2a-62839159880b', '69864d1d-c096-41e0-9870-ba359529be3a', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 26edf2fa..9f06ce5c 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -42,6 +42,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 4466, 2.412076, NOW() - INTERVAL '329 hours 36 minutes'),
  ('6032395c-839f-42a6-b4fd-3b8b8ca11508', '69864d1d-c096-41e0-9870-ba359529be3a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index edb47783..e81d86e6 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -80,4 +80,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 16118, 1.061315, NOW() - INTERVAL '329 hours 24 minutes'),
  ('49446e41-8d5b-471b-b006-796f34fd3037', '69864d1d-c096-41e0-9870-ba359529be3a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 433ed4e8..1cc95961 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -40,4 +40,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 48202, 2.321181, NOW() - INTERVAL '329 hours 18 minutes'),
  ('0d7f6322-c108-4705-b8a9-4ea04da8f97b', '69864d1d-c096-41e0-9870-ba359529be3a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index aa08065c..9d6130c0 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -94,4 +94,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 10686, 1.419682, NOW() - INTERVAL '329 hours 8 minutes'),
  ('74412722-093b-4e40-b1e5-9b11738adafa', '69864d1d-c096-41e0-9870-ba359529be3a', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 482414d3..eccf26db 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -101,6 +101,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 38879, 1.924116, NOW() - INTERVAL '329 hours'),
  ('2791fb05-f51e-40de-b50f-5c9abd67cb0b', '3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index ebaac52f..69780eed 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -30,5 +30,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 38811, 2.331652, NOW() - INTERVAL '359 hours 3 minutes'),
  ('258341c0-2eb5-46ec-b85c-0b9460c40af1', '3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index f5a5c0a4..769ce50f 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -121,13 +121,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 34744, 2.394503, NOW() - INTERVAL '358 hours 55 minutes'),
  ('19fa1cac-314c-4b44-9750-8bd3dc108ae3', '3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 027a2d91..490eb78d 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -259,13 +259,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 56090, 1.949441, NOW() - INTERVAL '358 hours 44 minutes'),
  ('8859c240-4418-4321-8a12-d58cc6ccefeb', '3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index e5bdcd21..c01f013e 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -40,5 +40,5 @@
 :root {
-  --space-lg: 12px;
+  --space-lg: 12px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 22527, 2.422541, NOW() - INTERVAL '358 hours 37 minutes'),
  ('643d29a3-fa1f-4d71-9a54-85be91ab1de9', '3c5e471b-1e65-4a9b-9030-f2e95ba50604', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index dd3923af..128a2650 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -147,13 +147,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 27782, 0.456561, NOW() - INTERVAL '358 hours 26 minutes'),
  ('c1e00182-efd3-4050-8c72-a06a67fbcb4f', '7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index add20f54..f40361cd 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -38,6 +38,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 36390, 1.62939, NOW() - INTERVAL '395 hours 51 minutes'),
  ('47565a3c-8a8f-4f0b-b97e-21c47d40bc2c', '7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 2ef96867..f81a9baf 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -11,6 +11,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 51197, 2.124007, NOW() - INTERVAL '395 hours 44 minutes'),
  ('df66ea1f-27cf-4e7f-b8a7-da835845fd68', '7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index ce3a804c..af398ed3 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -73,6 +73,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 2733, 1.844571, NOW() - INTERVAL '395 hours 32 minutes'),
  ('aba53aa3-720c-4b11-ac03-9f0b2bbbb6f5', '7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 993465dc..369f7922 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -75,6 +75,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 32683, 1.570406, NOW() - INTERVAL '395 hours 26 minutes'),
  ('201fbf60-9986-4143-87d6-eef818e3eec8', '7b6f87a1-1c0d-4cbf-ae7b-d6c57b5adcc3', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 57a4366e..27563f48 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -31,6 +31,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 45260, 1.403361, NOW() - INTERVAL '395 hours 15 minutes'),
  ('f65d309f-0f1b-476e-91f3-f0642b19e7bc', '1d877834-1cdd-4436-b500-46040199d8ca', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 7e196baa..d7005ac6 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -114,13 +114,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 2767, 2.594887, NOW() - INTERVAL '419 hours 31 minutes'),
  ('bf89deb0-cf08-402f-b9d2-f9d38fab0aca', '1d877834-1cdd-4436-b500-46040199d8ca', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index abefea62..05236b4b 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -91,13 +91,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 6872, 2.514434, NOW() - INTERVAL '419 hours 19 minutes'),
  ('0e5828a2-b47f-4fc2-9cfc-7abdd46c48b1', '1d877834-1cdd-4436-b500-46040199d8ca', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index cbb78a85..a55db125 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -15,5 +15,5 @@
 :root {
-  --radius-md: 12px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 54812, 0.894009, NOW() - INTERVAL '419 hours 12 minutes'),
  ('e21c8044-e583-4944-9bb5-2a72bf9baa27', '1d877834-1cdd-4436-b500-46040199d8ca', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index b6eba122..a03669cf 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -83,11 +83,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 33969, 2.556859, NOW() - INTERVAL '419 hours 3 minutes'),
  ('3e6ced9c-1318-48e7-b0a5-604df8981374', '1d877834-1cdd-4436-b500-46040199d8ca', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index eb5af157..bfb36e67 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -3,5 +3,5 @@
 :root {
-  --space-lg: 8px;
+  --space-lg: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 41334, 1.818071, NOW() - INTERVAL '418 hours 56 minutes'),
  ('16a26312-1ee6-4562-9a5d-f14d21df5284', '55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 09e8bb21..fe4232d5 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -69,5 +69,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(15)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 50477, 0.835338, NOW() - INTERVAL '436 hours 41 minutes'),
  ('edee455f-c7f2-45cd-a80f-d3f29023aaf0', '55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 0dabd78e..6ebb5384 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -40,5 +40,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v2/products")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(15)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 18859, 0.409786, NOW() - INTERVAL '436 hours 30 minutes'),
  ('d11598c0-38f0-4dfb-8482-0b9cec16666e', '55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 83fd8b96..076f31ea 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -6,6 +6,7 @@
 ALTER TABLE orders
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_orders_processed_at ON orders (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_orders_processed_at;
--- ALTER TABLE orders DROP COLUMN processed_at;
$diff$, 4, 3, 43859, 2.108341, NOW() - INTERVAL '436 hours 21 minutes'),
  ('314df77d-137f-492b-acc8-8fbb1160e4c4', '55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index f934e5dc..37e13053 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -1,6 +1,7 @@
 ALTER TABLE sessions
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_sessions_processed_at ON sessions (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_sessions_processed_at;
--- ALTER TABLE sessions DROP COLUMN processed_at;
$diff$, 4, 3, 29636, 1.978802, NOW() - INTERVAL '436 hours 10 minutes'),
  ('f3a66fb4-22a1-4684-8fab-2f6aebc1853e', '55315ac5-35b6-4e8d-90b1-a2328c7be74e', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 5601e3d0..332ad81e 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -113,5 +113,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 38433, 2.259626, NOW() - INTERVAL '436 hours 4 minutes'),
  ('20602311-e6a3-4a70-b283-314ebc6744a0', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 3671cb8d..abd1c10f 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -26,6 +26,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 15114, 1.23298, NOW() - INTERVAL '464 hours 3 minutes'),
  ('2f64aa85-b0cf-438b-9663-069ba689ade5', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 9c5d878e..606c6094 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -71,4 +71,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 56277, 0.229489, NOW() - INTERVAL '463 hours 52 minutes'),
  ('c43310a8-dab9-40e8-965e-44847763229f', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index a5bea899..66dd0b59 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -123,6 +123,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 43598, 0.270514, NOW() - INTERVAL '463 hours 44 minutes'),
  ('ca3a577d-78a1-479f-8c8b-1883fb690025', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 1fbbc38d..07a50e23 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -37,6 +37,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 40416, 2.572208, NOW() - INTERVAL '463 hours 36 minutes'),
  ('4bb26665-eb41-4efb-9b7a-e954bf341410', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 2028a182..8f263a4d 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -50,4 +50,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 41728, 0.85194, NOW() - INTERVAL '463 hours 30 minutes'),
  ('aeed3e76-bcc7-43c9-a425-97468179896f', '170a3d4c-438b-4bec-ba04-76a8c0216d6a', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index ed0e308c..954fef93 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -141,4 +141,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 34692, 1.703442, NOW() - INTERVAL '463 hours 21 minutes'),
  ('2c9f6683-3257-415b-a65a-a41b89aa3597', 'c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 55970402..262eed2e 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -130,13 +130,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 56319, 1.364895, NOW() - INTERVAL '489 hours 55 minutes'),
  ('3411d214-09a8-4316-8e96-f317ff179667', 'c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 8ee58ecd..b9fc81d2 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -237,13 +237,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 26668, 2.559897, NOW() - INTERVAL '489 hours 45 minutes'),
  ('79325447-e0a9-4e93-85a8-9f17a29c495c', 'c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index b43dfca2..9e07947c 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -9,5 +9,5 @@
 :root {
-  --radius-md: 8px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 40357, 0.785435, NOW() - INTERVAL '489 hours 35 minutes'),
  ('b6f24a17-2c8e-402e-b300-fd61e6893f56', 'c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 79dffa52..9494e715 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -36,5 +36,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 13567, 2.124326, NOW() - INTERVAL '489 hours 26 minutes'),
  ('820d1cb3-7879-425c-a06e-aef56ecb066a', 'c3453b43-44c7-4cf6-8db8-7c1cc556bf18', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 0b4de756..3a3eaa02 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -11,5 +11,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 57851, 1.096726, NOW() - INTERVAL '489 hours 17 minutes'),
  ('861da472-3381-4057-9ce2-f0575a99cdb5', '18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index b978ed63..1b01af18 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -49,6 +49,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 35296, 2.259253, NOW() - INTERVAL '517 hours'),
  ('8bbace8a-e846-4639-85be-9f0d79b31d1c', '18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 605d81f9..c3e2f19e 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -45,6 +45,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 16090, 0.792511, NOW() - INTERVAL '516 hours 52 minutes'),
  ('e0e66167-c69d-46b8-ac81-159220105178', '18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index f84a278b..edbdf76d 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -52,6 +52,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 29119, 2.001303, NOW() - INTERVAL '516 hours 43 minutes'),
  ('41c139e3-c856-4c42-8669-c2e03eeb7cfa', '18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 6bc73231..29e9888b 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -56,6 +56,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 32854, 0.905442, NOW() - INTERVAL '516 hours 34 minutes'),
  ('90ca2d5a-41d9-47dd-bc45-dafb68fbd6f3', '18a6ac6f-0c7c-4fce-9f7b-7d51c8273928', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index dd6ffb5f..2e4dd104 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -10,6 +10,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 55683, 1.701299, NOW() - INTERVAL '516 hours 24 minutes'),
  ('78f83284-2e07-460e-bfac-1cfb805daa5a', '0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index 995c856f..5cc3c02e 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -14,8 +14,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 45000,
+  "timeoutMs": 15000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 5655, 2.070698, NOW() - INTERVAL '559 hours 26 minutes'),
  ('e0bb106b-9093-438b-a277-c54b5d58a5cb', '0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index 86c4c9e5..7ec4bfec 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -132,11 +132,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v2/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 5) {
+    await new Promise((resolve) => setTimeout(resolve, 250 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 36277, 2.420504, NOW() - INTERVAL '559 hours 21 minutes'),
  ('82de95bf-e992-4c63-9b47-4edc7485b056', '0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index facfb839..3f65792b 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -3,8 +3,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 30000,
+  "timeoutMs": 15000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 22837, 1.339406, NOW() - INTERVAL '559 hours 12 minutes'),
  ('c78d9277-0178-4cfa-864d-f5e2b95ac10b', '0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index 5963125d..a4fa2bb2 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -52,11 +52,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 54223, 1.36336, NOW() - INTERVAL '559 hours 2 minutes'),
  ('4edfd4ca-a3fc-4aee-9765-89f7051a6c92', '0b9f8d61-744f-4e48-9287-47ce9da7ea58', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 73c457bd..f2760af7 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -91,13 +91,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 25995, 0.641507, NOW() - INTERVAL '558 hours 51 minutes'),
  ('45585212-080d-41d1-89f0-afc66956e1a9', 'f2e4d414-9e52-4ddd-954a-504fa07440ae', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index ab53f161..d9c8f39b 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -8,6 +8,7 @@
 ALTER TABLE refunds
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_refunds_processed_at ON refunds (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_refunds_processed_at;
--- ALTER TABLE refunds DROP COLUMN processed_at;
$diff$, 4, 3, 9479, 2.535416, NOW() - INTERVAL '579 hours 54 minutes'),
  ('7108d7f7-f03b-4796-ab5c-3124a30b08f0', 'f2e4d414-9e52-4ddd-954a-504fa07440ae', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index f3ac6c18..8fb765dc 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -84,5 +84,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(1)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 33844, 1.342273, NOW() - INTERVAL '579 hours 42 minutes'),
  ('580226ef-cd30-49c3-852c-9634e6c78e4e', 'f2e4d414-9e52-4ddd-954a-504fa07440ae', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index e3943818..a1e96b34 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -51,5 +51,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(15)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 50978, 2.495172, NOW() - INTERVAL '579 hours 34 minutes'),
  ('e8990c02-72bb-4c4a-ae4d-c325355f6afa', 'f2e4d414-9e52-4ddd-954a-504fa07440ae', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index ce3c7404..56ff471c 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -5,6 +5,7 @@
 ALTER TABLE sessions
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_sessions_processed_at ON sessions (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_sessions_processed_at;
--- ALTER TABLE sessions DROP COLUMN processed_at;
$diff$, 4, 3, 51161, 1.973098, NOW() - INTERVAL '579 hours 25 minutes'),
  ('016cd551-6289-4b1f-a2e2-279e2efc98aa', 'f2e4d414-9e52-4ddd-954a-504fa07440ae', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 1d8b37a4..40c67ada 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -3,6 +3,7 @@
 ALTER TABLE refunds
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_refunds_processed_at ON refunds (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_refunds_processed_at;
--- ALTER TABLE refunds DROP COLUMN processed_at;
$diff$, 4, 3, 50856, 2.460404, NOW() - INTERVAL '579 hours 16 minutes'),
  ('1fb2839c-1b83-4697-b8ec-ae2750152ec5', 'c7003914-3f4b-4acb-bde5-d1f22415bd88', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 348aa644..46d040aa 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -46,4 +46,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 25324, 2.427093, NOW() - INTERVAL '606 hours 28 minutes'),
  ('3ccb922c-9ccb-46a2-b551-fe3caafe502d', 'c7003914-3f4b-4acb-bde5-d1f22415bd88', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index da0eb090..eba73072 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -47,4 +47,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 34762, 0.821176, NOW() - INTERVAL '606 hours 22 minutes'),
  ('64fe9093-e3b4-409a-a0ff-cb2c1cdb30a8', 'c7003914-3f4b-4acb-bde5-d1f22415bd88', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 9c043b58..28bb33fd 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -144,4 +144,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 22546, 1.075078, NOW() - INTERVAL '606 hours 11 minutes'),
  ('4504b2bf-0b5f-48c8-b6c8-875fe1c9df33', 'c7003914-3f4b-4acb-bde5-d1f22415bd88', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 81fecba4..f40ea464 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -62,4 +62,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 10969, 1.579054, NOW() - INTERVAL '606 hours 4 minutes'),
  ('ef8fe679-05be-4f7c-9810-85745442788a', 'c7003914-3f4b-4acb-bde5-d1f22415bd88', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 7a5f5d8d..9802fe29 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -56,6 +56,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 7022, 1.662293, NOW() - INTERVAL '605 hours 51 minutes'),
  ('bd86e01e-e993-4a02-b6a0-2b254bed3db0', '729a8b08-e3f4-4948-9091-d69a32a68afa', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 2068ed50..a88d184c 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -53,13 +53,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 24596, 2.1774, NOW() - INTERVAL '638 hours 10 minutes'),
  ('54e9c95b-2682-42df-9a49-00451dc7f98e', '729a8b08-e3f4-4948-9091-d69a32a68afa', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 3f408e6a..d7166c40 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -223,13 +223,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 30480, 0.835804, NOW() - INTERVAL '638 hours 2 minutes'),
  ('46643917-7328-41a8-873e-400c589fffc3', '729a8b08-e3f4-4948-9091-d69a32a68afa', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index ef5551dd..da2dc978 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -133,13 +133,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 20085, 0.481789, NOW() - INTERVAL '637 hours 51 minutes'),
  ('8a4ee31f-26bb-4d14-b76b-09ea802fdde1', '729a8b08-e3f4-4948-9091-d69a32a68afa', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 491e8e20..4139a0d4 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -169,13 +169,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 55672, 0.552971, NOW() - INTERVAL '637 hours 40 minutes'),
  ('8f8db02e-0b37-4a91-a556-c1eb0fd20269', '729a8b08-e3f4-4948-9091-d69a32a68afa', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 86a4067a..1207dcc6 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -181,13 +181,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 32991, 0.578479, NOW() - INTERVAL '637 hours 34 minutes'),
  ('75a3ba33-3f00-4560-afd1-cfc42c80ff0d', 'b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index c3b34f5a..62fde8f7 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -61,6 +61,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 45275, 1.506519, NOW() - INTERVAL '654 hours 10 minutes'),
  ('466b1908-7a15-49e5-b2aa-21ff6309ac37', 'b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index d683bc1b..fcfac6f6 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -11,6 +11,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 7560, 1.148754, NOW() - INTERVAL '654 hours 2 minutes'),
  ('b773b137-c467-459f-a54f-817ac9c6dd4d', 'b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index d970a8d4..83254860 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -35,6 +35,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 18513, 1.508035, NOW() - INTERVAL '653 hours 51 minutes'),
  ('bef5aea1-58ec-4b14-952c-71969604612c', 'b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index b97abbb9..526247af 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -14,6 +14,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 52388, 2.175881, NOW() - INTERVAL '653 hours 46 minutes'),
  ('492fc8cd-396b-4d1f-a04e-dda9a274f292', 'b46b2cc1-1d39-4ff3-9a34-c8490b29d105', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 3425f568..74156eed 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -70,6 +70,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 20590, 2.58563, NOW() - INTERVAL '653 hours 38 minutes'),
  ('cb4dbd45-ace2-44fb-9d2b-18ee2900e94e', '73982e98-db5b-4ece-8b79-7937293721e7', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index f5829bfa..53204e74 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -177,11 +177,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 35466, 0.496517, NOW() - INTERVAL '686 hours 56 minutes'),
  ('4f6cb728-e23a-42cf-b795-f994c90248e7', '73982e98-db5b-4ece-8b79-7937293721e7', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index 538f1591..d9db82c9 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -139,11 +139,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v1/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 3) {
+    await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 41713, 0.35818, NOW() - INTERVAL '686 hours 45 minutes'),
  ('ef7f9057-dc56-4a63-b5a1-151bfdb82a05', '73982e98-db5b-4ece-8b79-7937293721e7', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index 2ea2fe23..b2f0fcb0 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -28,8 +28,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 45000,
+  "timeoutMs": 20000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 53514, 1.350094, NOW() - INTERVAL '686 hours 36 minutes'),
  ('6faedd21-3a1a-4388-886b-5175456cfdd0', '73982e98-db5b-4ece-8b79-7937293721e7', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index 31412d8e..d2015acf 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -273,11 +273,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v1/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 3) {
+    await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 4003, 0.473317, NOW() - INTERVAL '686 hours 31 minutes'),
  ('fb31d7a3-fee1-4209-a8b7-b46d4f50f143', '73982e98-db5b-4ece-8b79-7937293721e7', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index e7638e43..f8e96516 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -59,13 +59,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 35389, 1.766264, NOW() - INTERVAL '686 hours 18 minutes'),
  ('3a65d890-79e6-4706-8544-27bf2cd0147b', 'afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index e9348ffd..e827c1df 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -104,7 +104,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 5986, 2.550607, NOW() - INTERVAL '719 hours 4 minutes'),
  ('e70e2706-551b-45a8-be06-2d5c50816673', 'afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index aadd08b5..8172d2ce 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -8,6 +8,7 @@
 ALTER TABLE webhooks
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_webhooks_processed_at ON webhooks (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_webhooks_processed_at;
--- ALTER TABLE webhooks DROP COLUMN processed_at;
$diff$, 4, 3, 4406, 1.997149, NOW() - INTERVAL '718 hours 56 minutes'),
  ('129f9d75-47f3-4c48-8896-faf3d2348473', 'afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index 3daaf815..df371d07 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -165,7 +165,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 10632, 1.411115, NOW() - INTERVAL '718 hours 43 minutes'),
  ('5bb2e9c7-0944-4f40-93bd-a9c26cda19d3', 'afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index bada941a..421387b8 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -8,6 +8,7 @@
 ALTER TABLE orders
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_orders_processed_at ON orders (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_orders_processed_at;
--- ALTER TABLE orders DROP COLUMN processed_at;
$diff$, 4, 3, 33046, 1.74872, NOW() - INTERVAL '718 hours 39 minutes'),
  ('12a66f51-39e4-4036-b0d5-c2c920e33b18', 'afa2e26c-7271-4ec6-86c7-d0d1499b4e39', 'src/main/java/com/acme/gateway/RateLimiter.java', $diff$diff --git a/src/main/java/com/acme/gateway/RateLimiter.java b/src/main/java/com/acme/gateway/RateLimiter.java
index 8d74940a..882d1af1 100644
--- a/src/main/java/com/acme/gateway/RateLimiter.java
+++ b/src/main/java/com/acme/gateway/RateLimiter.java
@@ -29,7 +29,8 @@
     private long refillTokens() {
         long now = clock.millis();
-        long elapsed = now - lastRefill;
-        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        long elapsed = Math.max(0, now - lastRefill);
+        long newTokens = elapsed / REFILL_INTERVAL_MS;
+        lastRefill += newTokens * REFILL_INTERVAL_MS;
         tokens = Math.min(capacity, tokens + newTokens);
         return tokens;
     }
$diff$, 3, 2, 45412, 1.797609, NOW() - INTERVAL '718 hours 30 minutes'),
  ('beeb80a4-42ee-4e49-a356-c84521827f38', '7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index c3b5bebc..38a556dd 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -47,4 +47,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 46546, 1.5148, NOW() - INTERVAL '743 hours 51 minutes'),
  ('661551b9-39e8-4362-9e5a-4c9250e01bb9', '7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index c9ac7928..b4b0b64e 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -86,4 +86,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 27386, 0.470903, NOW() - INTERVAL '743 hours 38 minutes'),
  ('435d76f7-da2b-42e5-b824-8302dbe3552e', '7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 9896aad7..b4cb4d1f 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -116,6 +116,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 11345, 1.358852, NOW() - INTERVAL '743 hours 33 minutes'),
  ('865c13ff-fea4-4819-a1ed-be4234bed900', '7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index e2f6ff21..8903e687 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -76,4 +76,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 40754, 1.049429, NOW() - INTERVAL '743 hours 24 minutes'),
  ('8162d0c6-fa4b-40ee-87f6-2f88923c0b58', '7c44a681-5c03-4aad-baa0-64dd6e292c5b', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index ee3953fa..fbfa3a94 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -196,6 +196,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 21330, 2.047083, NOW() - INTERVAL '743 hours 11 minutes'),
  ('df409ea0-bfe0-4389-af18-fc6accd62891', '52b8bb22-657b-4a95-ac24-4de85c91b646', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 0148d74b..c64aa462 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -26,13 +26,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 35432, 1.083394, NOW() - INTERVAL '773 hours 25 minutes'),
  ('4d65e40b-118e-48b8-9ab2-f30f2fc90f6c', '52b8bb22-657b-4a95-ac24-4de85c91b646', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index a0fed5b5..56434782 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -6,5 +6,5 @@
 :root {
-  --space-lg: 12px;
+  --space-lg: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 8906, 2.592308, NOW() - INTERVAL '773 hours 15 minutes'),
  ('3c55b9f3-edd6-4a11-8f38-c947010189c5', '52b8bb22-657b-4a95-ac24-4de85c91b646', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 4675b9db..b17c0001 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -120,13 +120,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 47328, 0.718149, NOW() - INTERVAL '773 hours 7 minutes'),
  ('3faf4f42-78d7-4b25-befe-6dabf5a5c6ad', '52b8bb22-657b-4a95-ac24-4de85c91b646', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index c5f7caa7..8b84050b 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -12,13 +12,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 42937, 1.156994, NOW() - INTERVAL '772 hours 57 minutes'),
  ('c79d1bdf-b868-41e3-85b5-07deeca39a4a', '52b8bb22-657b-4a95-ac24-4de85c91b646', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 6e6694ba..de9c8d0a 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -11,13 +11,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 12057, 2.45292, NOW() - INTERVAL '772 hours 48 minutes'),
  ('8133f836-4b17-4c98-ba74-1350b138c35c', '21164d90-e913-464a-b931-b1d99c97deb9', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index cb7df58b..103d2db9 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -13,6 +13,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 20892, 0.542211, NOW() - INTERVAL '801 hours 29 minutes'),
  ('4f178b65-f4ae-4cd9-b412-8fdca7df9a99', '21164d90-e913-464a-b931-b1d99c97deb9', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 1ec998e6..1da975ac 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -11,6 +11,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 19553, 1.052403, NOW() - INTERVAL '801 hours 21 minutes'),
  ('998ccbe3-28d7-4877-af2d-178ed76701bc', '21164d90-e913-464a-b931-b1d99c97deb9', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 0c25715f..36393710 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -38,6 +38,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 27544, 1.65755, NOW() - INTERVAL '801 hours 10 minutes'),
  ('b108a2fa-34ca-4019-9dd6-744cfb131f66', '21164d90-e913-464a-b931-b1d99c97deb9', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 4cd1a663..3abf8d32 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -41,6 +41,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 12484, 0.436906, NOW() - INTERVAL '801 hours 6 minutes'),
  ('f26c6aa5-68bd-4e58-89dd-717e15a61d0e', '21164d90-e913-464a-b931-b1d99c97deb9', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 7d64b43f..13cbae41 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -79,6 +79,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 50412, 1.442675, NOW() - INTERVAL '800 hours 55 minutes'),
  ('cfea981d-cc66-46e6-9e80-1ad55c748b54', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index 03ee686f..92bd4340 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -10,5 +10,5 @@
 :root {
-  --radius-md: 12px;
+  --radius-md: 12px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 13435, 0.584802, NOW() - INTERVAL '816 hours 3 minutes'),
  ('284f9ff3-5bc0-4463-8187-a9bb05e8a9d3', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index e954363b..3d59e590 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -90,11 +90,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v2/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 3) {
+    await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 18999, 2.550735, NOW() - INTERVAL '815 hours 56 minutes'),
  ('20c01059-59ac-4680-abb3-41d5a2536373', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index ad80a9f1..532b5dff 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -2,8 +2,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 30000,
+  "timeoutMs": 10000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 26130, 1.707412, NOW() - INTERVAL '815 hours 46 minutes'),
  ('6b8f1c10-2b68-4c09-a34b-c6765febadd4', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index 45646359..7e67215d 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -38,5 +38,5 @@
 :root {
-  --space-md: 16px;
+  --space-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 10612, 0.825506, NOW() - INTERVAL '815 hours 33 minutes'),
  ('8cefa26b-bc40-4bae-bb61-00752cef5f55', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index eebf1ec2..bbb6c148 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -142,11 +142,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v2/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 5) {
+    await new Promise((resolve) => setTimeout(resolve, 500 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 29816, 1.839609, NOW() - INTERVAL '815 hours 26 minutes'),
  ('5e5720b6-68bc-4bc9-84e0-e803ee09176e', 'da461331-f9f3-4a5f-b70e-ee90a3cc6f54', 'src/types/orders.ts', $diff$diff --git a/src/types/orders.ts b/src/types/orders.ts
index 926db9bf..97985111 100644
--- a/src/types/orders.ts
+++ b/src/types/orders.ts
@@ -119,11 +119,16 @@
 export interface OrderTotals {
   subtotal: number;
-  discounts: any;
-  taxes: any;
+  discounts: DiscountLine[];
+  taxes: TaxLine[];
   shipping: number;
 }
 
 export interface DiscountLine {
   code: string;
   amount: number;
 }
+
+export interface TaxLine {
+  name: string;
+  amount: number;
+}
$diff$, 7, 2, 22609, 1.203074, NOW() - INTERVAL '815 hours 16 minutes'),
  ('5bb46a32-1cbb-44c3-ae92-8367e7bd6e4b', '2744bc27-d26e-421b-85c3-c819150ae6a7', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index db0f3883..ca203c7c 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -4,6 +4,7 @@
 ALTER TABLE sessions
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_sessions_processed_at ON sessions (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_sessions_processed_at;
--- ALTER TABLE sessions DROP COLUMN processed_at;
$diff$, 4, 3, 15359, 2.551441, NOW() - INTERVAL '847 hours 33 minutes'),
  ('99276811-ceac-440a-94e3-8b601757c963', '2744bc27-d26e-421b-85c3-c819150ae6a7', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index b279f0c2..65326ae8 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -15,8 +15,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 60000,
+  "timeoutMs": 20000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 13773, 1.294617, NOW() - INTERVAL '847 hours 23 minutes'),
  ('5bba08c5-1132-4915-b2b2-d164639b6e02', '2744bc27-d26e-421b-85c3-c819150ae6a7', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 74c0f5a2..c500d764 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -4,6 +4,7 @@
 ALTER TABLE sessions
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_sessions_processed_at ON sessions (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_sessions_processed_at;
--- ALTER TABLE sessions DROP COLUMN processed_at;
$diff$, 4, 3, 10115, 0.412478, NOW() - INTERVAL '847 hours 16 minutes'),
  ('2c8c72b3-1c8f-418b-a3b9-274a626b8ab4', '2744bc27-d26e-421b-85c3-c819150ae6a7', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 49d49de6..92c03d99 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -20,5 +20,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v2/products")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 23735, 2.596171, NOW() - INTERVAL '847 hours 8 minutes'),
  ('86e7fbc0-700e-49b3-a5e9-dc5442c39e10', '2744bc27-d26e-421b-85c3-c819150ae6a7', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 7f510134..ad5d34ca 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -18,5 +18,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v2/products")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(1)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 7120, 1.809333, NOW() - INTERVAL '846 hours 57 minutes'),
  ('c1c4b01e-b03c-4838-8f10-ff1270de4fd6', 'fe2063c6-0670-471d-bbac-b66dc86c663b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 31b1d13f..eada11a0 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -110,4 +110,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 45376, 1.203487, NOW() - INTERVAL '870 hours 4 minutes'),
  ('3766da36-8b17-4a30-8189-5c0d6835b9c8', 'fe2063c6-0670-471d-bbac-b66dc86c663b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 04011d48..749d61b1 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -45,4 +45,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 23334, 2.484364, NOW() - INTERVAL '869 hours 55 minutes'),
  ('7905df6b-da13-4641-bfa2-419e2bc6b28f', 'fe2063c6-0670-471d-bbac-b66dc86c663b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index f28360f1..6d6176c4 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -23,4 +23,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 36274, 0.866828, NOW() - INTERVAL '869 hours 51 minutes'),
  ('a05c5973-6f10-4427-94ca-c93ce64ca982', 'fe2063c6-0670-471d-bbac-b66dc86c663b', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index ce974172..f3df7c7e 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -24,4 +24,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 11023, 0.704063, NOW() - INTERVAL '869 hours 39 minutes'),
  ('b1a62e82-4237-472f-9505-4e3ea054b433', 'fe2063c6-0670-471d-bbac-b66dc86c663b', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 17227c47..9c0db7b3 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -26,6 +26,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 15690, 1.767368, NOW() - INTERVAL '869 hours 32 minutes'),
  ('2d23c04f-6b80-4c9d-aa51-bbde18ef0590', '377a70cf-5d3a-4f30-a81d-86e6edb47783', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index e3a448c3..074301b1 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -106,13 +106,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 11855, 0.807542, NOW() - INTERVAL '891 hours 12 minutes'),
  ('2dc01e0e-277a-4e7d-97ab-96b1cfc2aeaa', '377a70cf-5d3a-4f30-a81d-86e6edb47783', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 1e28a2b9..cd37f165 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -8,5 +8,5 @@
 :root {
-  --space-md: 16px;
+  --space-md: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 31961, 1.52479, NOW() - INTERVAL '891 hours 3 minutes'),
  ('9f06ce5c-26ed-42fa-9bd6-f7187ce16b52', '377a70cf-5d3a-4f30-a81d-86e6edb47783', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 72ea0920..5812014c 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -14,5 +14,5 @@
 :root {
-  --space-md: 12px;
+  --space-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 11926, 0.958676, NOW() - INTERVAL '890 hours 50 minutes'),
  ('a7146f5d-08da-400c-bb01-701cec1ed480', '377a70cf-5d3a-4f30-a81d-86e6edb47783', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index c1aef097..b2ed33a3 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -14,5 +14,5 @@
 :root {
-  --space-md: 8px;
+  --space-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 55098, 0.89601, NOW() - INTERVAL '890 hours 44 minutes'),
  ('4607de7e-3ff8-43fa-9f71-7fdd0b217a76', '377a70cf-5d3a-4f30-a81d-86e6edb47783', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 70de052c..bf1e9897 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -153,13 +153,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 30975, 0.237415, NOW() - INTERVAL '890 hours 33 minutes'),
  ('8a77941a-82ca-4d51-8508-af08365ed0fe', '7b0c5574-32b5-407e-a126-5d0ec1731263', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 7840277a..fa223515 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -32,6 +32,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 51244, 0.870233, NOW() - INTERVAL '933 hours 9 minutes'),
  ('1efad35e-2557-4a47-8780-33efc2808baa', '7b0c5574-32b5-407e-a126-5d0ec1731263', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index d793b00d..c8104bbd 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -72,6 +72,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 35627, 1.39249, NOW() - INTERVAL '933 hours'),
  ('f4a4ed7f-e281-4018-9cc9-5961433ed4e8', '7b0c5574-32b5-407e-a126-5d0ec1731263', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index c67d71ae..4e4f7c24 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -70,6 +70,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 35908, 0.614765, NOW() - INTERVAL '932 hours 55 minutes'),
  ('0694b18f-42ae-4ef5-9e2e-c7d9b3b21c25', '7b0c5574-32b5-407e-a126-5d0ec1731263', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 307d8559..3a1baf7e 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -5,6 +5,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 46263, 2.029583, NOW() - INTERVAL '932 hours 41 minutes'),
  ('8323d257-9d61-40c0-aa08-065c54f22159', '7b0c5574-32b5-407e-a126-5d0ec1731263', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 48eaf928..689cbc0b 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -32,6 +32,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 51693, 2.443797, NOW() - INTERVAL '932 hours 37 minutes'),
  ('482414d3-563c-40af-8871-fa5c4b056a51', '648bea9d-3d3a-4c77-83d6-2919fe753729', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index 250da203..bb143598 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -18,13 +18,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 47586, 1.583577, NOW() - INTERVAL '958 hours 57 minutes'),
  ('e1950090-330f-428c-b880-6145eccf26db', '648bea9d-3d3a-4c77-83d6-2919fe753729', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 476ab1b1..056273bb 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -212,13 +212,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 18841, 2.085296, NOW() - INTERVAL '958 hours 53 minutes'),
  ('3986c5bd-fde1-4d33-acc5-936c8f47ff4b', '648bea9d-3d3a-4c77-83d6-2919fe753729', 'src/services/checkout.ts', $diff$diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index 5b8e3237..2cfb5865 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -158,11 +158,17 @@
 export async function createSession(items: CartItem[], attempt = 0): Promise<Session> {
   const response = await fetch(`${API_BASE}/v2/checkout`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ items }),
   });
+
+  if (response.status === 429 && attempt < 5) {
+    await new Promise((resolve) => setTimeout(resolve, 250 * 2 ** attempt));
+    return createSession(items, attempt + 1);
+  }
+
   if (!response.ok) {
     throw new CheckoutError(`checkout failed: ${response.status}`);
   }
   return response.json() as Promise<Session>;
 }
$diff$, 6, 0, 55769, 0.814514, NOW() - INTERVAL '958 hours 41 minutes'),
  ('8e67b1ed-9a26-46b9-b334-7652ffb01fc7', '648bea9d-3d3a-4c77-83d6-2919fe753729', 'src/components/CartPage.tsx', $diff$diff --git a/src/components/CartPage.tsx b/src/components/CartPage.tsx
index 7cb1d1c9..597ae5ec 100644
--- a/src/components/CartPage.tsx
+++ b/src/components/CartPage.tsx
@@ -69,13 +69,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 13426, 1.295175, NOW() - INTERVAL '958 hours 30 minutes'),
  ('392d9daa-e053-4ee4-8ff7-bbc170b7dc33', '648bea9d-3d3a-4c77-83d6-2919fe753729', 'src/styles/theme.css', $diff$diff --git a/src/styles/theme.css b/src/styles/theme.css
index 3ef2bb8d..6f0c56c9 100644
--- a/src/styles/theme.css
+++ b/src/styles/theme.css
@@ -27,5 +27,5 @@
 :root {
-  --space-md: 12px;
+  --space-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 9464, 2.518528, NOW() - INTERVAL '958 hours 22 minutes'),
  ('b5bc569f-d949-454b-a78a-12cc55e2cbcc', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index e09203d7..91c8e1db 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -17,5 +17,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v2/products")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 21819, 2.491839, NOW() - INTERVAL '991 hours 4 minutes'),
  ('84755cf9-b873-44d0-afdb-e49167145c2c', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'config/gateway.json', $diff$diff --git a/config/gateway.json b/config/gateway.json
index df72cc95..36581c8f 100644
--- a/config/gateway.json
+++ b/config/gateway.json
@@ -4,8 +4,12 @@
 {
   "upstream": "http://payments:9000",
-  "timeoutMs": 45000,
+  "timeoutMs": 10000,
+  "retry": {
+    "maxAttempts": 3,
+    "backoffMs": 500
+  },
   "circuitBreaker": {
     "failureThreshold": 5,
     "windowSeconds": 30
   }
 }
$diff$, 5, 1, 28355, 0.707774, NOW() - INTERVAL '990 hours 54 minutes'),
  ('69780eed-ebaa-452f-bee8-e8dad2402be2', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java', $diff$diff --git a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
index 99396309..ed615cec 100644
--- a/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
+++ b/src/main/java/com/acme/gateway/filter/CacheHeaderFilter.java
@@ -36,5 +36,9 @@
     @Override
     public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
+        ServerHttpResponse response = exchange.getResponse();
+        if (exchange.getRequest().getPath().value().startsWith("/v1/catalog")) {
+            response.getHeaders().setCacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic());
+        }
         return chain.filter(exchange);
     }
 }
$diff$, 4, 0, 40730, 1.943963, NOW() - INTERVAL '990 hours 45 minutes'),
  ('2f807d56-8f03-49fd-b6c0-b776e39cdc34', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index c25a0926..5ceab57f 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -9,6 +9,7 @@
 ALTER TABLE refunds
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_refunds_processed_at ON refunds (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_refunds_processed_at;
--- ALTER TABLE refunds DROP COLUMN processed_at;
$diff$, 4, 3, 44049, 2.097356, NOW() - INTERVAL '990 hours 36 minutes'),
  ('6ff7446e-158c-42f1-bda2-51d2590a34cf', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 0a746546..596e2918 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -1,6 +1,7 @@
 ALTER TABLE orders
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_orders_processed_at ON orders (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_orders_processed_at;
--- ALTER TABLE orders DROP COLUMN processed_at;
$diff$, 4, 3, 14330, 2.097255, NOW() - INTERVAL '990 hours 26 minutes'),
  ('bb02af1b-ea42-4e5b-b69c-e50ff5a5c0a4', '0c2adf49-205f-4668-9e8c-17547f20fb8b', 'src/main/resources/db/migration/V17__processed_at.sql', $diff$diff --git a/src/main/resources/db/migration/V17__processed_at.sql b/src/main/resources/db/migration/V17__processed_at.sql
index 9072b649..fa39a3a9 100644
--- a/src/main/resources/db/migration/V17__processed_at.sql
+++ b/src/main/resources/db/migration/V17__processed_at.sql
@@ -9,6 +9,7 @@
 ALTER TABLE orders
     ADD COLUMN processed_at timestamptz;
+
+-- Serves: ops-dashboard query filtering by processing window
+CREATE INDEX idx_orders_processed_at ON orders (processed_at DESC);
+
 -- Down migration
-
--- DROP INDEX idx_orders_processed_at;
--- ALTER TABLE orders DROP COLUMN processed_at;
$diff$, 4, 3, 37954, 1.176254, NOW() - INTERVAL '990 hours 21 minutes'),
  ('bb2e3ac1-490e-478d-827a-2d91f9881fd3', '2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 768a5f4f..311eadb4 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -151,6 +151,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 7044, 0.558391, NOW() - INTERVAL '1016 hours 59 minutes'),
  ('111abef1-1fb8-40e5-9282-213a6671df4f', '2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index d8cbc04b..b20b3616 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -82,6 +82,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 50918, 1.136852, NOW() - INTERVAL '1016 hours 51 minutes'),
  ('e30d8761-c948-4ef9-9456-a0957cd4e36c', '2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 65b57641..e9dc4b4f 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -37,6 +37,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 51013, 2.004742, NOW() - INTERVAL '1016 hours 40 minutes'),
  ('3bf56629-e93d-4783-981a-3f97493a35ca', '2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'payments/charges.py', $diff$diff --git a/payments/charges.py b/payments/charges.py
index 1eade9d2..f9d0647d 100644
--- a/payments/charges.py
+++ b/payments/charges.py
@@ -94,4 +94,6 @@
 def compute_fee(amount: float, rate: float) -> float:
-    fee = amount * rate * 0.01
-    return round(fee, 2)
+    amount_dec = Decimal(str(amount))
+    rate_dec = Decimal(str(rate))
+    fee = amount_dec * rate_dec / Decimal("100")
+    return float(fee.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
 
$diff$, 4, 2, 42267, 2.426771, NOW() - INTERVAL '1016 hours 31 minutes'),
  ('4fd76c13-ed3a-4f4f-801f-013ee5bdcd21', '2763f9f2-2b21-4af8-b36c-a8444f675e5d', 'payments/refunds.py', $diff$diff --git a/payments/refunds.py b/payments/refunds.py
index 6a059083..c2252932 100644
--- a/payments/refunds.py
+++ b/payments/refunds.py
@@ -50,6 +50,12 @@
 def create_refund(charge_id: str, amount: Decimal, key: str | None = None) -> Refund:
+    if key:
+        existing = Refund.objects.filter(idempotency_key=key).first()
+        if existing:
+            logger.info("returning existing refund %s for key %s", existing.id, key)
+            return existing
     refund = Refund.objects.create(
         charge_id=charge_id,
         amount=amount,
+        idempotency_key=key,
     )
     return refund
$diff$, 6, 0, 28074, 0.23459, NOW() - INTERVAL '1016 hours 22 minutes'),
  ('1d418f4e-128a-4650-9d39-23af898f310e', 'f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 546e507b..153eeea2 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -36,5 +36,5 @@
 :root {
-  --radius-md: 12px;
+  --radius-md: 16px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 35491, 1.544174, NOW() - INTERVAL '1044 hours 1 minute'),
  ('3efaf821-e45d-40f4-a3ee-54682c31503c', 'f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 78323f17..37887fd8 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -260,13 +260,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 49817, 0.234448, NOW() - INTERVAL '1043 hours 52 minutes'),
  ('74bf1aaa-8149-4e4c-b174-0c0d788737e4', 'f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index c898ab7d..8e473c6a 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -5,5 +5,5 @@
 :root {
-  --space-lg: 12px;
+  --space-lg: 24px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 19539, 2.514011, NOW() - INTERVAL '1043 hours 41 minutes'),
  ('804138d2-0e5c-4f27-9541-a0d77916d6ac', 'f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'src/components/CheckoutButton.tsx', $diff$diff --git a/src/components/CheckoutButton.tsx b/src/components/CheckoutButton.tsx
index 500e7baa..c50479bf 100644
--- a/src/components/CheckoutButton.tsx
+++ b/src/components/CheckoutButton.tsx
@@ -218,13 +218,15 @@
 export function CheckoutButton({ session }: Props) {
-  const [disabled, setDisabled] = useState(false);
 
+  const [status, setStatus] = useState<"idle" | "loading" | "error">("idle");
+  const disabled = status === "loading";
   async function handleClick() {
-    setDisabled(true);
+    setStatus("loading");
     try {
       await createSession(session.items);
     } catch (err) {
+      setStatus("error");
       console.error(err);
     } finally {
-      setDisabled(false);
+      setStatus("idle");
     }
   }
$diff$, 5, 3, 5205, 1.8122, NOW() - INTERVAL '1043 hours 33 minutes'),
  ('b47ae703-246b-4bf2-91ba-c7a59407f170', 'f0cfbe83-cbf0-4862-8b66-c8e50b99da65', 'src/tokens/spacing.css', $diff$diff --git a/src/tokens/spacing.css b/src/tokens/spacing.css
index 0d9ea001..f4f54c7a 100644
--- a/src/tokens/spacing.css
+++ b/src/tokens/spacing.css
@@ -28,5 +28,5 @@
 :root {
-  --radius-md: 16px;
+  --radius-md: 12px;
   --space-lg: 24px;
   --radius-md: 8px;
 }
$diff$, 1, 1, 7137, 1.650964, NOW() - INTERVAL '1043 hours 23 minutes'),
  ('17d490f4-1fd8-42c1-bfd9-16624388a4f3', '3522db69-2300-43ba-9326-aab1bf653ee8', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 292bbff3..4256b3f3 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -21,6 +21,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 40
+  }
 
   network_configuration {
$diff$, 6, 2, 43205, 2.107909, NOW() - INTERVAL '1054 hours 50 minutes'),
  ('7013259b-9952-49ac-b403-61cdadd20f54', '3522db69-2300-43ba-9326-aab1bf653ee8', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index cb66b36a..53e7b090 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -41,6 +41,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 28746, 1.740272, NOW() - INTERVAL '1054 hours 41 minutes'),
  ('3bad755d-71fb-4c98-a490-9db6858eca8b', '3522db69-2300-43ba-9326-aab1bf653ee8', 'infra/terraform/ecs.tf', $diff$diff --git a/infra/terraform/ecs.tf b/infra/terraform/ecs.tf
index 3f0a4468..8ffa1e0e 100644
--- a/infra/terraform/ecs.tf
+++ b/infra/terraform/ecs.tf
@@ -80,6 +80,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 3
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 41625, 2.553952, NOW() - INTERVAL '1054 hours 31 minutes'),
  ('2ef96867-274c-45c7-a551-a8240df8b935', '3522db69-2300-43ba-9326-aab1bf653ee8', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 53b86429..9b02907e 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -16,6 +16,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 33209, 2.380294, NOW() - INTERVAL '1054 hours 26 minutes'),
  ('df7c3f04-3796-46a2-8da5-a36ef81a9baf', '3522db69-2300-43ba-9326-aab1bf653ee8', 'infra/terraform/rds.tf', $diff$diff --git a/infra/terraform/rds.tf b/infra/terraform/rds.tf
index 3d0a08bd..0edbfefd 100644
--- a/infra/terraform/rds.tf
+++ b/infra/terraform/rds.tf
@@ -67,6 +67,10 @@
 resource "aws_ecs_service" "gateway" {
   name            = "gateway"
-  task_definition = aws_ecs_task_definition.gateway.arn
-  desired_count   = 1
+  task_definition = aws_ecs_task_definition.gateway_v2.arn
+  desired_count   = 2
+  capacity_provider_strategy {
+    capacity_provider = "FARGATE_SPOT"
+    weight            = 60
+  }
 
   network_configuration {
$diff$, 6, 2, 28477, 1.154138, NOW() - INTERVAL '1054 hours 16 minutes');

INSERT INTO review_verdict (id, patch_id, reviewer, decision, override_reason, decided_at) VALUES
  ('c0ac6abd-c1c5-4ff7-9851-9df2898eecd4', 'c1c4b01e-b03c-4838-8f10-ff1270de4fd6', 'ci-review-bot', 'REJECTED', NULL, NOW() - INTERVAL '849 hours 33 minutes'),
  ('5ab50543-d327-4653-98f8-d10ca3d9182a', '9c13a804-e3a6-4c1f-8e42-328da673c89e', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '178 hours 19 minutes'),
  ('ce3a804c-5be5-4a1b-a98a-0151addecc90', 'c5ccc136-893a-48c1-a625-897d86556531', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '191 hours 7 minutes'),
  ('f75342e9-9503-4d9c-b016-3cb9af398ed3', '492fc8cd-396b-4d1f-a04e-dda9a274f292', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '643 hours 26 minutes'),
  ('49a0035a-b20a-4e80-8fbf-e60002153217', '3766da36-8b17-4a30-8189-5c0d6835b9c8', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '844 hours 1 minute'),
  ('a78e35e3-50a7-4523-a49a-1ee98d32afe0', 'de14b04b-3190-4cd6-9ca9-b3adb6cea86f', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '191 hours 10 minutes'),
  ('369f7922-9934-45dc-9056-98b7c5c38298', 'd11598c0-38f0-4dfb-8482-0b9cec16666e', 'alice', 'REJECTED', NULL, NOW() - INTERVAL '411 hours 23 minutes'),
  ('b219ba31-7713-48f1-9af8-7e6e93158fd7', 'b773b137-c467-459f-a54f-817ac9c6dd4d', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '611 hours 40 minutes'),
  ('e0242a75-3b80-4465-8b6a-7f2d70145938', 'f3a66fb4-22a1-4684-8fab-2f6aebc1853e', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '400 hours 50 minutes'),
  ('7f415cd2-4f4c-4ea8-b41f-3516d0ebdf38', '16a26312-1ee6-4562-9a5d-f14d21df5284', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '418 hours'),
  ('a98dec07-8169-4762-a756-3f4857a4366e', 'a05c5973-6f10-4427-94ca-c93ce64ca982', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '858 hours 2 minutes'),
  ('33e9c592-2e4a-48bd-a79e-fb6ea834f65d', '466b1908-7a15-49e5-b2aa-21ff6309ac37', 'alice', 'REJECTED', NULL, NOW() - INTERVAL '621 hours 56 minutes'),
  ('e548165c-467b-4762-91a0-3579bef6c38f', 'edee455f-c7f2-45cd-a80f-d3f29023aaf0', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '415 hours 31 minutes'),
  ('e8f11af6-c1e1-4591-b78c-f03d45c327b6', '7905df6b-da13-4641-bfa2-419e2bc6b28f', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '869 hours 17 minutes'),
  ('68477ed7-591e-4f8d-aa64-c85d8b646d1c', 'c43310a8-dab9-40e8-965e-44847763229f', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '426 hours 58 minutes'),
  ('1b435410-ff75-4a2e-9700-5ac67e196baa', 'ca3a577d-78a1-479f-8c8b-1883fb690025', 'bob', 'ACCEPTED', 'Bot flagged a flaky test as the cause; manually verified the test passes in isolation.', NOW() - INTERVAL '421 hours 24 minutes'),
  ('5eebc317-440e-4879-bbbb-cb3a02371821', '18d1d52b-dd94-4d87-8796-1f5640996266', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '242 hours 14 minutes'),
  ('f6f2c7bd-0523-4b4b-abef-ea6251ea2eef', 'cb4dbd45-ace2-44fb-9d2b-18ee2900e94e', 'charlie', 'ACCEPTED', 'Manual override: the diff only touched generated files.', NOW() - INTERVAL '652 hours 57 minutes'),
  ('3d96de6c-c5e6-40bf-9240-7cc6be016f58', '9f06ce5c-26ed-42fa-9bd6-f7187ce16b52', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '863 hours 45 minutes'),
  ('b3439c28-dd13-4051-b1ea-36d18bf54410', '6faedd21-3a1a-4388-886b-5175456cfdd0', 'alice', 'REJECTED', NULL, NOW() - INTERVAL '673 hours 58 minutes'),
  ('a55db125-cbb7-4a85-b7b0-0f3a5c6957b7', '4f6cb728-e23a-42cf-b795-f994c90248e7', 'bob', 'REJECTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '682 hours 31 minutes'),
  ('ba4ebc0a-cd84-4a46-92ce-4eef4b8814b9', 'f5daf044-5413-4f04-90c7-b503976d6a61', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '240 hours 23 minutes'),
  ('b6eba122-4e40-4c14-aece-49254f67420c', '2dc01e0e-277a-4e7d-97ab-96b1cfc2aeaa', 'bob', 'REJECTED', 'Manual override: the diff only touched generated files.', NOW() - INTERVAL '851 hours 38 minutes'),
  ('e7c861aa-133d-4a24-bb6f-b53ba03669cf', 'a7146f5d-08da-400c-bb01-701cec1ed480', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '869 hours 53 minutes'),
  ('969d6cab-6f78-4c84-bc19-8f82e8eb749a', '2d23c04f-6b80-4c9d-aa51-bbde18ef0590', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '860 hours 28 minutes'),
  ('2c495c27-611a-4dad-8169-804f9cb652fa', '4607de7e-3ff8-43fa-9f71-7fdd0b217a76', 'alice', 'ACCEPTED', 'Bot flagged a flaky test as the cause; manually verified the test passes in isolation.', NOW() - INTERVAL '859 hours 31 minutes'),
  ('ad489595-bfb3-4e67-ab5a-f1577a97b412', 'dcee3c89-a076-405e-bed0-751932bd87ac', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '219 hours 54 minutes'),
  ('516d4188-98de-4ac2-adb7-f201b19dd572', '4bb26665-eb41-4efb-9b7a-e954bf341410', 'bob', 'REJECTED', NULL, NOW() - INTERVAL '426 hours 25 minutes'),
  ('6be5e76a-858d-4505-91e1-80e16d55a97f', '20602311-e6a3-4a70-b283-314ebc6744a0', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '450 hours 52 minutes'),
  ('24376de4-6096-402a-bf8f-c9c76796c982', '8a77941a-82ca-4d51-8508-af08365ed0fe', 'bob', 'REJECTED', NULL, NOW() - INTERVAL '897 hours 6 minutes'),
  ('3f0f3b9e-2481-43ee-81cf-8585e4c92ad7', '1efad35e-2557-4a47-8780-33efc2808baa', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '904 hours 44 minutes'),
  ('bf040653-2f05-4877-ad61-8fc33709545a', '1c180a04-cd2a-43a2-b80f-5e117e131848', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '275 hours 4 minutes'),
  ('a595815c-4553-4610-be42-32d509e8bb21', '344efdd1-da09-4dc1-8f85-386209e8fbd6', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '252 hours 58 minutes'),
  ('b3c212ad-7252-409a-ba6b-467ebc956cc5', '7fe29ca0-12fe-49ea-aa93-0be1e58bf09b', 'bob', 'REJECTED', NULL, NOW() - INTERVAL '43 hours 18 minutes'),
  ('bca242bc-61e5-435e-b3dd-e17c2c3a99e6', 'f4a4ed7f-e281-4018-9cc9-5961433ed4e8', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '929 hours 3 minutes'),
  ('0737883b-184e-45c7-aebb-53840dabd78e', '3a0cf435-9b3f-47eb-912b-590f82f28d45', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '243 hours 57 minutes'),
  ('b33806a4-6caf-4b75-8113-385ced150df0', '820d1cb3-7879-425c-a06e-aef56ecb066a', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '458 hours 42 minutes'),
  ('9c0280a9-1b46-4689-9f7a-610e709622f5', '129f9d75-47f3-4c48-8896-faf3d2348473', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '685 hours 17 minutes'),
  ('83fd8b96-01e8-42c7-a095-9312c25dfff7', 'b6f24a17-2c8e-402e-b300-fd61e6893f56', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '461 hours 57 minutes'),
  ('dfca2496-8c32-4145-8bfd-625c076f31ea', '8323d257-9d61-40c0-aa08-065c54f22159', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '885 hours 35 minutes'),
  ('67957925-6338-4792-905d-f33ca2bbda20', '3411d214-09a8-4316-8e96-f317ff179667', 'alice', 'REJECTED', NULL, NOW() - INTERVAL '452 hours 42 minutes'),
  ('a2035c72-8601-43f1-87cb-24950b96de5c', '2c9f6683-3257-415b-a65a-a41b89aa3597', 'diana', 'ACCEPTED', 'Bot flagged a flaky test as the cause; manually verified the test passes in isolation.', NOW() - INTERVAL '454 hours 4 minutes'),
  ('f934e5dc-021d-49e4-a351-1cd6c46eebbc', '5cee4bfe-5c10-4414-a799-f3e4707fb018', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '266 hours 52 minutes'),
  ('6b2c7b85-719a-4192-be49-57a837e13053', 'b1558b38-b3d4-48e8-8922-ff3444c8780c', 'ci-review-bot', 'REJECTED', NULL, NOW() - INTERVAL '66 hours 17 minutes'),
  ('c5cb1a86-3932-412a-bd70-b3f259defcfb', 'dfad59cd-15c9-4d30-bf2d-1ac1aeaf35e2', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '60 hours 4 minutes'),
  ('5601e3d0-7f20-4ac0-af9e-99381a1945a9', '30740151-4b5a-434e-b84f-b54b31daacaf', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '46 hours 21 minutes'),
  ('8d89c627-bd87-46c6-9bfe-57ae332ad81e', '0694b18f-42ae-4ef5-9e2e-c7d9b3b21c25', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '923 hours 4 minutes'),
  ('d88e0085-d83d-4a85-bd88-2db4307348b1', 'e70e2706-551b-45a8-be06-2d5c50816673', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '716 hours 40 minutes'),
  ('46cb4623-2d32-4b11-b5f9-70356cd20bfa', '41c139e3-c856-4c42-8669-c2e03eeb7cfa', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '503 hours 33 minutes'),
  ('a5c176f7-9c32-4427-86ac-36c528dd8dca', '556914f5-ce37-43da-aac7-4eab28822c17', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '276 hours 59 minutes'),
  ('0b8b6df5-60c6-40cc-97e9-94ad674ade56', '3986c5bd-fde1-4d33-acc5-936c8f47ff4b', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '912 hours 42 minutes'),
  ('45e90776-6f63-4fb3-abd1-c10f3671cb8d', '90ca2d5a-41d9-47dd-bc45-dafb68fbd6f3', 'bob', 'REJECTED', NULL, NOW() - INTERVAL '472 hours 42 minutes'),
  ('1cb20e7b-9337-472d-b762-0b9332724257', '91d68fc0-a386-4295-b770-30554af16b40', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '67 hours 28 minutes'),
  ('053c36f6-606c-4094-9c5d-878e3d46c021', '8162d0c6-fa4b-40ee-87f6-2f88923c0b58', 'charlie', 'REJECTED', 'Re-opened: bot rejection did not match the issue acceptance criteria.', NOW() - INTERVAL '725 hours 28 minutes'),
  ('dfc7142d-ba27-4dde-933d-bba30936c31c', '661551b9-39e8-4362-9e5a-4c9250e01bb9', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '719 hours 36 minutes'),
  ('a5bea899-6cd2-4229-91b8-24bdbe03e4d6', '57dbfbb0-bc18-4936-9c67-33e259cfb90b', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '290 hours 22 minutes'),
  ('a1b6447a-4eed-4d3c-8993-357966dd0b59', '5c7a5069-4d0a-4b94-9a8b-ecceaa0dfccc', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '303 hours 11 minutes'),
  ('1627b34a-70a7-41a1-b7bd-4abaa1c39200', '392d9daa-e053-4ee4-8ff7-bbc170b7dc33', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '921 hours 30 minutes'),
  ('4c5f33ca-fd0f-4e89-87a5-0e231fbbc38d', '4f06c137-68c3-4e9a-b36b-d157f135159e', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '267 hours 16 minutes'),
  ('226d9718-526e-42d9-91d7-432795487d8b', '62511e1b-8dec-4d5c-b17d-6f9caf58395d', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '57 hours 43 minutes'),
  ('8f263a4d-2028-4182-a8d1-192beb941b44', '865c13ff-fea4-4819-a1ed-be4234bed900', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '698 hours 10 minutes'),
  ('21fc1d5d-9a68-476f-83a0-30f44714cb04', 'b8339f3d-bb43-422e-8d9b-c711104a8209', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '68 hours 2 minutes'),
  ('ed0e308c-83da-4035-b28b-dd4aee79120c', '8e67b1ed-9a26-46b9-b334-7652ffb01fc7', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '923 hours 9 minutes'),
  ('7eec84ae-7bd9-4b17-a128-4f8c954fef93', '861da472-3381-4057-9ce2-f0575a99cdb5', 'charlie', 'ACCEPTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '479 hours 58 minutes'),
  ('e7f99d19-c97f-43ea-80a8-e23e41deb675', '922ca333-15bb-4f00-ac25-e4a972ddd9ad', 'alice', 'REJECTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '76 hours 52 minutes'),
  ('fbf872c0-7e49-461e-8727-362c5f135102', 'cf93e3ec-b5a2-4cc1-b972-698834064891', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '88 hours 39 minutes'),
  ('ae487e90-9df3-44f3-9988-30224399900e', '4edfd4ca-a3fc-4aee-9765-89f7051a6c92', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '544 hours 38 minutes'),
  ('2b567747-ee05-4b49-9628-48fc26aaf740', '4f1f8059-7f35-4e68-af11-59e67a884223', 'charlie', 'REJECTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '68 hours 59 minutes'),
  ('55970402-781a-4a19-ba3c-ef38cff8db1e', '82de95bf-e992-4c63-9b47-4edc7485b056', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '511 hours 40 minutes'),
  ('d367a931-ddc1-4cc1-bd58-21a6262eed2e', 'df409ea0-bfe0-4389-af18-fc6accd62891', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '725 hours 45 minutes'),
  ('0dff141a-f3eb-4774-ac42-4acf555fda7e', 'c9ce0528-26ca-4b76-a1c4-f161d740d572', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '110 hours 55 minutes'),
  ('fbc1fa6a-b9fc-41d2-8ee5-8ecde3c2ee1a', '3c55b9f3-edd6-4a11-8f38-c947010189c5', 'bob', 'REJECTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '748 hours 51 minutes'),
  ('c264e54e-68da-409f-9f94-ec85d384120c', '6ff7446e-158c-42f1-bda2-51d2590a34cf', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '958 hours 34 minutes'),
  ('03843ead-8fd8-400e-9a15-e07e535e4ed5', 'cd41e8ec-df9b-4f0a-8d62-8c709f8df148', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '70 hours 6 minutes'),
  ('400bcb35-9e07-447c-b43d-fca27215db2b', '3faf4f42-78d7-4b25-befe-6dabf5a5c6ad', 'bob', 'ACCEPTED', 'Bot flagged a flaky test as the cause; manually verified the test passes in isolation.', NOW() - INTERVAL '758 hours 4 minutes'),
  ('aea022e9-8bc4-463a-950d-d4618e042e2e', 'e0bb106b-9093-438b-a277-c54b5d58a5cb', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '553 hours'),
  ('953b2263-d0d1-46c3-840d-98a677cd6310', '74412722-093b-4e40-b1e5-9b11738adafa', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '281 hours 9 minutes'),
  ('9494e715-79df-4a52-a945-f8b5970e4397', '46757041-d89f-49a2-8bec-48747c77207b', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '108 hours 15 minutes'),
  ('7946d91a-2c67-47d9-8bef-e562cdae4772', '6032395c-839f-42a6-b4fd-3b8b8ca11508', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '287 hours 34 minutes'),
  ('e3d8ee56-dd5a-4fb3-bc99-c233c40c8cc9', '3d79f098-4bfe-4106-8a2a-62839159880b', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '293 hours 7 minutes'),
  ('add3aa7c-babc-4b38-a08f-7cf65a947276', '69780eed-ebaa-452f-bee8-e8dad2402be2', 'diana', 'REJECTED', NULL, NOW() - INTERVAL '964 hours 59 minutes'),
  ('60f9dc72-3a3e-4a02-8b4d-e756784696ef', '4d65e40b-118e-48b8-9ab2-f30f2fc90f6c', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '727 hours 29 minutes'),
  ('a80e277b-b6c7-423c-9963-3c82617357d6', '4d4d5404-9de6-4649-93f9-8f1c70f5c12d', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '83 hours 13 minutes'),
  ('fe89967c-9019-40a1-861d-afe828dbfba6', '0d7f6322-c108-4705-b8a9-4ea04da8f97b', 'diana', 'ACCEPTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '313 hours 13 minutes'),
  ('f58c03ab-0e16-44a5-a303-d8cedea65e88', '84755cf9-b873-44d0-afdb-e49167145c2c', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '948 hours 8 minutes'),
  ('f72f659d-348a-48a5-a4e5-6e9ed794783f', 'b108a2fa-34ca-4019-9dd6-744cfb131f66', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '762 hours 12 minutes'),
  ('a8e1b1ec-3660-4524-8a9c-7114643170b1', '3bf56629-e93d-4783-981a-3f97493a35ca', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '1004 hours 6 minutes'),
  ('6c74a4c5-ac48-4989-8f6b-ad7858ed88fd', '7108d7f7-f03b-4796-ab5c-3124a30b08f0', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '567 hours 23 minutes'),
  ('1279e8bb-dbf4-4a9b-9b01-af18b978ed63', '8133f836-4b17-4c98-ba74-1350b138c35c', 'alice', 'ACCEPTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '791 hours 58 minutes'),
  ('82bfc03d-d284-48c8-bc67-896d81488d32', '8d8f0e3f-36af-4244-b88c-4d27f9c1621a', 'diana', 'REJECTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '104 hours 36 minutes'),
  ('91dc9b87-5106-4cdc-9576-9dbbe9eecdfd', '016cd551-6289-4b1f-a2e2-279e2efc98aa', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '546 hours 22 minutes'),
  ('4babf3fd-7230-4a44-a5dd-494c9bb28ebb', '111abef1-1fb8-40e5-9282-213a6671df4f', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '972 hours 36 minutes'),
  ('ced99ccd-40cb-4a12-83e2-f19e605d81f9', '2791fb05-f51e-40de-b50f-5c9abd67cb0b', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '320 hours 40 minutes'),
  ('7f018a3d-4806-4fc1-b642-af00f41342df', 'eb07bdcf-15a9-4104-9c50-9b25854e0ace', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '99 hours 24 minutes'),
  ('8ca3b05c-5e3c-4c15-b51f-5f69fb253be3', '19fa1cac-314c-4b44-9750-8bd3dc108ae3', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '351 hours 21 minutes'),
  ('edbdf76d-f84a-478b-90fb-86437d880c38', 'deb961b6-74f6-441f-a4c5-71e6476f3210', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '107 hours 5 minutes'),
  ('57ad33f2-6927-4810-a4bc-e3d3c0aab155', '580226ef-cd30-49c3-852c-9634e6c78e4e', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '578 hours 46 minutes'),
  ('29afb02c-8db6-4c14-827f-f52326ecc58b', '45585212-080d-41d1-89f0-afc66956e1a9', 'diana', 'ACCEPTED', 'Re-opened: bot rejection did not match the issue acceptance criteria.', NOW() - INTERVAL '536 hours 12 minutes'),
  ('67516c05-a74f-4cc0-9d54-4afbd8508d65', '8859c240-4418-4321-8a12-d58cc6ccefeb', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '345 hours 45 minutes'),
  ('29e9888b-6bc7-4231-b1ad-d93215d0f462', 'bb2e3ac1-490e-478d-827a-2d91f9881fd3', 'charlie', 'REJECTED', NULL, NOW() - INTERVAL '976 hours 31 minutes'),
  ('77bee0f8-e9b7-41f3-9593-0a414cbdb335', 'f26c6aa5-68bd-4e58-89dd-717e15a61d0e', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '794 hours 23 minutes'),
  ('bbe27345-97f9-40ec-9afe-a16f816c0d1d', 'e30d8761-c948-4ef9-9456-a0957cd4e36c', 'alice', 'REJECTED', NULL, NOW() - INTERVAL '987 hours 28 minutes'),
  ('fad9bd59-fb9b-4ed3-b94e-90cbbb415f23', 'e8990c02-72bb-4c4a-ae4d-c325355f6afa', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '550 hours 37 minutes'),
  ('6c384a7d-228e-4a33-83b8-9ba50a25753c', '1d418f4e-128a-4650-9d39-23af898f310e', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '996 hours 40 minutes'),
  ('70be36f8-a0ee-4655-ae4d-d104dd6ffb5f', '5e5720b6-68bc-4bc9-84e0-e803ee09176e', 'security-bot', 'REJECTED', NULL, NOW() - INTERVAL '788 hours 45 minutes'),
  ('06c1aeff-b081-4f84-9216-7749d0eb272f', '3ccb922c-9ccb-46a2-b551-fe3caafe502d', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '593 hours 7 minutes'),
  ('1e0264fd-5536-4db1-aead-3bc072707a4f', '6b8f1c10-2b68-4c09-a34b-c6765febadd4', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '805 hours 8 minutes'),
  ('b3626a6b-b110-4aa4-9b22-aca7732efe77', '3efaf821-e45d-40f4-a3ee-54682c31503c', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '1041 hours 10 minutes'),
  ('b4762269-d814-4777-96e8-85a2b9564259', 'c1e00182-efd3-4050-8c72-a06a67fbcb4f', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '383 hours 12 minutes'),
  ('995c856f-5640-44d2-b68f-8f616dfbcac7', '201fbf60-9986-4143-87d6-eef818e3eec8', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '373 hours 34 minutes'),
  ('0d7f859d-4c9c-4065-8801-f8f75cc3c02e', '804138d2-0e5c-4f27-9541-a0d77916d6ac', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '1023 hours 15 minutes'),
  ('e7ba05e1-1dfc-4d16-9853-935b0af84dad', '284f9ff3-5bc0-4463-8187-a9bb05e8a9d3', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '792 hours 24 minutes'),
  ('74d51387-ba62-4580-816d-8f0f3e3d5a9f', 'bada54ec-036a-47c2-8f2d-e3687cb6a4e6', 'alice', 'ACCEPTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '133 hours 42 minutes'),
  ('7ec4bfec-86c4-49e5-9cb7-829d5d446d20', '64fe9093-e3b4-409a-a0ff-cb2c1cdb30a8', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '603 hours 2 minutes'),
  ('1e0cb41c-851d-45f2-ad75-188ded031431', 'ef8fe679-05be-4f7c-9810-85745442788a', 'bob', 'REJECTED', 'Security bot false positive: the dependency bump is within the allowed policy window.', NOW() - INTERVAL '558 hours 28 minutes'),
  ('f70b8651-16d4-41af-b4cc-14500040fb25', 'aba53aa3-720c-4b11-ac03-9f0b2bbbb6f5', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '372 hours 31 minutes'),
  ('e06b8864-c95c-4fd1-bd50-19c2cc78fe22', '0fdff30b-a25a-4cfb-bb6f-c7d8543457fc', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '145 hours 26 minutes'),
  ('7aa5db9f-3f65-492b-bacf-b83978fc5c29', '8cefa26b-bc40-4bae-bb61-00752cef5f55', 'diana', 'REJECTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '793 hours 33 minutes'),
  ('a06bc235-2b50-4077-909d-f9241b3b35ab', '4504b2bf-0b5f-48c8-b6c8-875fe1c9df33', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '582 hours 32 minutes'),
  ('a4fa2bb2-5963-425d-af5d-85252afa41ba', '74bf1aaa-8149-4e4c-b174-0c0d788737e4', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '1021 hours 18 minutes'),
  ('cb370a55-eb19-43a3-b631-502d7d2e8d03', '3d2e0ce1-d7e5-4558-af69-902ec8b4a4b0', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '166 hours 59 minutes'),
  ('516a5ab8-44de-487b-b411-74ed7f15b371', 'ef8f7aa1-5270-4763-9cda-972bb133c49b', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '143 hours 19 minutes'),
  ('fd799cc4-30d2-409f-b276-0af773c457bd', '17d490f4-1fd8-42c1-bfd9-16624388a4f3', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '1013 hours 13 minutes'),
  ('5bce54c6-6604-400c-b277-d0de5cf33293', '5bb46a32-1cbb-44c3-ae92-8367e7bd6e4b', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '810 hours 28 minutes'),
  ('665c693f-8e30-434c-8b96-75cd47e5d2a5', '9d8685d4-1b97-4a6c-a73f-737b41d462c0', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '167 hours 11 minutes'),
  ('c16cf743-116e-4798-ae1c-25085736005a', '2c8c72b3-1c8f-418b-a3b9-274a626b8ab4', 'ci-review-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '826 hours 2 minutes'),
  ('7dadcfc6-8f1d-4a5c-958d-90351e1b6784', '8f8db02e-0b37-4a91-a556-c1eb0fd20269', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '626 hours 15 minutes'),
  ('add51003-3abb-4925-9263-26f373807918', '155f1eb6-63bf-48c3-be24-0b3156859e95', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '175 hours 5 minutes'),
  ('f92afd28-d9c8-439b-ab53-f161689f4a95', 'd14d1d49-be37-43c3-b125-601336a9a411', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '176 hours'),
  ('96c403a0-a5fa-4d19-9c6f-02cae1c81a0c', '0e5828a2-b47f-4fc2-9cfc-7abdd46c48b1', 'diana', 'ACCEPTED', NULL, NOW() - INTERVAL '393 hours 33 minutes'),
  ('31f45cc0-1814-4c56-8a46-51fc20d25e70', '99276811-ceac-440a-94e3-8b601757c963', 'bob', 'ACCEPTED', NULL, NOW() - INTERVAL '800 hours 37 minutes'),
  ('d3be43f4-7af3-4473-8fb7-65dcf3ac6c18', '54e9c95b-2682-42df-9a49-00451dc7f98e', 'alice', 'ACCEPTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '598 hours 16 minutes'),
  ('25a324b2-6626-4273-b3c9-81167b9cbcff', 'df7c3f04-3796-46a2-8da5-a36ef81a9baf', 'alice', 'REJECTED', 'Bot flagged a flaky test as the cause; manually verified the test passes in isolation.', NOW() - INTERVAL '1040 hours 9 minutes'),
  ('e3943818-9b74-4220-be00-d69c49de452b', '54a49233-39a0-4d82-890e-a2e29c503b84', 'alice', 'ACCEPTED', 'Hotfix approved manually despite the coverage drop.', NOW() - INTERVAL '189 hours 30 minutes'),
  ('be8a4bbd-f7a6-4c4b-b4e9-2941a1e96b34', '7013259b-9952-49ac-b403-61cdadd20f54', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '1033 hours 53 minutes'),
  ('6352dff1-be4b-43d0-b17a-229e79d0f230', '3bad755d-71fb-4c98-a490-9db6858eca8b', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '1030 hours 25 minutes'),
  ('cbfbc185-c195-42e8-8d3c-d44648ddbb76', '46643917-7328-41a8-873e-400c589fffc3', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '600 hours 13 minutes'),
  ('3ea6dbcf-b62c-4262-9feb-3ddb50ac7d45', 'bd86e01e-e993-4a02-b6a0-2b254bed3db0', 'alice', 'ACCEPTED', NULL, NOW() - INTERVAL '622 hours 37 minutes'),
  ('b28041ca-bdae-41a2-96ff-471cce3c7404', 'f65d309f-0f1b-476e-91f3-f0642b19e7bc', 'charlie', 'ACCEPTED', NULL, NOW() - INTERVAL '405 hours 35 minutes'),
  ('690874f7-43db-485c-bee4-8e38bf419e0e', '86e7fbc0-700e-49b3-a5e9-dc5442c39e10', 'security-bot', 'ACCEPTED', NULL, NOW() - INTERVAL '822 hours 14 minutes');
