import { execSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')

export const backendUrl = `http://localhost:${process.env.BACKEND_PORT ?? '8080'}`
export const frontendUrl = `http://localhost:${process.env.FRONTEND_PORT ?? '5173'}`

async function waitFor(url: string, predicate: (response: Response) => Promise<boolean>, timeoutMs: number) {
  const deadline = Date.now() + timeoutMs
  let lastError = ''
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url)
      if (response.ok && (await predicate(response))) return
    } catch (error) {
      lastError = String(error)
    }
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 3000))
  }
  throw new Error(`Timed out waiting for ${url}: ${lastError}`)
}

export default async function globalSetup() {
  // Boot the full stack; Flyway applies migrations and the seed data on
  // first backend startup. Volumes are wiped afterwards in global-teardown.
  execSync('docker compose -f infra/docker-compose.yml down -v --remove-orphans', {
    cwd: ROOT,
    stdio: 'inherit',
  })
  execSync('docker compose -f infra/docker-compose.yml up -d --build', {
    cwd: ROOT,
    stdio: 'inherit',
    env: {
      ...process.env,
      BACKEND_PORT: process.env.BACKEND_PORT ?? '8080',
      FRONTEND_PORT: process.env.FRONTEND_PORT ?? '5173',
    },
  })

  await waitFor(`${backendUrl}/actuator/health`, async (response) => {
    const body = (await response.json()) as { status?: string }
    return body.status === 'UP'
  }, 300_000)
  await waitFor(frontendUrl, async () => true, 60_000)
  // Wait until the full nginx -> backend proxy chain serves API responses,
  // not just static files; guards against a boot-time network race.
  await waitFor(`${frontendUrl}/api/variants`, async (response) => {
    const body = (await response.json()) as unknown
    return Array.isArray(body)
  }, 120_000)
}
