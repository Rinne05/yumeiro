export function docsBase() {
  const base = process.env.YUMEIRO_DOCS_BASE ?? '/'
  if (!/^\/(?:[A-Za-z0-9][A-Za-z0-9._-]*\/)*$/.test(base)) {
    throw new Error('YUMEIRO_DOCS_BASE 必须是以斜线开头和结尾的网址路径，例如 /yumeiro/。')
  }
  return base
}
