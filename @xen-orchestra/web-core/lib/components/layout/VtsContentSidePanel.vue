<template>
  <div
    class="vts-content-side-panel"
    :class="{
      mobile: uiStore.isSmall,
      locked: panelStore.isLocked && !uiStore.isSmall,
      'has-panel-column': hasPanelColumn,
    }"
  >
    <slot />
  </div>
</template>

<script setup lang="ts">
import { usePanelStore } from '@core/stores/panel.store'
import { useUiStore } from '@core/stores/ui.store'
import { computed } from 'vue'

const panelStore = usePanelStore()
const uiStore = useUiStore()

const hasPanelColumn = computed(() => (panelStore.isLocked || panelStore.isExpanded) && !uiStore.isSmall)
</script>

<style scoped lang="postcss">
.vts-content-side-panel {
  --side-panel-width: 40rem;

  &:not(.mobile) {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 0;
    overflow: hidden;
    transition: grid-template-columns 0.25s;

    &.has-panel-column {
      grid-template-columns: minmax(0, 1fr) var(--side-panel-width);
    }
  }
}
</style>
