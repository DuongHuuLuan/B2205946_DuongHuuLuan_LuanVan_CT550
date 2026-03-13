<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chế độ xem sản xuất</h4>
          <div class="small opacity-75">
            Xem trước thiết kế, thông số kỹ thuật sticker và xuất file PDF/SVG cho xưởng in.
          </div>
        </div>

        <div class="d-flex gap-2 flex-wrap">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'orders.detail', params: { id } }">
            <i class="fa-solid fa-arrow-left me-1"></i> Về chi tiết đơn
          </RouterLink>
          <button type="button" class="btn btn-export" :disabled="loading || exportingFormat === 'pdf'"
            @click="exportFile('pdf')">
            <i class="fa-solid fa-file-pdf me-1"></i>
            {{ exportingFormat === "pdf" ? "Đang xuất PDF..." : "Xuất PDF" }}
          </button>
          <button type="button" class="btn btn-export-outline" :disabled="loading || exportingFormat === 'svg'"
            @click="exportFile('svg')">
            <i class="fa-solid fa-bezier-curve me-1"></i>
            {{ exportingFormat === "svg" ? "Đang xuất SVG..." : "Xuất SVG" }}
          </button>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu sản xuất...
          </div>

          <div v-else-if="!production" class="py-4 text-center opacity-75">
            Không có dữ liệu sản xuất.
          </div>

          <template v-else>
            <div class="d-flex flex-wrap gap-2 align-items-center">
              <span class="code-pill">Mã đơn: O{{ production.order_id }}</span>
              <span class="badge" :class="statusTableBadgeClass(production.status)">
                {{ statusLabel(production.status) }}
              </span>
              <span class="badge" :class="paymentStatusBadgeClass(production.payment_status)">
                {{ paymentStatusLabel(production.payment_status) }}
              </span>
              <span v-if="showRefundBadge(production.refund_support_status)" class="badge"
                :class="refundSupportBadgeClass(production.refund_support_status)">
                {{ refundSupportLabel(production.refund_support_status) }}
              </span>
            </div>

            <div v-if="production.rejection_reason" class="alert alert-danger mt-3 mb-0">
              <div class="fw-semibold mb-1">Lý do hủy đơn</div>
              <div>{{ production.rejection_reason }}</div>
            </div>

            <div class="row g-3 mt-1">
              <div v-for="item in production.items" :key="item.order_detail_id" class="col-12">
                <div class="production-item">
                  <div class="production-item__head">
                    <div>
                      <h5 class="mb-1">{{ item.product_name || "Thiết kế nón bảo hiểm" }}</h5>
                      <div class="small opacity-75">
                        Chi tiết đơn: OD{{ item.order_detail_id }} | Chi tiết sản phẩm: PD{{ item.product_detail_id }}
                      </div>
                    </div>
                    <div class="item-meta">
                      <div><span class="label">Số lượng:</span> {{ item.quantity }}</div>
                      <div>
                        <span class="label">Vùng in (Print area):</span>
                        {{ formatMeasure(item.printable_width_mm) }} x
                        {{ formatMeasure(item.printable_height_mm) }} mm
                      </div>
                    </div>
                  </div>

                  <div class="row g-3 mt-1">
                    <div class="col-12 col-xl-5">
                      <div class="preview-shell">
                        <div class="preview-stage" :style="{
                          aspectRatio: `${item.canvas_width_px} / ${item.canvas_height_px}`,
                        }">
                          <img v-if="item.base_image_url || item.preview_image_url" class="preview-base"
                            :src="item.base_image_url || item.preview_image_url" alt="Helmet base" />
                          <div v-else class="preview-base preview-base--empty">
                            Không có ảnh nền nón
                          </div>

                          <div v-for="layer in sortedLayers(item.layers)"
                            :key="`${item.order_detail_id}-${layer.z_index}-${layer.sticker_id}`" class="preview-layer"
                            :style="layerBoxStyle(item, layer)">
                            <div class="preview-layer__clip" :style="layerClipStyle(layer)">
                              <img v-if="layer.image_url" class="preview-layer__image" :src="layer.image_url"
                                alt="Sticker preview" :style="layerImageStyle(layer)" />
                              <div v-else class="preview-layer__missing">Thiếu ảnh</div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div class="col-12 col-xl-7">
                      <div class="table-responsive">
                        <table class="table align-middle mb-0">
                          <thead>
                            <tr class="small opacity-75">
                              <th>Sticker</th>
                              <th>Vị trí</th>
                              <th>Kích thước in</th>
                              <th>Tọa độ X / Y</th>
                              <th>Góc xoay</th>
                              <th>Lớp (Z)</th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr v-for="layer in sortedLayers(item.layers)"
                              :key="`spec-${item.order_detail_id}-${layer.z_index}-${layer.sticker_id}`">
                              <td>
                                <div class="fw-semibold">{{ layer.sticker_name || "Sticker" }}</div>
                                <div class="small opacity-75">ID: {{ layer.sticker_id || "-" }}</div>
                              </td>
                              <td>{{ layer.position_label || "-" }}</td>
                              <td>
                                {{ formatMeasure(layer.render_width_mm) }} x
                                {{ formatMeasure(layer.render_height_mm) }} mm
                              </td>
                              <td>
                                {{ formatNumber(layer.x, 3) }} / {{ formatNumber(layer.y, 3) }}
                              </td>
                              <td>{{ formatNumber(layer.rotation_degrees, 2) }}°</td>
                              <td>{{ layer.z_index }}</td>
                            </tr>
                            <tr v-if="!item.layers?.length">
                              <td colspan="6" class="text-center opacity-75 py-4">
                                Không có lớp sticker nào trong thiết kế này.
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>

                      <div class="spec-grid mt-3">
                        <div class="spec-card">
                          <div class="spec-label">Khung vẽ (Canvas)</div>
                          <div class="spec-value">
                            {{ formatNumber(item.canvas_width_px, 0) }} x
                            {{ formatNumber(item.canvas_height_px, 0) }} px
                          </div>
                        </div>
                        <div class="spec-card">
                          <div class="spec-label">Số lớp sticker</div>
                          <div class="spec-value">{{ item.layers?.length || 0 }}</div>
                        </div>
                        <div class="spec-card">
                          <div class="spec-label">Đường dẫn ảnh xem trước</div>
                          <div class="spec-value text-break">
                            {{ item.preview_image_url || item.base_image_url || "-" }}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
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
import { onMounted, ref } from "vue";
import { useRoute } from "vue-router";
import Swal from "sweetalert2";

