import { execSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')

export default async function globalTeardown() {
  // Tear the stack down and wipe the data volume so the next run starts from
  // a clean seed.
  execSync('docker compose -f infra/docker-compose.yml down -v --remove-orphans', {
    cwd: ROOT,
    stdio: 'inherit',
  })
}
