<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết danh mục</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'categories.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'categories.edit', params: { id } }">
            <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
          </RouterLink>
          <button class="btn btn-outline-danger" type="button" :disabled="!canDelete" :title="!canDelete ? 'Khong the xoa: con san pham' : 'Xoa'" @click="onDelete">
            <i class="fa-solid fa-trash me-1"></i> Xoa
          </button>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <div v-else-if="!category" class="py-4 text-center opacity-75">
            Không tìm thấy danh mục
          </div>

          <div v-else>
            <div class="mb-2">
              <span class="label">Tên:</span> {{ category.name || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Số sản phẩm:</span>
              {{ category.products_count ?? 0 }}
            </div>
            <div class="mb-2">
              <span class="label">Tạo lúc:</span>
              {{ formatDate(category.created_at) }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";
import CategoryService from "@/services/category.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const category = ref(null);

const canDelete = computed(() => (category.value?.products_count ?? 0) === 0);

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN");
}

async function fetchCategory() {
  loading.value = true;
  try {
    const res = await CategoryService.get(props.id);
    category.value = res?.data ?? res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không tìm thấy danh mục.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "categories.list" });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
  if (!canDelete.value) {
    await Swal.fire('Khong the xoa', 'Danh muc nay van con san pham.', 'warning');
    return;
  }

  const result = await Swal.fire({
    title: "Xoa danh muc nay?",
    text: "Khong the hoan tac!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xoa",
    cancelButtonText: "Huy",
  });

  if (!result.isConfirmed) return;

  try {
    await CategoryService.delete(props.id);
    await Swal.fire({ title: "Xoa thanh cong", icon: "success" });
    router.push({ name: "categories.list" });
  } catch (e) {
    await Swal.fire({
      title: "Lỗi",
      text: e?.response?.data?.message || "Không thể xóa",
      icon: "error",
    });
  }
}

onMounted(fetchCategory);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.label {
  font-weight: 600;
}
</style>








