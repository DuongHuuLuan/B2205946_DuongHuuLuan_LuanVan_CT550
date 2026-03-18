<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Đơn hàng</h4>
          <div class="small opacity-75">
            Theo dõi đơn chờ duyệt, đơn đã thanh toán và các trường hợp cần hỗ trợ hoàn tiền.
          </div>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md-6 col-lg-5">
              <SearchToggle v-model="keyword" placeholder="Tìm theo mã đơn, email, tên người dùng..." />
            </div>

            <div class="col-12 col-md-6 col-lg-3">
              <select v-model="status" class="form-select bg-transparent">
                <option value="">Tất cả trạng thái</option>
                <option value="pending">Chờ xử lý (Pending)</option>
                <option value="shipping">Đang giao (Shipping)</option>
                <option value="completed">Hoàn thành (Completed)</option>
                <option value="cancelled">Đã hủy (Cancelled)</option>
              </select>
            </div>

            <div class="col-12 col-lg-4 d-flex justify-content-md-end gap-2">
              <span class="badge bg-secondary-subtle text-secondary align-self-center">
                Tổng: {{ meta.total }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body p-0">
          <div v-if="loading" class="py-5 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <div v-else class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th class="ps-3" style="width: 120px">Mã đơn</th>
                  <th>Khách hàng</th>
                  <th style="min-width: 220px">Thanh toán</th>
                  <th style="min-width: 220px">Trạng thái</th>
                  <th class="text-center" style="width: 170px">Ngày tạo</th>
                  <th class="text-center" style="width: 160px">Tổng tiền</th>
                  <th class="text-center" style="width: 150px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="order in items" :key="order.id">
                  <td class="ps-3">
                    <span class="code-pill">O{{ order.id }}</span>
                  </td>

                  <td>
                    <RouterLink class="name-link" :to="{ name: 'orders.detail', params: { id: order.id } }">
                      <div class="fw-semibold">
                        {{ order?.user?.username || order?.delivery_info?.name || "-" }}
                      </div>
                      <div class="small opacity-75">
                        {{ order?.user?.email || order?.delivery_info?.phone || "-" }}
                      </div>
                    </RouterLink>
                  </td>

                  <td>
                    <div class="fw-semibold small">
                      {{ order?.payment_method?.name || "-" }}
                    </div>
                    <div class="mt-1 d-flex flex-wrap gap-1">
                      <span class="badge" :class="paymentStatusBadgeClass(order?.payment_status)">
                        {{ paymentStatusLabel(order?.payment_status) }}
                      </span>
                      <span v-if="showRefundBadge(order?.refund_support_status)" class="badge"
                        :class="refundSupportBadgeClass(order?.refund_support_status)">
                        {{ refundSupportLabel(order?.refund_support_status) }}
                      </span>
                    </div>
                  </td>

                  <td>
                    <div class="d-flex flex-column gap-1">
                      <div>
                        <span class="badge" :class="statusTableBadgeClass(order?.status)">
                          {{ statusLabel(order?.status) }}
                        </span>
                      </div>
                      <div v-if="order?.rejection_reason" class="small rejection-text" :title="order.rejection_reason">
                        Lý do: {{ order.rejection_reason }}
                      </div>
                    </div>
                  </td>

                  <td class="text-center">
                    <span class="small opacity-75">
                      {{ formatDateTimeVN(order?.created_at) }}
                    </span>
                  </td>

                  <td class="text-center fw-semibold">
                    {{ formatMoney(calcTotal(order)) }}
                  </td>

                  <td class="text-end pe-3">
                    <div class="d-flex justify-content-center gap-2">
                      <RouterLink v-if="canReviewOrder(order?.status)" class="btn btn-sm btn-approve px-3"
                        :to="{ name: 'orders.detail', params: { id: order.id } }" title="Xem và duyệt đơn">
                        Duyệt đơn
                      </RouterLink>

                      <RouterLink v-else class="icon-btn icon-view"
                        :to="{ name: 'orders.detail', params: { id: order.id } }" title="Xem chi tiết">
                        <i class="fa-solid fa-eye"></i>
                      </RouterLink>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="7" class="text-center py-5">
                    <div class="opacity-75">
                      <i class="fa-regular fa-folder-open fs-4 d-block mb-2"></i>
                      Không có đơn hàng phù hợp.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-if="meta.total" class="d-flex justify-content-between align-items-center p-3 border-top">
            <div class="small opacity-75">
              Hiển thị
              {{ (meta.current_page - 1) * meta.per_page + 1 }}
              -
              {{ Math.min(meta.current_page * meta.per_page, meta.total) }}
              /
              {{ meta.total }}
            </div>

            <div class="btn-group">
              <button class="btn btn-outline-secondary btn-sm" :disabled="page === 1" @click="page--">
                <i class="fa-solid fa-chevron-left"></i>
              </button>
              <button class="btn btn-outline-secondary btn-sm" disabled>
                Trang {{ page }}
              </button>
              <button class="btn btn-outline-secondary btn-sm" :disabled="meta.current_page >= meta.last_page"
                @click="page++">
                <i class="fa-solid fa-chevron-right"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref, watch } from "vue";
import Swal from "sweetalert2";

import SearchToggle from "@/components/common/SearchToggle.vue";
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

const keyword = ref("");
const status = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({
  current_page: 1,
  per_page: perPage,
  total: 0,
  last_page: 1,
});
const loading = ref(false);

function calcTotal(order) {
  const details = order?.order_details || [];
  return details.reduce((sum, item) => {
    const qty = Number(item?.quantity || 0);
    const price = Number(item?.price || 0);
    return sum + qty * price;
  }, 0);
}

function canReviewOrder(orderStatus) {
  return normalizeEnumText(orderStatus) === "pending";
}

function showRefundBadge(refundStatus) {
  const value = normalizeEnumText(refundStatus);
  return Boolean(value) && value !== "none";
}

async function fetchOrders() {
  loading.value = true;
  try {
    const response = await OrderService.getAll({
      q: keyword.value.trim() || undefined,
      status: status.value || undefined,
      page: page.value,
      per_page: perPage,
    });

    items.value = Array.isArray(response?.items) ? response.items : [];
    meta.value = response?.meta ?? {
      current_page: 1,
      per_page: perPage,
      total: 0,
      last_page: 1,
    };
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể tải đơn hàng. Vui lòng thử lại.";
    await Swal.fire("Lỗi", message, "error");
  } finally {
    loading.value = false;
  }
}

onMounted(fetchOrders);

watch([keyword, status], async () => {
  page.value = 1;
  await fetchOrders();
});

watch(page, async () => {
  await fetchOrders();
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.name-link {
  text-decoration: none;
  color: inherit;
  display: inline-block;
}

.code-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.3rem 0.6rem;
  border-radius: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.2px;
  background: color-mix(in srgb, var(--main-color) 14%, transparent);
  border: 1px solid var(--hover-border-color);
  color: var(--font-color);
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

.icon-btn {
  width: 36px;
  height: 36px;
  border-radius: 0.75rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-color);
  background: transparent;
  text-decoration: none;
  transition: 0.12s ease;
}

.icon-btn:hover {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}

.icon-view {
  color: #0ea5e9;
}

.btn-approve {
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  background: var(--status-warning-bg);
  color: var(--font-color);
  font-weight: 600;
}

.btn-approve:hover {
  filter: var(--brightness);
  color: #8a6700;
}

.rejection-text {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
  color: var(--status-danger);
  max-width: 18rem;
}
</style>