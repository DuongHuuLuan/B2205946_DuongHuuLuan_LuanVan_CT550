<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết đơn hàng</h4>
          <div class="small opacity-75">Xem thông tin và danh sách sản phẩm</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'orders.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <div v-else-if="!order" class="py-4 text-center opacity-75">
            Không tìm thấy đơn hàng.
          </div>

          <template v-else>
            <div class="row g-3">
              <div class="col-12 col-md-3">
                <label class="form-label">Mã đơn</label>
                <div class="form-control bg-transparent">O{{ order?.id || "-" }}</div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Trạng thái</label>
                <div>
                  <span class="badge" :class="statusTableBadgeClass(order?.status)">
                    {{ statusLabel(order?.status) }}
                  </span>
                </div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Ngày tạo</label>
                <div class="form-control bg-transparent">
                  {{ formatDateTimeVN(order?.created_at) }}
                </div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Thanh toán</label>
                <div class="form-control bg-transparent">
                  {{ order?.payment_method?.name || "-" }}
                </div>
              </div>
            </div>

            <div class="row g-3 mt-2">
              <div class="col-12 col-md-6">
                <label class="form-label">Thông tin Khách hàng</label>
                <div class="form-control bg-transparent mb-2">
                  {{ order?.user?.username || "-" }}
                </div>
                <div class="form-control bg-transparent">
                  {{ order?.user?.email || "-" }}
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Thông tin giao hàng</label>
                <div class="form-control bg-transparent mb-2">
                  {{ order?.delivery_info?.name || "-" }}
                </div>
                <div class="form-control bg-transparent mb-2">
                  {{ order?.delivery_info?.phone || "-" }}
                </div>
                <div class="form-control bg-transparent">
                  {{ order?.delivery_info?.address || "-" }}
                </div>
              </div>
            </div>

            <div class="mt-3">
              <div class="fw-semibold">Danh sách sản phẩm</div>
              <div class="small opacity-75">Sản phẩm, màu, kích thước, số lượng và giá</div>

              <div class="table-responsive mt-2">
                <table class="table align-middle mb-0">
                  <thead>
                    <tr class="small opacity-75">
                      <th style="min-width: 320px">Sản phẩm</th>
                      <th style="min-width: 160px">Màu</th>
                      <th style="min-width: 140px">Kích thước</th>
                      <th style="width: 120px">Số lượng</th>
                      <th style="width: 160px">Giá</th>
                      <th style="width: 160px" class="text-end">Thành tiền</th>
                    </tr>
                  </thead>

                  <tbody>
                    <tr v-for="(it, idx) in orderItems" :key="idx">
                      <td>
                        <div class="d-flex align-items-center gap-2">
                          <div class="thumb">
                            <img v-if="it?.image_url" :src="it.image_url" alt="thumb" />
                            <div v-else class="thumb-placeholder">
                              <i class="fa-regular fa-image"></i>
                            </div>
                          </div>

                          <div>
                            <div class="fw-semibold">{{ it?.product_name || "-" }}</div>
                            <div class="small opacity-75">ID: PD{{ it?.product_detail_id || "-" }}</div>
                          </div>
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.color_name || "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.size_name || "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.quantity ?? "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ formatMoney(it?.price) }}
                        </div>
                      </td>

                      <td class="text-end">
                        <div class="fw-semibold">
                          {{ formatMoney(calcLineTotal(it)) }}
                        </div>
                      </td>
                    </tr>

                    <tr v-if="!orderItems.length">
                      <td colspan="6" class="text-center opacity-75 py-4">
                        Không có dữ liệu sản phẩm.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="d-flex justify-content-end align-items-center gap-3 mt-3 flex-wrap">
                <div class="text-end me-4">
                  <div class="d-flex justify-content-between gap-3 align-items-center">
                    <span class="small opacity-75">Tổng số lượng:</span>
                    <span class="ms-4 fs-5 fw-semibold">{{ calcTQuantity(orderItems) }}</span>
                  </div>
                  <div class="d-flex justify-content-between gap-3 mt-1">
                    <span class="small opacity-75">Tổng tiền:</span>
                    <span class="ms-4 fs-5 fw-semibold">{{ formatMoney(calcTotal(orderItems)) }}</span>
                  </div>
                </div>

                <div v-if="canUpdateStatus" class="d-flex justify-content-md-end align-items-center mt-2 mt-md-0">
                  <button type="button" class="btn btn-approve-warning me-2" :disabled="actionLoading"
                    @click="approveOrder">
                    <i class="fa-solid fa-check me-1"></i>
                    {{ actionLoading ? "Đang xử lý..." : "Duyệt đơn" }}
                  </button>
                  <button type="button" class="btn btn-reject-warning" :disabled="actionLoading" @click="rejectOrder">
                    <i class="fa-solid fa-xmark me-1"></i>
                    {{ actionLoading ? "Đang xử lý..." : "Từ chối" }}
                  </button>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";
