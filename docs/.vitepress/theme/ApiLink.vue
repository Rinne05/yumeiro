<script setup lang="ts">
import { computed } from 'vue'
import { withBase } from 'vitepress'
import { data as apiLinks } from '../api.data'

const props = defineProps<{ symbol?: string }>()
const href = computed(() => {
  if (!props.symbol) return withBase('/api/index.html')
  const path = (apiLinks as Record<string, string>)[props.symbol]
  if (!path) throw new Error(`找不到 Dartdoc API「${props.symbol}」。请核对公开名称并重新生成接口文档。`)
  return withBase(`/api/${path}`)
})
</script>

<template>
  <a :href="href" target="_blank" rel="noopener"><code v-if="symbol">{{ symbol }}</code><template v-else>API 参考</template></a>
</template>
