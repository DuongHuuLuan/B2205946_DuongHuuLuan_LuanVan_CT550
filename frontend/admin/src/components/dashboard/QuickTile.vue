<template>
  <button class="btn tile w-100 text-start" disabled>
    <div class="d-flex align-items-center gap-2">
      <i :class="icon + ' fs-5'"></i>
      <div>
        <div class="fw-semibold">{{ title }}</div>
        <div class="small opacity-75">{{ desc }}</div>
      </div>
    </div>
  </button>
</template>

<script setup>
defineProps({
  title: String,
  desc: String,
  icon: String,
});
</script>

<style scoped>
.tile {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
  padding: 1rem;
}
.tile:hover {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}
</style>
