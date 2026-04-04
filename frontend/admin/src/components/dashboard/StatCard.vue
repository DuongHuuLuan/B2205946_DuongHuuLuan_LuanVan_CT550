<template>
  <div class="card card-soft h-100">
    <div class="card-body">
      <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="stats-label mb-0">{{ label }}</div>
        <div class="icon-box">
          <i :class="icon"></i>
        </div>
      </div>

      <div v-if="displayLines.length" class="stats-lines">
        <div v-for="line in displayLines" :key="line" class="value-line">{{ line }}</div>
      </div>
      <div v-else class="stats-value">
        <span class="value-number">{{ formatValue(value).number }}</span>
        <span class="value-unit">{{ formatValue(value).unit }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  label: String,
  value: [String, Number],
  icon: String,
  lines: {
    type: Array,
    default: () => [],
  },
});

const displayLines = computed(() =>
  Array.isArray(props.lines)
    ? props.lines
      .map((line) => String(line || "").trim())
      .filter(Boolean)
    : [],
);

const formatValue = (val) => {
  if (!val) return { number: '0', unit: '' };
  const strVal = String(val);
  const parts = strVal.split(' ');

  let unit = parts[1] || '';

  if (unit.toUpperCase() === 'VND') {
    unit = 'VNĐ';
  }

  return {
    number: parts[0],
    unit: unit
  };
};
</script>

<style scoped>
.stats-label {
  font-size: 0.9rem;
  color: #6c757d;
  /* Màu xám nhẹ cho label */
  font-weight: 500;
  margin-bottom: 0;
}

.stats-value {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.stats-lines {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.value-number {
  font-size: 1.4rem;
  font-weight: 800;
  line-height: 1;
  color: #333;
}

.value-line {
  font-size: 1.05rem;
  font-weight: 800;
  line-height: 1.2;
  color: #333;
}

.value-unit {
  font-size: 1rem;
  font-weight: 700;
  opacity: 0.8;
}

.icon-box {
  width: 38px;
  /* Thu nhỏ nhẹ để cân đối với text */
  height: 38px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fdf5eb;
  color: #c6a67d;
  flex-shrink: 0;
}

/* Khoảng cách giữa hàng tiêu đề và hàng số */
.mb-2 {
  margin-bottom: 0.75rem !important;
}
</style>
