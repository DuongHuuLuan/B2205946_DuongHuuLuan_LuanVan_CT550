<template>
  <div class="card card-soft h-100">
    <div class="card-body">
      <div class="d-flex align-items-start justify-content-between">
        <div>
          <div class="stats-label">{{ label }}</div>
          <div class="stats-value">
            <span class="value-number">{{ formatValue(value).number }}</span>
            <span class="value-unit">{{ formatValue(value).unit }}</span>
          </div>
        </div>

        <div class="icon-box">
          <i :class="icon"></i>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  label: String,
  value: [String, Number],
  icon: String
});

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
  font-size: 0.85rem;
  opacity: 0.75;
  /* Chỉnh con số này để tăng/giảm khoảng cách */
  margin-bottom: 10px;
  line-height: 1.2;
}

.stats-value {
  display: inline-flex;
  align-items: baseline;
  gap: 4px;
}

.value-number {
  font-size: 1.2rem;
  font-weight: 800;
  line-height: 1;
}

.value-unit {
  font-size: 1rem;
  /* VNĐ nhỏ hơn */
  font-weight: 700;
  opacity: 0.9;
  text-transform: uppercase;
}

/* Chỉnh lại icon-box cho tròn và giống mẫu hơn */
.icon-box {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  /* Chỉnh thành hình tròn */
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7ede2;
  /* Màu beige nhạt như hình bạn gửi */
  color: #c6a67d;
  /* Màu icon nâu vàng */
}
</style>