import OrderService from "@/services/order.service";
import { downloadFileBlob } from "@/utils/statistics-export";
import {
  normalizeEnumText,
  paymentStatusBadgeClass,
  paymentStatusLabel,
  refundSupportBadgeClass,
  refundSupportLabel,
  statusLabel,
  statusTableBadgeClass,
} from "@/utils/utils";

const route = useRoute();
const id = route.params.id;

const loading = ref(true);
const production = ref(null);
const exportingFormat = ref("");

function sortedLayers(layers) {
  return [...(layers || [])].sort((left, right) => {
    return Number(left?.z_index || 0) - Number(right?.z_index || 0);
  });
}

function showRefundBadge(refundStatus) {
  const value = normalizeEnumText(refundStatus);
  return Boolean(value) && value !== "none";
}

function formatMeasure(value) {
  return formatNumber(value, 2);
}

function formatNumber(value, digits = 2) {
  const numeric = Number(value);
  if (Number.isNaN(numeric)) return "-";
  return numeric.toFixed(digits);
}

function layerBoxStyle(item, layer) {
  const canvasWidth = Number(item?.canvas_width_px || 1);
  const canvasHeight = Number(item?.canvas_height_px || 1);
  return {
    left: `${((Number(layer?.left_px || 0) / canvasWidth) * 100).toFixed(4)}%`,
    top: `${((Number(layer?.top_px || 0) / canvasHeight) * 100).toFixed(4)}%`,
    width: `${((Number(layer?.box_size_px || 0) / canvasWidth) * 100).toFixed(4)}%`,
    height: `${((Number(layer?.box_size_px || 0) / canvasWidth) * 100).toFixed(4)}%`,
    transform: `rotate(${Number(layer?.rotation_degrees || 0)}deg)`,
  };
}

