<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Quản lý sticker</h4>
          <div class="small opacity-75">{{ scopeDescription }}</div>
        </div>

        <RouterLink v-if="scope !== 'user'" class="icon-btn icon-add" :to="{ name: 'stickers.create' }"
          title="Thêm sticker hệ thống">
          <i class="fa-solid fa-circle-plus"></i>
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-lg-4">
              <SearchToggle v-model="keyword" placeholder="Tìm theo tên, danh mục hoặc người tạo..." />
            </div>

            <div class="col-12 col-lg-5">
              <div class="scope-switch">
                <button v-for="option in scopeOptions" :key="option.value" type="button" class="scope-btn"
                  :class="{ active: scope === option.value }" @click="applyScope(option.value)">
                  {{ option.label }}
                </button>
              </div>
            </div>

            <div class="col-12 col-lg-3 d-flex justify-content-lg-end gap-2">
              <span class="badge bg-secondary-subtle text-secondary align-self-center">
                Tổng cộng: {{ meta.total }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th class="ps-3" style="width: 120px">Mã</th>
                  <th style="min-width: 360px">Sticker</th>
                  <th style="min-width: 160px">Danh mục</th>
                  <th style="width: 160px">Loại</th>
                  <th class="text-center" style="width: 120px">Đã dùng</th>
                  <th class="text-center" style="width: 180px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="sticker in items" :key="sticker.id">
                  <td class="ps-3">
                    <span class="code-pill">S{{ sticker.id }}</span>
                  </td>
                  <td>
                    <RouterLink class="sticker-link" :to="detailRouteFor(sticker)">
                      <div class="d-flex align-items-center gap-3">
                        <div class="thumb">
                          <img v-if="sticker.image_url" :src="sticker.image_url" alt="Sticker" />
                          <div v-else class="thumb-placeholder">
                            <i class="fa-regular fa-image"></i>
                          </div>
                        </div>
                        <div>
                          <div class="d-flex align-items-center gap-2 flex-wrap">
                            <div class="fw-semibold">{{ sticker.name }}</div>
                            <span class="badge scope-badge"
                              :class="isSystemSticker(sticker) ? 'scope-system' : 'scope-user'">
                              {{ isSystemSticker(sticker) ? "Hệ thống" : "Người dùng tạo" }}
                            </span>
                          </div>
                          <div v-if="sticker.owner_user_id" class="small text-muted mt-1">
                            {{ formatOwnerLabel(sticker) }}
                          </div>
                        </div>
                      </div>
                    </RouterLink>
                  </td>
                  <td>
                    <span class="badge category-badge">{{ sticker.category || "-" }}</span>
                  </td>
                  <td>
                    <span class="badge scope-badge"
                      :class="Boolean(sticker.is_ai_generated) ? 'scope-ai' : 'scope-manual'">
                      {{ sticker.is_ai_generated ? "AI" : "Thường" }}
                    </span>
                  </td>
                  <td class="text-center">
                    <span class="badge usage-badge">{{ sticker.usage_count ?? 0 }}</span>
                  </td>
                  <td class="text-center">
                    <div class="d-flex justify-content-center gap-2">
                      <RouterLink class="icon-btn icon-view" :to="detailRouteFor(sticker)" title="Chi tiết">
                        <i class="fa-solid fa-eye"></i>
                      </RouterLink>
                      <template v-if="isSystemSticker(sticker)">
                        <RouterLink class="icon-btn icon-edit"
                          :to="{ name: 'stickers.edit', params: { id: sticker.id }, query: detailQueryFor(sticker) }"
                          title="Chỉnh sửa">
                          <i class="fa-solid fa-pen-to-square"></i>
                        </RouterLink>
                        <button class="icon-btn icon-delete" title="Xóa" :disabled="!sticker.can_delete"
                          @click="onDeleteClick(sticker)">
                          <i class="fa-solid fa-trash"></i>
                        </button>
                      </template>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="6" class="text-center py-5">
                    <div class="opacity-75">
                      <i class="fa-regular fa-note-sticky fs-4 d-block mb-2"></i>
                      Không tìm thấy sticker phù hợp.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="d-flex justify-content-between align-items-center p-3 border-top" v-if="meta.total">
            <div class="small opacity-75">
              Hiển thị
              {{ (meta.current_page - 1) * meta.per_page + 1 }}
              -
              {{ Math.min(meta.current_page * meta.per_page, meta.total) }}
              trên tổng số
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
import { computed, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";

import SearchToggle from "@/components/common/SearchToggle.vue";
import StickerService from "@/services/sticker.service";

const route = useRoute();
const router = useRouter();

const scopeOptions = [
  { value: "system", label: "Sticker hệ thống" },
  { value: "user", label: "Người dùng tạo" },
];

function normalizeScope(value) {
  return value === "user" ? "user" : "system";
}

function buildScopeQuery(value = scope.value) {
  const normalized = normalizeScope(value);
  return normalized === "system" ? {} : { scope: normalized };
}

const keyword = ref("");
const scope = ref(normalizeScope(route.query.scope));
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });

