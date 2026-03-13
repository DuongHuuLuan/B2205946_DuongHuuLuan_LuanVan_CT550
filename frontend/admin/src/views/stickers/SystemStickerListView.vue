<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Sticker hệ thống</h4>
          <div class="small opacity-75">Quản lý thư viện sticker dùng chung cho tất cả người dùng.</div>
        </div>

        <RouterLink class="icon-btn icon-add" :to="{ name: 'stickers.create' }" title="Thêm sticker mới">
          <i class="fa-solid fa-circle-plus"></i>
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md-6 col-lg-5">
              <SearchToggle v-model="keyword" placeholder="Tìm theo tên hoặc danh mục..." />
            </div>

            <div class="col-12 col-md-6 col-lg-7 d-flex justify-content-md-end gap-2">
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
                  <th style="min-width: 320px">Sticker</th>
                  <th style="min-width: 160px">Danh mục</th>
                  <th class="text-center" style="width: 120px">Trong suốt</th>
                  <th class="text-center" style="width: 120px">Đã dùng</th>
                  <th class="text-center" style="width: 160px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="sticker in items" :key="sticker.id">
                  <td class="ps-3">
                    <span class="code-pill">S{{ sticker.id }}</span>
                  </td>
                  <td>
                    <RouterLink class="sticker-link" :to="{ name: 'stickers.detail', params: { id: sticker.id } }">
                      <div class="d-flex align-items-center gap-3">
                        <div class="thumb">
                          <img v-if="sticker.image_url" :src="sticker.image_url" alt="Sticker" />
                          <div v-else class="thumb-placeholder">
                            <i class="fa-regular fa-image"></i>
                          </div>
                        </div>
                        <div>
                          <div class="fw-semibold">{{ sticker.name }}</div>
                        </div>
                      </div>
                    </RouterLink>
                  </td>
                  <td>
                    <span class="badge category-badge">{{ sticker.category || "-" }}</span>
                  </td>
                  <td class="text-center">
                    <span class="badge" :class="sticker.has_transparent_background ? 'flag-yes' : 'flag-no'">
                      {{ sticker.has_transparent_background ? "Có" : "Không" }}
                    </span>
                  </td>
                  <td class="text-center">
                    <span class="badge usage-badge">{{ sticker.usage_count ?? 0 }}</span>
                  </td>
                  <td class="text-center">
                    <div class="d-flex justify-content-center gap-2">
                      <RouterLink class="icon-btn icon-edit" :to="{ name: 'stickers.edit', params: { id: sticker.id } }"
                        title="Chỉnh sửa">
                        <i class="fa-solid fa-pen-to-square"></i>
                      </RouterLink>
                      <button class="icon-btn icon-delete" title="Xóa" :disabled="!sticker.can_delete"
                        @click="onDeleteClick(sticker)">
                        <i class="fa-solid fa-trash"></i>
                      </button>
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
import { onMounted, ref, watch } from "vue";
import Swal from "sweetalert2";

import SearchToggle from "@/components/common/SearchToggle.vue";
import StickerService from "@/services/sticker.service";

const keyword = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });

async function fetchStickers() {
  try {
    const response = await StickerService.getAll({
      q: keyword.value.trim() || undefined,
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

async function onDeleteClick(sticker) {
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
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
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
.usage-badge {
  background: color-mix(in srgb, var(--main-color) 14%, transparent);
  border: 1px solid var(--hover-border-color);
  color: var(--font-color);
  font-weight: 600;
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
</style>