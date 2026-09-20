import { parseUnifiedDiff, toSideBySideRows } from './diff'

const SAMPLE = `diff --git a/src/services/checkout.ts b/src/services/checkout.ts
index ab12cd34..ef56ab78 100644
--- a/src/services/checkout.ts
+++ b/src/services/checkout.ts
@@ -12,7 +12,9 @@ export async function createSession(items: CartItem[], attempt = 0) {
   const response = await fetch(\`\${API_BASE}/v1/checkout\`, {
     method: 'POST',
   });
+
+  if (response.status === 429 && attempt < 3) {
+    return createSession(items, attempt + 1);
+  }
   if (!response.ok) {
     throw new CheckoutError('failed');
   }
`

describe('parseUnifiedDiff', () => {
  it('skips file headers and parses one hunk with line numbers', () => {
    const parsed = parseUnifiedDiff(SAMPLE)
    expect(parsed.hunks).toHaveLength(1)
    const hunk = parsed.hunks[0]
    expect(hunk.header).toBe('@@ -12,7 +12,9 @@ export async function createSession(items: CartItem[], attempt = 0) {')
    expect(hunk.lines).toHaveLength(10)

    expect(hunk.lines[0]).toEqual({
      type: 'context',
      text: '  const response = await fetch(`${API_BASE}/v1/checkout`, {',
      oldLine: 12,
      newLine: 12,
    })
    expect(hunk.lines[3]).toMatchObject({ type: 'added', oldLine: null, newLine: 15 })
    expect(hunk.lines[3].text).toBe('')
    expect(hunk.lines[4].text).toBe('  if (response.status === 429 && attempt < 3) {')
    expect(hunk.lines[5]).toMatchObject({ type: 'added', newLine: 17 })
    expect(hunk.lines[7]).toMatchObject({ type: 'context', oldLine: 15, newLine: 19 })
  })

  it('tracks removed lines on the old side only', () => {
    const parsed = parseUnifiedDiff(
      '@@ -1,3 +1,2 @@\n keep\n-removed\n-lost\n+added\n',
    )
    const lines = parsed.hunks[0].lines
    expect(lines[1]).toMatchObject({ type: 'removed', oldLine: 2, newLine: null })
    expect(lines[2]).toMatchObject({ type: 'removed', oldLine: 3, newLine: null })
    expect(lines[3]).toMatchObject({ type: 'added', oldLine: null, newLine: 2 })
  })

  it('treats input without a hunk header as context', () => {
    const parsed = parseUnifiedDiff('just some text\nsecond line\n')
    expect(parsed.hunks).toHaveLength(1)
    expect(parsed.hunks[0].lines[0]).toMatchObject({ type: 'context', text: 'just some text' })
  })
})

describe('toSideBySideRows', () => {
  it('emits removed lines on the left and added lines on the right', () => {
    const parsed = parseUnifiedDiff('@@ -1,2 +1,2 @@\n ctx\n-removed\n+added\n')
    const rows = toSideBySideRows(parsed)

    expect(rows[0].hunkHeader).toBe('@@ -1,2 +1,2 @@')
    expect(rows[1].left?.type).toBe('context')
    expect(rows[1].right?.type).toBe('context')
    expect(rows[2].left?.type).toBe('removed')
    expect(rows[2].right).toBeNull()
    expect(rows[3].left).toBeNull()
    expect(rows[3].right?.type).toBe('added')
  })
})