import { formatMoney, statusLabel, statusTableBadgeClass, formatDateTimeVN } from "@/utils/utils";
import OrderService from "@/services/order.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const order = ref(null);
const actionLoading = ref(false);
const canUpdateStatus = computed(() => String(order.value?.status || "").toLowerCase() === "pending");

const orderItems = computed(() => {
  return order.value?.order_details || [];
});

function calcLineTotal(it) {
  const q = Number(it?.quantity || 0);
  const p = Number(it?.price || 0);
  return q * p;
}

function calcTotal(items) {
  return (items || []).reduce((sum, it) => sum + calcLineTotal(it), 0);
}

function calcTQuantity(items) {
  return (items || []).reduce((sum, it) => sum + Number(it?.quantity || 0), 0);
}

async function fetchOrder() {
  loading.value = true;
  try {
    const res = await OrderService.get(id);
    order.value = res ?? null;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải đơn hàng. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "orders.list" });
  } finally {
    loading.value = false;
  }
}

async function approveOrder() {
  try {
    const ok = await Swal.fire({
      title: "Duyệt đơn hàng?",
      text: "Đơn hàng sẽ được chuyển sang trạng thái đang giao.",
      icon: "question",
      showCancelButton: true,
      confirmButtonText: "Duyệt đơn",
      cancelButtonText: "Hủy",
    });

    if (!ok.isConfirmed) return;

    actionLoading.value = true;
    await OrderService.updateStatus(id, { status: "shipping" });
    await Swal.fire("Thành công", "Đã duyệt đơn hàng.", "success");
    await fetchOrder();
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Duyệt đơn thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
  } finally {
    actionLoading.value = false;
  }
}

async function rejectOrder() {
  try {
    const ok = await Swal.fire({
      title: "Từ chối đơn hàng?",
      text: "Đơn hàng sẽ được chuyển sang trạng thái đã hủy.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Từ chối",
      cancelButtonText: "Hủy",
    });

    if (!ok.isConfirmed) return;

    actionLoading.value = true;
    await OrderService.updateStatus(id, { status: "cancelled" });
    await Swal.fire("Thành công", "Đã từ chối đơn hàng.", "success");
    await fetchOrder();
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Từ chối đơn thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
  } finally {
    actionLoading.value = false;
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

.thumb {
  width: 6rem;
  border-radius: 0.6rem;
  overflow: hidden;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.03);
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumb-placeholder {
  opacity: 0.6;
  font-size: 1.1rem;
}

.status-pending {
  background: var(--status-warning-bg);
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-shipping {
  background: var(--status-info-bg);
  border: 1px solid color-mix(in srgb, var(--status-info) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-completed {
  background: var(--status-success-bg);
  border: 1px solid color-mix(in srgb, var(--status-success) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-canceled {
  background: var(--status-danger-bg);
  border: 1px solid color-mix(in srgb, var(--status-danger) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.btn-approve-warning {
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: #8a6700;
  background: transparent;
  font-weight: 600;
  transition: background-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.btn-approve-warning:hover,
.btn-approve-warning:focus-visible,
.btn-approve-warning:active {
  background: var(--status-warning-bg);
  color: #8a6700;
}

.btn-approve-warning:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(0, 0, 0, 0.1);
}

.btn-reject-warning {
  border: 1px solid color-mix(in srgb, var(--status-danger) 55%, transparent);
  color: var(--status-danger);
  background: transparent;
  font-weight: 600;
  transition: background-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.btn-reject-warning:hover,
.btn-reject-warning:focus-visible,
.btn-reject-warning:active {
  background: var(--status-danger-bg);
  color: var(--status-danger);
}

.btn-reject-warning:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(0, 0, 0, 0.1);
}
</style>
