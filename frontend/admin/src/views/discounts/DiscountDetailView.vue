<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết khuyến mãi</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'discounts.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'discounts.edit', params: { id } }">
            <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
          </RouterLink>
          <button class="btn btn-outline-danger" type="button" @click="onDelete">
            <i class="fa-solid fa-trash me-1"></i> Xóa
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

          <div v-else-if="!discount" class="py-4 text-center opacity-75">
            Không tìm thấy khuyến mãi.
          </div>

          <div v-else>
            <div class="mb-2">
              <span class="label">Mã/tên:</span> {{ discount.name || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Mô tả:</span> {{ discount.description || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Danh mục:</span> {{ discount.category_id || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Phần trăm:</span> {{ discount.percent ?? 0 }}%
            </div>
            <div class="mb-2">
              <span class="label">Trạng thái:</span> {{ statusLabel(discount.status) }}
            </div>
            <div class="mb-2">
              <span class="label">Bắt đầu:</span> {{ formatDate(discount.start_at) }}
            </div>
            <div class="mb-2">
              <span class="label">Kết thúc:</span> {{ formatDate(discount.end_at) }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";
import DiscountService from "@/services/discount.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const discount = ref(null);

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN");
}

function statusLabel(status) {
  switch (status) {
    case "active":
      return "Đang bật";
    case "disabled":
      return "Đang tắt";
    case "expired":
      return "Hết hạn";
    default:
      return "-";
  }
}

async function fetchDiscount() {
  loading.value = true;
  try {
    const res = await DiscountService.get(props.id);
    discount.value = res?.data ?? res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải khuyến mãi.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "discounts.list" });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
  const result = await Swal.fire({
    title: "Xóa khuyến mãi này?",
    text: "Không thể hoàn tác!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xóa",
    cancelButtonText: "Hủy",
  });

  if (!result.isConfirmed) return;

  try {
    await DiscountService.delete(props.id);
    await Swal.fire({ title: "Xóa thành công", icon: "success" });
    router.push({ name: "discounts.list" });
  } catch (e) {
    await Swal.fire({
      title: "Lỗi",
      text: e?.response?.data?.message || "Không thể xóa",
      icon: "error",
    });
  }
}

onMounted(fetchDiscount);
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