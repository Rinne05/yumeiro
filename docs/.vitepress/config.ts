import { existsSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'
import type { DefaultTheme } from 'vitepress'
import { docsBase } from '../scripts/base.mjs'

const base = docsBase()
const generated = new URL('../.generated/', import.meta.url)
const recordedBase = new URL('base.txt', generated)
const favicon = readFileSync(new URL('./theme/favicon.png', import.meta.url), 'base64')
if (!existsSync(recordedBase) || readFileSync(recordedBase, 'utf8') !== base) {
  throw new Error('请使用相同的 YUMEIRO_DOCS_BASE 执行 npm run generate，再启动或构建文档站。')
}

const guides: DefaultTheme.SidebarItem[] = [
  {
    text: '指南',
    items: [
      { text: '开始使用', link: '/guide/getting-started' },
      { text: '主题与预设', link: '/guide/theming' },
      { text: '视觉角色与令牌', link: '/guide/visual-roles' },
      { text: '材质与玻璃', link: '/guide/materials' },
      { text: '响应式与输入方式', link: '/guide/adaptive' },
      { text: '本地化与字体图标', link: '/guide/localization' },
    ],
  },
]

const components: DefaultTheme.SidebarItem[] = [
  { text: '组件目录', link: '/components/' },
  {
    text: '控件',
    base: '/components/',
    items: [
      { text: '按钮', link: 'buttons' },
      { text: '文本与标签输入', link: 'inputs' },
      { text: '选择控件', link: 'selection' },
      { text: '表单控件', link: 'form-controls' },
      { text: '数值与评分', link: 'sliders' },
      { text: '颜色选择', link: 'color-picker' },
    ],
  },
  {
    text: '展示',
    base: '/components/',
    items: [
      { text: '状态与反馈', link: 'display' },
      { text: '媒体', link: 'media' },
    ],
  },
  {
    text: '布局',
    base: '/components/',
    items: [
      { text: '页面与容器', link: 'layout' },
      { text: '列表与设置行', link: 'rows' },
      { text: '数据表', link: 'data-table' },
      { text: '数据表紧凑变体', link: 'compact-table' },
    ],
  },
  {
    text: '导航',
    base: '/components/',
    items: [
      { text: '导航与切页', link: 'navigation' },
      { text: '工具栏与全局搜索', link: 'toolbars' },
    ],
  },
  {
    text: '浮层',
    base: '/components/',
    items: [
      { text: '对话框与编辑器', link: 'dialogs' },
      { text: '底部与选择面板', link: 'sheets' },
      { text: '上下文菜单与提示', link: 'menus' },
      { text: '通知', link: 'toasts' },
    ],
  },
]

export default defineConfig({
  base,
  lang: 'zh-CN',
  title: 'Yumeiro',
  description: 'Yumeiro Flutter 组件、主题和材质的使用指南与 API 参考。',
  head: [['link', { rel: 'icon', type: 'image/png', href: `data:image/png;base64,${favicon}` }]],
  cleanUrls: false,
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: '指南', link: '/guide/getting-started', activeMatch: '/guide/' },
      { text: '组件', link: '/components/', activeMatch: '/components/' },
      { text: 'API 参考', link: '/api/index.html', target: '_blank' },
      { text: '维护文档', link: '/contributing' },
    ],
    sidebar: {
      '/guide/': guides,
      '/components/': components,
    },
    search: {
      provider: 'local',
      options: {
        miniSearch: {
          options: {
            tokenize: (text) => Array.from(new Intl.Segmenter('zh-CN', { granularity: 'word' }).segment(text))
              .filter((word) => word.isWordLike)
              .map((word) => word.segment),
          },
        },
        translations: {
          button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
          modal: {
            displayDetails: '显示详细列表',
            resetButtonTitle: '清除搜索',
            backButtonTitle: '返回',
            noResultsText: '未找到结果',
            footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' },
          },
        },
      },
    },
    outline: { level: [2, 3], label: '本页目录' },
    docFooter: { prev: '上一页', next: '下一页' },
    lastUpdated: { text: '最后更新' },
    darkModeSwitchLabel: '外观',
    skipToContentLabel: '跳到正文',
    sidebarMenuLabel: '文档菜单',
    returnToTopLabel: '返回顶部',
    footer: { message: 'MIT 许可证', copyright: 'Copyright © 2026 Rinne05' },
  },
  vite: { publicDir: fileURLToPath(new URL('public/', generated)) },
})
