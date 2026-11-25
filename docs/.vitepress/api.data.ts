import { readFileSync } from 'node:fs'
import { extname } from 'node:path'

interface DartdocEntry {
  name: string
  qualifiedName: string
  href: string
  enclosedBy?: { name: string; href: string }
}

const libraryPrefix = 'yumeiro.'
const apiLink = /<ApiLink\s+symbol=(['"])([^'"]+)\1/g

export default {
  watch: [
    '../.generated/public/api/index.json',
    '../*.md',
    '../guide/**/*.md',
    '../components/**/*.md',
  ],
  load(files: string[]) {
    const indexPath = files.find((path) => extname(path) === '.json')
    if (!indexPath) throw new Error('请先生成 Dartdoc 的 API 索引。')

    // Send top-level names and the members cited by the site to the browser.
    const cited = new Set<string>()
    for (const path of files.filter((path) => extname(path) === '.md')) {
      for (const match of readFileSync(path, 'utf8').matchAll(apiLink)) {
        cited.add(match[2])
      }
    }

    const index: DartdocEntry[] = JSON.parse(readFileSync(indexPath, 'utf8'))
    const links: Record<string, string> = Object.create(null)
    for (const entry of index) {
      if (!entry.qualifiedName.startsWith(libraryPrefix)) continue
      const qualified = entry.qualifiedName.slice(libraryPrefix.length)
      // Dartdoc prefixes named constructors with the enclosing type twice.
      const owner = entry.enclosedBy?.name
      const symbol = owner && entry.name.startsWith(`${owner}.`) && qualified === `${owner}.${entry.name}`
        ? entry.name
        : qualified
      if (entry.enclosedBy?.href === 'yumeiro/' || cited.has(symbol)) {
        links[symbol] = entry.href
      }
    }
    return links
  },
}
