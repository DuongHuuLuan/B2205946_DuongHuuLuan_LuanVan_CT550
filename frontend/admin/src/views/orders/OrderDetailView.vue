<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết đơn hàng</h4>
          <div class="small opacity-75">
            Xem thông tin giao hàng, thanh toán, lý do hủy và thao tác duyệt đơn.
          </div>
        </div>

        <div class="d-flex gap-2 flex-wrap">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'orders.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>

          <RouterLink v-if="order && orderItems.length" class="btn btn-production"
            :to="{ name: 'orders.production', params: { id } }">
            <i class="fa-solid fa-wand-magic-sparkles me-1"></i>
            Chế độ xem sản xuất
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
                <div class="form-control bg-transparent">O{{ order.id }}</div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Trạng thái đơn</label>
                <div class="d-flex align-items-center gap-2 flex-wrap pt-1">
                  <span class="badge" :class="statusTableBadgeClass(order?.status)">
                    {{ statusLabel(order?.status) }}
                  </span>
                  <span v-if="showRefundBadge(order?.refund_support_status)" class="badge"
                    :class="refundSupportBadgeClass(order?.refund_support_status)">
                    {{ refundSupportLabel(order?.refund_support_status) }}
                  </span>
                </div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Thanh toán</label>
                <div class="form-control bg-transparent mb-2">
                  {{ order?.payment_method?.name || "-" }}
                </div>
                <div>
                  <span class="badge" :class="paymentStatusBadgeClass(order?.payment_status)">
                    {{ paymentStatusLabel(order?.payment_status) }}
                  </span>
                </div>
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Ngày tạo</label>
                <div class="form-control bg-transparent">
                  {{ formatDateTimeVN(order?.created_at) }}
                </div>
              </div>
            </div>

            <div v-if="order?.rejection_reason" class="alert alert-danger mt-3 mb-0">
              <div class="fw-semibold mb-1">Lý do từ chối</div>
              <div>{{ order.rejection_reason }}</div>
            </div>

            <div
              v-if="normalizeEnumText(order?.payment_status) === 'paid' && showRefundBadge(order?.refund_support_status)"
              class="alert alert-warning mt-3 mb-0">
              Đơn này đã thanh toán. Nếu bị từ chối, khách hàng cần được hướng dẫn liên hệ chat để xử lý hoàn tiền.
            </div>

            <div class="row g-3 mt-1">
              <div class="col-12 col-md-6">
                <label class="form-label">Thông tin khách hàng</label>
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

            <div v-if="order?.reviewed_at" class="row g-3 mt-1">
              <div class="col-12 col-md-4">
                <div class="small opacity-75">Duyệt lúc</div>
                <div>{{ formatDateTimeVN(order?.reviewed_at) }}</div>
              </div>
              <div class="col-12 col-md-4">
                <div class="small opacity-75">Admin duyệt</div>
                <div>{{ order?.reviewed_by_admin_id || "-" }}</div>
              </div>
            </div>

            <div class="mt-3">
              <div class="d-flex align-items-center justify-content-between gap-2 flex-wrap">
                <div>
                  <div class="fw-semibold">Danh sách sản phẩm</div>
                  <div class="small opacity-75">
                    Sản phẩm, màu, kích thước, số lượng, giá và thông tin thiết kế.
                  </div>
                </div>
              </div>

              <div class="table-responsive mt-2">
                <table class="table align-middle mb-0">
                  <thead>
                    <tr class="small opacity-75">
                      <th style="min-width: 340px">Sản phẩm</th>
                      <th style="min-width: 160px">Màu</th>
                      <th style="min-width: 140px">Kích thước</th>
                      <th style="min-width: 220px">Thiết kế</th>
                      <th style="width: 120px">Số lượng</th>
                      <th style="width: 160px">Giá</th>
                      <th style="width: 160px" class="text-end">Thành tiền</th>
                    </tr>
                  </thead>

                  <tbody>
                    <tr v-for="(item, index) in orderItems" :key="index">
                      <td>
                        <div class="d-flex align-items-center gap-2">
                          <div class="thumb">
                            <img v-if="item?.image_url" :src="item.image_url" alt="thumb" />
                            <div v-else class="thumb-placeholder">
                              <i class="fa-regular fa-image"></i>
                            </div>
                          </div>

                          <div>
                            <div class="fw-semibold">{{ item?.product_name || "-" }}</div>
                            <div class="small opacity-75">
                              Chi tiết sản phẩm: PD{{ item?.product_detail_id || "-" }}
                            </div>
                          </div>
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ item?.color_name || "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ item?.size_name || "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="design-cell">
                          <div class="fw-semibold">{{ item?.design_name || "Không có thiết kế" }}</div>
                          <div class="small opacity-75">
                            ID thiết kế: {{ item?.design_id || "-" }}
                          </div>
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ item?.quantity ?? "-" }}
                        </div>
                      </td>

                      <td>
                        <div class="form-control bg-transparent">
                          {{ formatMoney(item?.price) }}
                        </div>
                      </td>

                      <td class="text-end">
                        <div class="fw-semibold">
                          {{ formatMoney(calcLineTotal(item)) }}
                        </div>
                      </td>
                    </tr>

                    <tr v-if="!orderItems.length">
                      <td colspan="7" class="text-center opacity-75 py-4">
                        Không có dữ liệu sản phẩm.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="d-flex justify-content-between align-items-center gap-3 mt-3 flex-wrap">
                <div class="text-end">
                  <div class="d-flex justify-content-between gap-3 align-items-center">
                    <span class="small opacity-75">Tổng số lượng:</span>
                    <span class="ms-4 fs-5 fw-semibold">{{ calcTQuantity(orderItems) }}</span>
                  </div>
                  <div class="d-flex justify-content-between gap-3 mt-1">
                    <span class="small opacity-75">Tổng tiền:</span>
                    <span class="ms-4 fs-5 fw-semibold">{{ formatMoney(calcTotal(orderItems)) }}</span>
                  </div>
                </div>

                <div v-if="canReviewOrder" class="d-flex justify-content-md-end align-items-center mt-2 mt-md-0 gap-2">
                  <button type="button" class="btn btn-approve-warning" :disabled="actionLoading" @click="approveOrder">
                    <i class="fa-solid fa-check me-1"></i>
                    {{ actionLoading ? "Đang xử lý..." : "Duyệt đơn" }}
                  </button>

                  <button type="button" class="btn btn-reject-warning" :disabled="actionLoading" @click="rejectOrder">
                    <i class="fa-solid fa-xmark me-1"></i>
                    {{ actionLoading ? "Đang xử lý..." : "Từ chối đơn" }}
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

