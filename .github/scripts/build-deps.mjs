// Build a workspace and its workspace dependencies in dependency order,
// without turbo (turbo ships no riscv64 binary). Keeps going on failure
// and prints one line per package, so a run maps every broken build.
// Usage: node .github/scripts/build-deps.mjs <workspace-name>...
import { execFileSync, spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

const raw = execFileSync('yarn', ['--silent', 'workspaces', 'info', '--json'], { encoding: 'utf8' })
const info = JSON.parse(raw.slice(raw.indexOf('{')))

const order = []
const seen = new Set()
const visit = name => {
  if (seen.has(name)) return
  seen.add(name)
  if (info[name] === undefined) throw new Error(`unknown workspace: ${name}`)
  for (const dep of info[name].workspaceDependencies) visit(dep)
  order.push(name)
}
process.argv.slice(2).forEach(visit)

let failed = 0
for (const name of order) {
  const { location } = info[name]
  const pkg = JSON.parse(readFileSync(join(location, 'package.json'), 'utf8'))
  if (pkg.scripts?.build === undefined) continue
  const start = Date.now()
  const { status } = spawnSync('yarn', ['--cwd', location, 'run', 'build'], { stdio: 'inherit' })
  const secs = Math.round((Date.now() - start) / 1000)
  console.log(`BUILD ${status === 0 ? 'ok  ' : 'FAIL'} ${name} (${secs}s)`)
  if (status !== 0) failed++
}
console.log(`${order.length} workspaces in closure, ${failed} build(s) failed`)
process.exitCode = failed === 0 ? 0 : 1
