<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết phiếu nhập</h4>
          <div class="small opacity-75">
            Xem thông tin nhà cung cấp, kho, trạng thái và danh sách mặt hàng
          </div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'receipts.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Content -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <!-- Loading -->
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <template v-else>
            <!-- Top info -->
            <div class="row g-3">
              <!-- Distributor -->
              <div class="col-12 col-md-5">
                <label class="form-label">Nhà cung cấp</label>
                <div class="form-control bg-transparent">
                  {{ receipt?.distributor?.name || receipt?.distributor_name || "—" }}
                </div>
              </div>

              <!-- Warehouse -->
              <div class="col-12 col-md-5">
                <label class="form-label">Kho nhập</label>
                <div class="form-control bg-transparent">
                  {{
                    receipt?.warehouse?.address ||
                    receipt?.warehouse_address ||
                    "—"
                  }}
                </div>
              </div>

              <!-- Status -->
              <div class="col-12 col-md-2">
                <label class="form-label">Trạng thái</label>
                <div class="d-flex align-items-center gap-2">
                  <span class="badge" :class="statusBadgeClass(receipt?.status)">
                    {{ statusLabel(receipt?.status) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Items -->
            <div class="mt-3">
              <div class="fw-semibold">Danh sách sản phẩm nhập</div>
              <div class="small opacity-75">
                Sản phẩm, màu, số lượng, giá nhập và thành tiền
              </div>

              <div class="table-responsive mt-2">
                <table class="table align-middle mb-0">
                  <thead>
                    <tr class="small opacity-75">
                      <th style="min-width: 340px">Sản phẩm</th>
                      <th style="min-width: 200px">Màu</th>
                      <th style="min-width: 140px">Size</th>
                      <th style="width: 140px">Số lượng</th>
                      <th style="width: 180px">Giá nhập</th>
                      <th style="width: 180px" class="text-end">Thành tiền</th>
                    </tr>
                  </thead>

                  <tbody>
                    <tr v-for="(it, idx) in receiptItems" :key="idx">
                      <!-- Product + image -->
                      <td>
                        <div class="d-flex align-items-center gap-2">
                          <div class="thumb">
                            <img v-if="getProductThumb(it.product)" :src="getProductThumb(it.product)" alt="thumb" />
                            <div v-else class="thumb-placeholder">
                              <i class="fa-regular fa-image"></i>
                            </div>
                          </div>

                          <div class="flex-grow-1">
                            <div class="fw-semibold">
                              {{ it?.product?.name || "—" }}
                            </div>
                            <div class="small opacity-75">
                              ID: P{{ it?.product?.id || "—" }}
                            </div>
                            <div class="small opacity-75">
                              Danh mục: {{ it?.product?.category.name || "—" }}
                            </div>
                          </div>
                        </div>
                      </td>

                      <!-- Color -->
                      <td>
                        <div class="form-control bg-transparent">
                          {{
                            it?.color?.name ||
                            it?.color_name ||
                            "Không có màu"
                          }}
                        </div>
                      </td>

                      <!-- Size -->
                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.size?.size || "-" }}
                        </div>
                      </td>

                      <!-- Quantity -->
                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.quantity ?? "—" }}
                        </div>
                      </td>

                      <!-- Purchase price -->
                      <td>
                        <div class="form-control bg-transparent">
                          {{ formatMoney(it?.purchase_price) }}
                        </div>
                      </td>

                      <!-- Line total -->
                      <td class="text-end">
                        <div class="fw-semibold">
                          {{ formatMoney(calcLineTotal(it)) }}
                        </div>
                      </td>
                    </tr>

                    <tr v-if="!receiptItems.length">
                      <td colspan="6" class="text-center opacity-75 py-4">
                        Không có dữ liệu mặt hàng.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- Summary -->
              <div class="d-flex justify-content-end mt-3">
                <div class="text-end">
                  <div class="d-flex justify-content-between gap-3 align-items-center">
                    <span class="small opacity-75">Tổng số lượng :</span>
                    <span class="ms-4 fs-5 fw-semibold">{{
                      calcTQuantity(receiptItems)
                    }}</span>
                  </div>

                  <div class="d-flex justify-content-between gap-3 mt-1">
                    <span class="small opacity-75">Tổng tiền :</span>
                    <span class="ms-4 fs-5 fw-semibold">{{
                      formatMoney(calcTotal(receiptItems))
                    }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!--  meta -->
            <div class="row g-3 mt-1" v-if="receipt?.created_at || receipt?.updated_at">
              <div class="col-12 col-md-5">
                <div class="small opacity-75">Ngày tạo</div>
                <div>{{ formatDateTimeVN(receipt?.created_at) || "—" }}</div>
              </div>
              <div class="col-12 col-md-4">
                <div class="small opacity-75">Cập nhật</div>
                <div>{{ formatDateTimeVN(receipt?.updated_at) || "—" }}</div>
              </div>

              <div class="d-flex col-12 col-md-3 justify-content-md-end align-items-center mt-2 mt-md-0"
                v-if="receipt?.status === 'pending'">
                <button type="button" class="btn btn-outline-success me-2" :disabled="actionLoading"
                  @click="approveReceipt">
                  <i class="fa-solid fa-check me-1"></i>
                  {{ actionLoading ? "Đang xử lý..." : "Duyệt phiếu" }}
                </button>

                <button type="button" class="btn btn-outline-danger" :disabled="actionLoading" @click="rejectReceipt">
                  <i class="fa-solid fa-xmark me-1"></i>
                  {{ actionLoading ? "Đang xử lý..." : "Từ chối" }}
                </button>
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
import {
  formatMoney,
  statusLabel,
  statusBadgeClass,
  getProductThumb,
  formatDateTimeVN,
} from "@/utils/utils";
import ReceiptService from "@/services/receipt.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const receipt = ref(null);

const receiptItems = computed(() => {
  return receipt.value?.details || receipt.value?.receipt_details || [];
});

function calcLineTotal(it) {
  const q = Number(it?.quantity || 0);
  const p = Number(it?.purchase_price || 0);
  return q * p;
}

function calcTotal(items) {
  return (items || []).reduce((sum, it) => sum + calcLineTotal(it), 0);
}

function calcTQuantity(items) {
  return (items || []).reduce((sum, it) => sum + Number(it?.quantity || 0), 0);
}

async function fetchReceipt() {
  loading.value = true;
  try {
    const res = await ReceiptService.get(id);
    const data = res ?? {};

    receipt.value = data;
    console.log(res);
    console.log(receipt.value);
  } catch (e) {
    console.log(e);
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải phiếu nhập. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "receipts.list" });
  } finally {
    loading.value = false;
  }
}

