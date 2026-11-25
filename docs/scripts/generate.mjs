import { spawnSync } from 'node:child_process'
import { mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { docsBase } from './base.mjs'

const root = fileURLToPath(new URL('../../', import.meta.url))
const example = fileURLToPath(new URL('../../example/', import.meta.url))
const generated = new URL('../.generated/', import.meta.url)
const api = new URL('public/api/', generated)
const base = docsBase()

function run(tool, args, cwd) {
  const result = spawnSync(tool, args, {
    cwd,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  })
  if (result.error) throw result.error
  if (result.status !== 0) {
    throw new Error(`${tool} ${args.join(' ')} 执行失败（${result.status ?? result.signal}）。`)
  }
}

mkdirSync(new URL('public/', generated), { recursive: true })
rmSync(new URL('base.txt', generated), { force: true })

run('flutter', ['pub', 'get'], root)
rmSync(api, { recursive: true, force: true })
run('dart', ['doc', '--validate-links', '--output=docs/.generated/public/api'], root)

run('flutter', [
  'build', 'web', '--release', '--target=lib/main_docs.dart',
  `--base-href=${base}preview/`, '--no-web-resources-cdn',
  '--output=../docs/.generated/public/preview',
], example)

writeFileSync(new URL('base.txt', generated), base)
