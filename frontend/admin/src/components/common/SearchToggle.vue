<template>
  <div class="search-toggle" @keydown.escape="closeIfEmpty" @focusout="onFocusOut">
    <button class="search-toggle-btn" type="button" @click="openSearch" aria-label="Search">
      <i class="fa-solid fa-magnifying-glass"></i>
    </button>

    <Transition name="expand">
      <div v-show="open" class="input-group search-toggle-input">
        <input ref="inputRef" :value="modelValue" type="text" class="form-control bg-transparent"
          :placeholder="placeholder" @input="onInput" @blur="closeIfEmpty" />
        <button v-if="modelValue" class="btn btn-outline-secondary" type="button" title="Clear" @mousedown.prevent
          @click="clear">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { nextTick, ref, watch } from "vue";

const props = defineProps({
  modelValue: { type: String, default: "" },
  placeholder: { type: String, default: "Tìm kiếm..." },
});

const emit = defineEmits(["update:modelValue"]);
const open = ref(!!props.modelValue);
const inputRef = ref(null);

watch(
  () => props.modelValue,
  (value) => {
    if (value && !open.value) {
      open.value = true;
    }
  }
);

function onInput(event) {
  emit("update:modelValue", event.target.value);
}

function openSearch() {
  open.value = true;
  nextTick(() => inputRef.value?.focus());
}

function closeIfEmpty() {
  if (!props.modelValue) {
    open.value = false;
  }
}

function clear() {
  emit("update:modelValue", "");
  nextTick(() => inputRef.value?.focus());
}

function onFocusOut(event) {
  if (!event.currentTarget.contains(event.relatedTarget)) {
    closeIfEmpty();
  }
}
</script>

<style scoped>
.search-toggle {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.search-toggle-btn {
  width: 38px;
  height: 38px;
  border-radius: 999px;
  border: 1px solid var(--border-color, #dee2e6);
  background: var(--main-extra-bg, #fff);
  color: var(--font-extra-color, #6c757d);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: 0.2s;
}

.search-toggle-input {
  min-width: 220px;
  max-width: 360px;
  overflow: hidden;
  /* Quan trọng để hiệu ứng mượt hơn */
}

/* CSS CHO HIỆU ỨNG HIỆN RA TỪ TỪ */

/* 1. Trạng thái khi đang thực hiện animation */
.expand-enter-active,
.expand-leave-active {
  transition: all 0.3s ease-out;
}

/* 2. Trạng thái bắt đầu vào / kết thúc ra (ẩn đi) */
.expand-enter-from,
.expand-leave-to {
  opacity: 0;
  transform: translateX(-10px);
  /* Dịch nhẹ sang trái */
  max-width: 0;
  /* Thu nhỏ chiều rộng về 0 */
}

/* 3. Trạng thái khi đã hiện ra hoàn toàn */
.expand-enter-to,
.expand-leave-from {
  opacity: 1;
  transform: translateX(0);
  max-width: 360px;
}

@media (max-width: 768px) {
  .search-toggle-input {
    min-width: 180px;
  }
}
</style>