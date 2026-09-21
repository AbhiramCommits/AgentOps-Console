// Captures the three README screenshots from a running compose stack.
// Usage: boot the stack, load the demo seed, then:
//   FRONTEND_URL=http://localhost:5173 node screenshot.mjs
import { mkdir } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { chromium } from '@playwright/test'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const OUT_DIR = resolve(ROOT, 'docs', 'screenshots')
const baseURL = process.env.FRONTEND_URL ?? 'http://localhost:5173'

async function main() {
  await mkdir(OUT_DIR, { recursive: true })
  const browser = await chromium.launch()
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } })

  // 1. Runs list
  await page.goto(`${baseURL}/`)
  await page.getByRole('table').waitFor({ state: 'visible' })
  await page.getByRole('heading', { name: 'Agent Runs' }).waitFor()
  await page.waitForTimeout(1200)
  await page.screenshot({ path: resolve(OUT_DIR, 'runs-list.png'), fullPage: true })

  // 2. Run detail with an expanded side-by-side diff
  await page.locator('table tbody tr td a').first().click()
  await page.locator('details').first().waitFor()
  await page.locator('details summary').first().click()
  await page.locator('details[open]').waitFor()
  await page.waitForTimeout(800)
  await page.screenshot({ path: resolve(OUT_DIR, 'run-detail.png'), fullPage: true })

  // 3. Live metrics charts
  await page.goto(`${baseURL}/metrics`)
  await page.getByText('Acceptance rate per day').waitFor()
  await page.getByText('Cost per day').waitFor()
  await page.waitForTimeout(1500)
  await page.screenshot({ path: resolve(OUT_DIR, 'metrics.png'), fullPage: true })

  await browser.close()
  console.log(`Screenshots written to ${OUT_DIR}`)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
