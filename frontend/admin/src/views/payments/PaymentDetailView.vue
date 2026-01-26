<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết phương thức thanh toán</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'payments.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'payments.edit', params: { id } }">
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

          <div v-else-if="!payment" class="py-4 text-center opacity-75">
            Không tìm thấy phương thức thanh toán.
          </div>

          <div v-else>
            <div class="mb-2">
              <span class="label">Tên:</span> {{ payment.name || "-" }}
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
import PaymentService from "@/services/payment.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const payment = ref(null);

async function fetchPayment() {
  loading.value = true;
  try {
    const res = await PaymentService.get(props.id);
    payment.value = res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải phương thức thanh toán.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "payments.list" });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
  const result = await Swal.fire({
    title: "Xóa phương thức thanh toán này?",
    text: "Không thể hoàn tác!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xóa",
    cancelButtonText: "Hủy",
  });

  if (!result.isConfirmed) return;

  try {
    await PaymentService.delete(props.id);
    await Swal.fire({ title: "Xóa thành công", icon: "success" });
    router.push({ name: "payments.list" });
  } catch (e) {
    await Swal.fire({
      title: "Lỗi",
      text: e?.response?.data?.message || "Không thể xóa",
      icon: "error",
    });
  }
}

onMounted(fetchPayment);
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