function layerClipStyle(layer) {
  const boxSize = Math.max(Number(layer?.box_size_px || 0), 1);
  return {
    left: `${((Number(layer?.visible_offset_x_px || 0) / boxSize) * 100).toFixed(4)}%`,
    top: `${((Number(layer?.visible_offset_y_px || 0) / boxSize) * 100).toFixed(4)}%`,
    width: `${((Number(layer?.visible_width_px || 0) / boxSize) * 100).toFixed(4)}%`,
    height: `${((Number(layer?.visible_height_px || 0) / boxSize) * 100).toFixed(4)}%`,
  };
}

function layerImageStyle(layer) {
  const visibleWidth = Math.max(Number(layer?.visible_width_px || 0), 1);
  const visibleHeight = Math.max(Number(layer?.visible_height_px || 0), 1);
  return {
    width: `${((Number(layer?.box_size_px || 0) / visibleWidth) * 100).toFixed(4)}%`,
    height: `${((Number(layer?.box_size_px || 0) / visibleHeight) * 100).toFixed(4)}%`,
    left: `-${((Number(layer?.visible_offset_x_px || 0) / visibleWidth) * 100).toFixed(4)}%`,
    top: `-${((Number(layer?.visible_offset_y_px || 0) / visibleHeight) * 100).toFixed(4)}%`,
  };
}

async function fetchProduction() {
  loading.value = true;
  try {
    production.value = await OrderService.getProduction(id);
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể tải dữ liệu sản xuất.";
    await Swal.fire("Lỗi", message, "error");
  } finally {
    loading.value = false;
  }
}

async function exportFile(format) {
  exportingFormat.value = format;
  try {
    const result = await OrderService.exportProduction(id, format, 300);
    downloadFileBlob(result.blob, result.filename);
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      `Không thể xuất file ${String(format).toUpperCase()}.`;
    await Swal.fire("Lỗi", message, "error");
  } finally {
    exportingFormat.value = "";
  }
}

onMounted(fetchProduction);
</script>

<style scoped>
/* Giữ nguyên các style cũ của bạn */
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.code-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.3rem 0.65rem;
  border-radius: 999px;
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

.btn-export,
.btn-export-outline {
  font-weight: 600;
}

.btn-export {
  border: 1px solid color-mix(in srgb, var(--status-danger) 40%, transparent);
  background: var(--status-danger-bg);
  color: var(--font-color);
}

.btn-export-outline {
  border: 1px solid color-mix(in srgb, var(--status-info) 45%, transparent);
  background: transparent;
  color: var(--font-color);
}

.production-item {
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  padding: 1rem;
  background: color-mix(in srgb, var(--main-extra-bg) 86%, white 14%);
}

.production-item__head {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.item-meta {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  color: var(--font-color);
}

.label {
  opacity: 0.7;
}

.preview-shell {
  padding: 1rem;
  border-radius: 1rem;
  border: 1px solid var(--border-color);
  background:
    radial-gradient(circle at top left, rgba(255, 255, 255, 0.65), rgba(255, 255, 255, 0)),
    linear-gradient(135deg, #f7f1e8, #e8eef8);
}

.preview-stage {
  position: relative;
  width: 100%;
  overflow: hidden;
  border-radius: 1rem;
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: rgba(255, 255, 255, 0.45);
}

.preview-base {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.preview-base--empty {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  font-size: 0.95rem;
}

.preview-layer {
  position: absolute;
  transform-origin: center center;
}

.preview-layer__clip {
  position: absolute;
  overflow: hidden;
}

.preview-layer__image {
  position: absolute;
  inset: 0 auto auto 0;
  object-fit: contain;
}

.preview-layer__missing {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.65rem;
  color: #6b7280;
  background: rgba(255, 255, 255, 0.7);
}

.spec-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.75rem;
}

.spec-card {
  padding: 0.85rem 0.95rem;
  border-radius: 0.85rem;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.26);
}

.spec-label {
  font-size: 0.82rem;
  opacity: 0.72;
  margin-bottom: 0.35rem;
}

.spec-value {
  font-weight: 600;
  word-break: break-word;
}
</style>