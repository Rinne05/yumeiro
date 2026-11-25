import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import ApiLink from './ApiLink.vue'
import ComponentDemo from './ComponentDemo.vue'
import './style.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('ApiLink', ApiLink)
    app.component('ComponentDemo', ComponentDemo)
  },
} satisfies Theme
