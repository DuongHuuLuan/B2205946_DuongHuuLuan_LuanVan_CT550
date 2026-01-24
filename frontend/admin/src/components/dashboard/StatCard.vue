<template>
  <div class="card card-soft h-100">
    <div class="card-body">
      <div class="d-flex align-items-start justify-content-between">
        <div>
          <div class="small opacity-75">{{ label }}</div>
          <div class="fs-4 fw-bold">{{ value }}</div>
        </div>

        <div class="icon-box">
          <i :class="icon"></i>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  label: String,
  value: [String, Number],
  icon: { type: String, default: "fa-solid fa-chart-line" },
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}
.icon-box {
  width: 44px;
  height: 44px;
  border-radius: 0.9rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: color-mix(in srgb, var(--main-color) 16%, transparent);
  color: var(--main-color);
}
</style>
