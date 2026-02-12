<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Cập nhật trạng thái</h4>
          <div class="small opacity-75">Chỉnh sửa trạng thái đơn hàng</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'orders.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <form v-else @submit.prevent="onSubmit">
            <div class="row g-3">
              <div class="col-12 col-md-6">
                <label class="form-label">Mã đơn</label>
                <div class="form-control bg-transparent">O{{ order?.id || "-" }}</div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Khách hàng</label>
                <div class="form-control bg-transparent">
                  {{ order?.user?.username || order?.delivery_info?.name || "-" }}
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Trạng thái</label>
                <select v-if="canAdminUpdateStatus" v-model="status" class="form-select bg-transparent"
                  :disabled="saving">
                  <option v-for="opt in adminStatusOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
                <div v-else class="form-control bg-transparent">
                  {{ statusLabel(order?.status) }}
                </div>
                <div class="form-text text-warning mt-1" v-if="!canAdminUpdateStatus">
                  Admin chỉ được cập nhật đơn hàng ở trạng thái chờ xác nhận.
                </div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="!canSubmit">
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ saving ? "Đang lưu..." : "Lưu thay đổi" }}
              </button>

              <RouterLink class="btn btn-outline-secondary" :to="{ name: 'orders.detail', params: { id } }">
                <i class="fa-solid fa-eye me-1"></i> Xem chi tiết
              </RouterLink>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";
import OrderService from "@/services/order.service";
import { statusLabel } from "@/utils/utils";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const saving = ref(false);
const order = ref(null);
const status = ref("pending");
const adminStatusOptions = [
  { value: "shipping", label: "Shipping" },
  { value: "cancelled", label: "Cancelled" },
];

const currentStatus = computed(() => String(order.value?.status || "").toLowerCase());
const canAdminUpdateStatus = computed(() => currentStatus.value === "pending");
const canSubmit = computed(() => {
  return !saving.value && canAdminUpdateStatus.value && adminStatusOptions.some((opt) => opt.value === status.value);
});

async function fetchOrder() {
  loading.value = true;
  try {
    const res = await OrderService.get(id);
    order.value = res ?? null;
    status.value = canAdminUpdateStatus.value ? "shipping" : order.value?.status || "pending";
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tài đơn hàng. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "orders.list" });
  } finally {
    loading.value = false;
  }
}

async function onSubmit() {
  if (!canAdminUpdateStatus.value || !adminStatusOptions.some((opt) => opt.value === status.value)) {
    await Swal.fire("Không hợp lệ", "Admin chỉ được chuyển trạng thái từ chờ xác nhận sang giao hàng hoặc hủy đơn.", "warning");
    return;
  }

  saving.value = true;
  try {
    await OrderService.updateStatus(id, { status: status.value });
    await Swal.fire("Thành công", "Cập nhật trạng thái thành công!", "success");
    router.push({ name: "orders.detail", params: { id } });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật trạng thái thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
  } finally {
    saving.value = false;
  }
}

onMounted(fetchOrder);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.btn-accent {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
}

.btn-accent:hover {
  filter: var(--brightness);
}
</style>