import OrderService from "@/services/order.service";
import {
  formatDateTimeVN,
  formatMoney,
  normalizeEnumText,
  paymentStatusBadgeClass,
  paymentStatusLabel,
  refundSupportBadgeClass,
  refundSupportLabel,
  statusLabel,
  statusTableBadgeClass,
} from "@/utils/utils";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const order = ref(null);
const actionLoading = ref(false);

const orderItems = computed(() => order.value?.order_details || []);
const canReviewOrder = computed(
  () => normalizeEnumText(order.value?.status) === "pending",
);

function calcLineTotal(item) {
  const quantity = Number(item?.quantity || 0);
  const price = Number(item?.price || 0);
  return quantity * price;
}

function calcTotal(items) {
  return (items || []).reduce((sum, item) => sum + calcLineTotal(item), 0);
}

function calcTQuantity(items) {
  return (items || []).reduce((sum, item) => sum + Number(item?.quantity || 0), 0);
}

function showRefundBadge(refundStatus) {
  const value = normalizeEnumText(refundStatus);
  return Boolean(value) && value !== "none";
}

async function fetchOrder() {
  loading.value = true;
  try {
    order.value = await OrderService.get(id);
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể tải đơn hàng. Vui lòng thử lại.";
    await Swal.fire("Lỗi", message, "error");
    router.push({ name: "orders.list" });
  } finally {
    loading.value = false;
  }
}

async function approveOrder() {
  const confirmed = await Swal.fire({
    title: "Duyệt đơn hàng?",
    text: "Đơn hàng sẽ được chuyển sang trạng thái đang giao.",
    icon: "question",
    showCancelButton: true,
    confirmButtonText: "Duyệt đơn",
    cancelButtonText: "Hủy",
  });

  if (!confirmed.isConfirmed) return;

  actionLoading.value = true;
  try {
    await OrderService.approve(id);
    await Swal.fire("Thành công", "Đã duyệt đơn hàng.", "success");
    await fetchOrder();
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Duyệt đơn thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", message, "error");
  } finally {
    actionLoading.value = false;
  }
}

async function rejectOrder() {
  const result = await Swal.fire({
    title: "Từ chối đơn hàng",
    input: "textarea",
    inputLabel: "Lý do từ chối",
    inputPlaceholder: "Nhập lý do hủy đơn để hiện cho khách hàng...",
    inputAttributes: {
      "aria-label": "Lý do từ chối đơn hàng",
    },
    showCancelButton: true,
    confirmButtonText: "Từ chối đơn",
    cancelButtonText: "Hủy",
    preConfirm: (value) => {
      const reason = String(value || "").trim();
      if (!reason) {
        Swal.showValidationMessage("Vui lòng nhập lý do từ chối.");
        return false;
      }
      return reason;
    },
  });

  if (!result.isConfirmed || !result.value) return;

  actionLoading.value = true;
  try {
    await OrderService.reject(id, result.value);
    await Swal.fire("Thành công", "Đã từ chối đơn hàng.", "success");
    await fetchOrder();
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Từ chối đơn thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", message, "error");
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
  height: 4.5rem;
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
  object-fit: contain;
  padding: 0.25rem;
}

.thumb-placeholder {
  opacity: 0.6;
  font-size: 1.1rem;
}

.status-pending,
.payment-unpaid {
  background: var(--status-warning-bg);
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-shipping,
.payment-paid,
.refund-resolved {
  background: var(--status-success-bg);
  border: 1px solid color-mix(in srgb, var(--status-success) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-completed {
  background: var(--status-info-bg);
  border: 1px solid color-mix(in srgb, var(--status-info) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-canceled,
.refund-contact-required {
  background: var(--status-danger-bg);
  border: 1px solid color-mix(in srgb, var(--status-danger) 55%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.refund-none {
  background: color-mix(in srgb, var(--main-extra-bg) 80%, white 20%);
  border: 1px solid var(--border-color);
  color: var(--font-color);
  font-weight: 700;
}

.btn-production {
  border: 1px solid color-mix(in srgb, var(--status-info) 45%, transparent);
  background: color-mix(in srgb, var(--status-info-bg) 75%, transparent);
  color: var(--font-color);
  font-weight: 600;
}

.btn-production:hover {
  filter: var(--brightness);
}

.btn-approve-warning {
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: #8a6700;
  background: transparent;
  font-weight: 600;
  transition:
    background-color 0.15s ease,
    transform 0.15s ease,
    box-shadow 0.15s ease;
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
  transition:
    background-color 0.15s ease,
    transform 0.15s ease,
    box-shadow 0.15s ease;
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

.design-cell {
  min-width: 12rem;
}
</style>