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
                <label class="form-label">Người đặt</label>
                <div class="form-control bg-transparent">
                  {{ order?.user?.username || order?.delivery_info?.name || "-" }}
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Trạng thái</label>
                <select v-model="status" class="form-select bg-transparent">
                  <option value="pending">Pending</option>
                  <option value="shipping">Shipping</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="saving">
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
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";
import OrderService from "@/services/order.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const saving = ref(false);
const order = ref(null);
const status = ref("pending");

async function fetchOrder() {
  loading.value = true;
  try {
    const res = await OrderService.get(id);
    order.value = res?.data ?? res ?? null;
    status.value = order.value?.status || "pending";
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
