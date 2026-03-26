<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">{{ heading }}</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2 flex-wrap">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'stickers.list', query: listQuery }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink v-if="canEdit" class="btn btn-outline-secondary"
            :to="{ name: 'stickers.edit', params: { id }, query: route.query }">
            <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
          </RouterLink>
          <button v-if="canDeleteAction" class="btn btn-outline-danger" type="button" :disabled="!sticker?.can_delete"
            @click="onDelete">
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

          <div v-else-if="!sticker" class="py-4 text-center opacity-75">
            Không tìm thấy sticker.
          </div>

          <div v-else class="row g-4">
            <div class="col-12 col-lg-4">
              <div class="preview-shell">
                <img v-if="sticker.image_url" :src="sticker.image_url" alt="Sticker preview" />
                <div v-else class="preview-empty">
                  <i class="fa-regular fa-image fs-2 mb-2"></i>
                  <div>Không có đường dẫn ảnh (URL)</div>
                </div>
              </div>
            </div>

            <div class="col-12 col-lg-8">
              <div class="info-grid">
                <div class="info-item">
                  <div class="label">Tên sticker</div>
                  <div class="value">{{ sticker.name || "-" }}</div>
                </div>
                <div class="info-item">
                  <div class="label">Loại sticker</div>
                  <div class="value">
                    <span class="badge" :class="isUserSticker ? 'scope-user' : 'scope-system'">
                      {{ isUserSticker ? "Người dùng tạo" : "Hệ thống" }}
                    </span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="label">Người tạo</div>
                  <div class="value">{{ ownerLabel }}</div>
                </div>
                <div class="info-item">
                  <div class="label">Danh mục</div>
                  <div class="value">{{ sticker.category || "-" }}</div>
                </div>
                <div class="info-item">
                  <div class="label">Nền trong suốt</div>
                  <div class="value">
                    <span class="badge" :class="sticker.has_transparent_background ? 'flag-yes' : 'flag-no'">
                      {{ sticker.has_transparent_background ? "Có" : "Không" }}
                    </span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="label">Sticker AI</div>
                  <div class="value">
                    <span class="badge" :class="sticker.is_ai_generated ? 'flag-yes' : 'flag-no'">
                      {{ sticker.is_ai_generated ? "Có" : "Không" }}
                    </span>
                  </div>
                </div>

                <div class="info-item">
                  <div class="label">Đã được sử dụng</div>
                  <div class="value">{{ sticker.usage_count ?? 0 }} thiết kế</div>
                </div>
                <div class="info-item">
                  <div class="label">Có thể chỉnh sửa</div>
                  <div class="value">
                    <span class="badge" :class="canEdit ? 'flag-yes' : 'flag-no'">
                      {{ canEdit ? "Có" : "Không" }}
                    </span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="label">Có thể xóa</div>
                  <div class="value">
                    <span class="badge" :class="sticker.can_delete ? 'flag-yes' : 'flag-no'">
                      {{ sticker.can_delete ? "Có" : "Không" }}
                    </span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="label">Tạo lúc</div>
                  <div class="value">{{ formatDateTimeVN(sticker.created_at) }}</div>
                </div>
                <div class="info-item">
                  <div class="label">Cập nhật lúc</div>
                  <div class="value">{{ formatDateTimeVN(sticker.updated_at) }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";

import StickerService from "@/services/sticker.service";
import { formatDateTimeVN } from "@/utils/utils";

const props = defineProps({ id: String });
const id = props.id;
const route = useRoute();
const router = useRouter();

const loading = ref(true);
const sticker = ref(null);

const isUserSticker = computed(() => Boolean(sticker.value?.owner_user_id));
const canEdit = computed(() => Boolean(sticker.value?.can_edit));
const canDeleteAction = computed(() => !isUserSticker.value);
const showSystemDeleteWarning = computed(() => !isUserSticker.value && sticker.value && !sticker.value.can_delete);
const heading = computed(() => (isUserSticker.value ? "Chi tiết sticker người dùng tạo" : "Chi tiết sticker hệ thống"));
const listQuery = computed(() => (route.query.scope === "user" ? { scope: "user" } : {}));

const ownerLabel = computed(() => {
  if (!isUserSticker.value) return "Hệ thống";

  const ownerName = sticker.value?.owner_username?.trim();
  const ownerEmail = sticker.value?.owner_email?.trim();
  const ownerId = sticker.value?.owner_user_id;

  if (ownerName && ownerEmail) {
    return `${ownerName} (${ownerEmail})`;
  }
  if (ownerName) {
    return ownerName;
  }
  if (ownerEmail) {
    return ownerEmail;
  }
  if (ownerId) {
    return `Người dùng #${ownerId}`;
  }
  return "Người dùng";
});

async function fetchSticker() {
  loading.value = true;
  try {
    sticker.value = await StickerService.getAdmin(id);
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không tìm thấy dữ liệu sticker.";
    await Swal.fire("Lỗi", message, "error");
    router.push({ name: "stickers.list", query: listQuery.value });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
  if (!canDeleteAction.value) {
    await Swal.fire(
      "Chỉ xem",
      "Sticker do người dùng tạo chỉ được xem chi tiết trong màn quản trị này.",
      "info",
    );
    return;
  }

  if (!sticker.value?.can_delete) {
    await Swal.fire(
      "Không thể xóa",
      "Sticker này đã được người dùng sử dụng trong thiết kế.",
      "warning",
    );
    return;
  }

  const result = await Swal.fire({
    title: "Xóa sticker này?",
    text: "Hành động này không thể hoàn tác.",
    icon: "warning",
    showCancelButton: true,
    confirmButtonColor: "#d33",
    confirmButtonText: "Xóa ngay",
    cancelButtonText: "Hủy",
  });

  if (!result.isConfirmed) return;

  try {
    await StickerService.delete(id);
    await Swal.fire("Thành công", "Đã xóa sticker hệ thống.", "success");
    router.push({ name: "stickers.list", query: listQuery.value });
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể xóa sticker vào lúc này.";
    await Swal.fire("Lỗi", message, "error");
  }
}

onMounted(fetchSticker);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.preview-shell {
  min-height: 320px;
  border-radius: 1rem;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.preview-shell img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.preview-empty {
  opacity: 0.72;
  text-align: center;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 0.9rem;
}

.info-item {
  border: 1px solid var(--border-color);
  border-radius: 0.85rem;
  padding: 0.85rem 1rem;
  background: rgba(255, 255, 255, 0.16);
}

.label {
  font-size: 0.82rem;
  opacity: 0.72;
  margin-bottom: 0.35rem;
}

.value {
  font-weight: 600;
}

.break-all {
  word-break: break-all;
}

.flag-yes {
  background: var(--status-success-bg);
  border: 1px solid color-mix(in srgb, var(--status-success) 55%, transparent);
  color: var(--font-color);
}

.flag-no {
  background: var(--status-warning-bg);
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: var(--font-color);
}

.scope-system {
  background: color-mix(in srgb, #2563eb 16%, transparent);
  border: 1px solid color-mix(in srgb, #2563eb 45%, transparent);
  color: var(--font-color);
}

.scope-user {
  background: color-mix(in srgb, #f97316 16%, transparent);
  border: 1px solid color-mix(in srgb, #f97316 45%, transparent);
  color: var(--font-color);
}
</style>
