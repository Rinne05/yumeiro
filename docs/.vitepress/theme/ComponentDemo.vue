<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useData, withBase } from 'vitepress'

const props = withDefaults(defineProps<{
  id: string
  title: string
  overlayHeight?: number
  inputModes?: boolean
  compactTouch?: boolean
  themeStyles?: boolean
}>(), { overlayHeight: 420 })

type Tab = 'preview' | 'code'

const { isDark } = useData()
const tab = ref<Tab>('preview')
const previewTab = ref<HTMLButtonElement>()
const codeTab = ref<HTMLButtonElement>()
const iframe = ref<HTMLIFrameElement>()
const mounted = ref(false)
const ready = ref(false)
const height = ref(160)
const modality = ref('auto')
const preset = ref('classic')
const prefix = computed(() => `demo-${props.id}`)
const query = computed(() => {
  const params = new URLSearchParams({ demo: props.id, locale: 'zh' })
  if (mounted.value) params.set('theme', isDark.value ? 'dark' : 'light')
  if (modality.value !== 'auto') params.set('modality', modality.value)
  if (props.themeStyles && preset.value !== 'classic') params.set('preset', preset.value)
  return params
})
const standaloneUrl = computed(() => withBase(`/preview/index.html?${query.value}`))
const previewUrl = computed(() => {
  const params = new URLSearchParams(query.value)
  params.set('embedded', '1')
  params.set('overlayHeight', String(props.overlayHeight))
  return withBase(`/preview/index.html?${params}`)
})

function resizePreview(event: MessageEvent) {
  if (event.origin !== window.location.origin || event.source !== iframe.value?.contentWindow) return
  const size = event.data
  if (size?.type !== 'yumeiro.previewSize' || !Number.isFinite(size.height) || size.height <= 0) return

  height.value = Math.ceil(size.height)
  ready.value = true
}

watch(previewUrl, () => { ready.value = false })

onMounted(() => {
  window.addEventListener('message', resizePreview)
  mounted.value = true
})
onBeforeUnmount(() => window.removeEventListener('message', resizePreview))

async function onTabKey(event: KeyboardEvent) {
  switch (event.key) {
    case 'Home': tab.value = 'preview'; break
    case 'End': tab.value = 'code'; break
    case 'ArrowLeft':
    case 'ArrowRight': tab.value = tab.value === 'preview' ? 'code' : 'preview'; break
    default: return
  }
  event.preventDefault()
  await nextTick()
  const button = tab.value === 'preview' ? previewTab.value : codeTab.value
  button?.focus()
}
</script>

<template>
  <div class="component-demo">
    <div class="demo-header">
      <div class="demo-tabs" role="tablist" :aria-label="title" @keydown="onTabKey">
        <button
          :id="`${prefix}-preview-tab`"
          ref="previewTab"
          type="button"
          role="tab"
          :aria-controls="`${prefix}-preview-panel`"
          :aria-selected="tab === 'preview'"
          :tabindex="tab === 'preview' ? 0 : -1"
          @click="tab = 'preview'"
        >预览</button>
        <button
          :id="`${prefix}-code-tab`"
          ref="codeTab"
          type="button"
          role="tab"
          :aria-controls="`${prefix}-code-panel`"
          :aria-selected="tab === 'code'"
          :tabindex="tab === 'code' ? 0 : -1"
          @click="tab = 'code'"
        >代码</button>
      </div>
      <div class="demo-actions">
        <select v-if="themeStyles" v-model="preset" aria-label="预览主题">
          <option value="classic">经典</option>
          <option value="glass">液态玻璃</option>
          <option value="pixel">复古像素</option>
        </select>
        <select v-if="inputModes" v-model="modality" aria-label="预览输入方式">
          <option value="auto">自动布局</option>
          <option value="pointer">指针</option>
          <option value="touch">触控</option>
        </select>
        <a :href="standaloneUrl" target="_blank" rel="noopener">独立打开</a>
      </div>
    </div>
    <div
      :id="`${prefix}-preview-panel`"
      v-show="tab === 'preview'"
      class="demo-preview"
      :class="{ 'demo-preview-compact': compactTouch && modality === 'touch' }"
      role="tabpanel"
      :aria-labelledby="`${prefix}-preview-tab`"
      :style="{ height: `${height}px` }"
    >
      <iframe v-if="mounted" ref="iframe" :src="previewUrl" :title="title" :height="height" loading="lazy" />
      <p v-if="!ready" class="demo-loading" role="status">加载 Flutter 预览…</p>
    </div>
    <div
      :id="`${prefix}-code-panel`"
      v-show="tab === 'code'"
      class="demo-code"
      role="tabpanel"
      :aria-labelledby="`${prefix}-code-tab`"
      tabindex="0"
    >
      <slot />
    </div>
  </div>
</template>

<style scoped>
.component-demo {
  margin: 24px 0;
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  overflow: hidden;
}

.demo-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 4px 12px;
  padding: 0 12px;
  border-bottom: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
}

.demo-header a { font-size: 14px; }

.demo-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  min-height: 36px;
}

.demo-actions select {
  appearance: auto;
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  padding: 3px 5px;
  color: var(--vp-c-text-1);
  background: var(--vp-c-bg);
  font-size: 14px;
}

.demo-tabs { display: flex; }

.demo-tabs button {
  min-height: 44px;
  padding: 0 12px;
  border-bottom: 2px solid transparent;
  color: var(--vp-c-text-2);
  font-size: 14px;
  font-weight: 600;
}

.demo-tabs button[aria-selected='true'] {
  border-color: var(--vp-c-brand-1);
  color: var(--vp-c-brand-1);
}

.demo-tabs button:focus-visible,
.demo-code:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: -3px;
}

.demo-preview {
  position: relative;
  background: var(--vp-c-bg-soft);
}

.demo-preview iframe {
  display: block;
  width: 100%;
  border: 0;
}

.demo-preview-compact iframe {
  max-width: 390px;
  margin-inline: auto;
}

.demo-preview .demo-loading {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  margin: 0;
  background: var(--vp-c-bg-soft);
  color: var(--vp-c-text-2);
  font-size: 14px;
}

.demo-code :deep(div[class*='language-']) {
  margin: 0;
  border-radius: 0;
}
</style>