const scopeDescription = computed(() =>
  scope.value === "system"
    ? "Danh sách sticker dùng chung cho tất cả người dùng."
    : "Danh sách sticker do người dùng tạo."
);

function isSystemSticker(sticker) {
  return !sticker?.owner_user_id;
}

function detailQueryFor(sticker) {
  return isSystemSticker(sticker) ? buildScopeQuery(scope.value) : { scope: "user" };
}

function detailRouteFor(sticker) {
  return {
    name: "stickers.detail",
    params: { id: sticker.id },
    query: detailQueryFor(sticker),
  };
}

function formatOwnerLabel(sticker) {
  const ownerName = sticker?.owner_username?.trim();
  const ownerEmail = sticker?.owner_email?.trim();
  const ownerId = sticker?.owner_user_id;

  if (ownerName && ownerEmail) {
    return `Tạo bởi: ${ownerName} (${ownerEmail})`;
  }
  if (ownerName) {
    return `Tạo bởi: ${ownerName}`;
  }
  if (ownerEmail) {
    return `Tạo bởi: ${ownerEmail}`;
  }
  if (ownerId) {
    return `Tạo bởi người dùng #${ownerId}`;
  }
  return "Sticker hệ thống";
}

async function fetchStickers() {
  try {
    const response = await StickerService.getAdminList({
      q: keyword.value.trim() || undefined,
      scope: scope.value,
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
      "Không thể tải danh sách sticker.";
    await Swal.fire("Lỗi", message, "error");
  }
}

async function applyScope(nextScope) {
  const normalized = normalizeScope(nextScope);
  if (scope.value === normalized) return;

  scope.value = normalized;
  await router.replace({ query: buildScopeQuery(normalized) });
  if (page.value !== 1) {
    page.value = 1;
    return;
  }
  await fetchStickers();
}

async function onDeleteClick(sticker) {
  if (!isSystemSticker(sticker)) {
    await Swal.fire(
      "Chỉ xem",
      "Sticker do người dùng tạo chỉ được xem chi tiết trong màn quản trị này.",
      "info",
    );
    return;
  }

  if (!sticker?.can_delete) {
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
    confirmButtonText: "Xóa ngay",
    cancelButtonText: "Hủy bỏ",
  });

  if (!result.isConfirmed) return;

  try {
    await StickerService.delete(sticker.id);
    await Swal.fire("Thành công", "Đã xóa sticker thành công.", "success");
    await fetchStickers();
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể xóa sticker vào lúc này.";
    await Swal.fire("Lỗi", message, "error");
  }
}

onMounted(fetchStickers);

watch(keyword, async () => {
  page.value = 1;
  await fetchStickers();
});

watch(page, async () => {
  await fetchStickers();
});

watch(
  () => route.query.scope,
  async (value) => {
    const normalized = normalizeScope(value);
    if (normalized === scope.value) return;
    scope.value = normalized;
    if (page.value !== 1) {
      page.value = 1;
      return;
    }
    await fetchStickers();
  },
);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.scope-switch {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.scope-btn {
  border: 1px solid var(--border-color);
  background: transparent;
  color: var(--font-color);
  border-radius: 999px;
  padding: 0.5rem 0.9rem;
  font-weight: 600;
  transition: 0.12s ease;
}

.scope-btn:hover {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}

.scope-btn.active {
  background: color-mix(in srgb, var(--main-color) 16%, transparent);
  border-color: var(--hover-border-color);
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

.icon-btn:hover:not(:disabled) {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}

.icon-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.icon-add {
  color: #16a34a;
  width: 42px;
  height: 42px;
  border-radius: 1rem;
}

.icon-view {
  color: #2563eb;
}

.icon-edit {
  color: #f59e0b;
}

.icon-delete {
  color: #ef4444;
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

.sticker-link {
  text-decoration: none;
  color: inherit;
}

.thumb {
  width: 4.5rem;
  height: 4.5rem;
  border-radius: 0.85rem;
  border: 1px solid var(--border-color);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.24);
  flex: 0 0 auto;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  padding: 0.35rem;
}

.thumb-placeholder {
  opacity: 0.6;
}

.category-badge,
.usage-badge,
.scope-badge {
  border: 1px solid var(--hover-border-color);
  color: var(--font-color);
  font-weight: 600;
}

.category-badge,
.usage-badge {
  background: color-mix(in srgb, var(--main-color) 14%, transparent);
}

.scope-system {
  background: color-mix(in srgb, #2563eb 16%, transparent);
  border-color: color-mix(in srgb, #2563eb 45%, transparent);
}

.scope-user {
  background: color-mix(in srgb, #f97316 16%, transparent);
  border-color: color-mix(in srgb, #f97316 45%, transparent);
}

.scope-ai {
  background: color-mix(in srgb, #8b5cf6 16%, transparent);
  border-color: color-mix(in srgb, #8b5cf6 45%, transparent);
}

.scope-manual {
  background: color-mix(in srgb, #64748b 16%, transparent);
  border-color: color-mix(in srgb, #64748b 45%, transparent);
}
</style>