// Thay đổi trạng thái
const actionLoading = ref(false);

async function approveReceipt() {
  try {
    const ok = await Swal.fire({
      title: "Duyệt phiếu nhập?",
      text: "Các sản phẩm trong phiếu sẽ được thêm vào kho.",
      icon: "question",
      showCancelButton: true,
      confirmButtonText: "Duyệt",
      cancelButtonText: "Hủy",
    });

    if (!ok.isConfirmed) return;

    actionLoading.value = true;

    await ReceiptService.approve(id);

    await Swal.fire("Thành công!", "Đã duyệt phiếu nhập.", "success");
    await fetchReceipt(); // reload lại status + data
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Duyệt phiếu thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
  } finally {
    actionLoading.value = false;
  }
}

async function rejectReceipt() {
  try {
    const ok = await Swal.fire({
      title: "Từ chối phiếu nhập?",
      text: "Sản phẩm sẽ không được thêm vào kho.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Từ chối",
      cancelButtonText: "Hủy",
      confirmButtonColor: "#dc3545",
    });

    if (!ok.isConfirmed) return;

    actionLoading.value = true;

    await ReceiptService.reject(id);

    await Swal.fire("Thành công!", "Đã từ chối phiếu nhập.", "success");
    await fetchReceipt();
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Từ chối phiếu thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
  } finally {
    actionLoading.value = false;
  }
}

onMounted(fetchReceipt);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

/* product thumb */
.thumb {
  width: 7rem;
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

/* status badges */
.badge {
  padding: 0.45rem 0.6rem;
  border-radius: 0.6rem;
  font-weight: 600;
}

.badge-pending {
  background: rgba(255, 193, 7, 0.18);
  border: 1px solid rgba(255, 193, 7, 0.35);
  color: #ffc107;
}

.badge-completed {
  background: rgba(25, 135, 84, 0.18);
  border: 1px solid rgba(25, 135, 84, 0.35);
  color: #2ecc71;
}

.badge-canceled {
  background: rgba(220, 53, 69, 0.18);
  border: 1px solid rgba(220, 53, 69, 0.35);
  color: #ff6b6b;
}

.badge-secondary {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid var(--border-color);
  color: var(--font-color);
}
</style>
