import { expect, test, type APIRequestContext } from '@playwright/test'
import { backendUrl } from '../global-setup'

interface AcceptanceBucket {
  variantId: string
  accepted: number
  total: number
}

async function variantAcceptance(request: APIRequestContext, variantId: string) {
  const response = await request.get(`${backendUrl}/api/metrics/acceptance?bucket=week`)
  expect(response.ok()).toBeTruthy()
  const buckets = (await response.json()) as AcceptanceBucket[]
  return buckets
    .filter((bucket) => bucket.variantId === variantId)
    .reduce(
      (acc, bucket) => ({ accepted: acc.accepted + bucket.accepted, total: acc.total + bucket.total }),
      { accepted: 0, total: 0 },
    )
}

test('rejecting a patch lowers the variant acceptance rate on /metrics', async ({ page, request }) => {
  // Open the runs list and pick a run.
  await page.goto('/')
  await expect(page.getByRole('table')).toBeVisible()
  await page.locator('table tbody tr td a').first().click()

  // Resolve the run's variant via the API so we can compare before/after.
  const runId = new URL(page.url()).pathname.split('/').pop() ?? ''
  const runResponse = await request.get(`${backendUrl}/api/runs/${runId}`)
  expect(runResponse.ok()).toBeTruthy()
  const runDetail = (await runResponse.json()) as { run: { variantId: string } }
  const variantId = runDetail.run.variantId

  const before = await variantAcceptance(request, variantId)
  expect(before.total).toBeGreaterThan(0)
  expect(before.accepted).toBeGreaterThan(0)
  const rateBefore = before.accepted / before.total

  // Pick a patch that is not already rejected and reject it with a reason.
  // The patch is pinned by index: a hasNot("Rejected") locator would re-resolve
  // to another element once the optimistic update flips this one.
  await expect(page.locator('details').first()).toBeVisible()
  const patchItems = page.locator('details')
  const count = await patchItems.count()
  let targetIndex = -1
  for (let i = 0; i < count; i += 1) {
    const text = await patchItems.nth(i).innerText()
    if (!text.includes('Rejected')) {
      targetIndex = i
      break
    }
  }
  expect(targetIndex).toBeGreaterThanOrEqual(0)
  const patch = patchItems.nth(targetIndex)
  await patch.getByRole('button', { name: 'Reject' }).click()

  const dialog = page.getByRole('dialog')
  await expect(dialog).toBeVisible()
  await dialog.getByLabel(/Override reason/).fill('E2E: the diff causes a flaky test')
  await dialog.getByRole('button', { name: 'Reject patch' }).click()
  await expect(patch.getByText('Rejected', { exact: true })).toBeVisible()

  // The variant's acceptance rate must drop once the rejection lands.
  await expect
    .poll(
      async () => {
        const after = await variantAcceptance(request, variantId)
        return after.total > 0 ? after.accepted / after.total : null
      },
      { message: 'acceptance rate should drop after rejecting a patch' },
    )
    .toBeLessThan(rateBefore)

  // The live metrics page renders the acceptance chart and a fresh timestamp.
  await page.goto('/metrics')
  await expect(page.getByText('Acceptance rate per day')).toBeVisible()
  await expect(page.getByText(/Updated|Updating/)).toBeVisible()
})
