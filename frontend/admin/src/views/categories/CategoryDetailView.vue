<template>
  <div class="card card-soft">
    <div class="card-body">
      <h4 class="mb-1">Chi tiết danh mục</h4>
      <div class="small opacity-75">ID: {{ id }} (Placeholder)</div>

      <hr />
      <div class="d-flex gap-2">
        <RouterLink class="btn btn-outline-secondary" to="/categories">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>

        <RouterLink
          class="btn btn-outline-secondary"
          :to="{ name: 'categories.edit', params: { id } }"
        >
          <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({ id: String });
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}
</style>
