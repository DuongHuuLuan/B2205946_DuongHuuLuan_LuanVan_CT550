<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết sản phẩm</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'products.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'products.edit', params: { id } }">
            <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
          </RouterLink>
          <button
            class="btn btn-outline-danger"
            type="button"
            :disabled="!canDelete"
            :title="canDelete ? 'Xóa' : 'Không thể xóa'"
            @click="onDelete"
          >
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

          <div v-else-if="!product" class="py-4 text-center opacity-75">
            Không tìm thấy sản phẩm.
          </div>

          <div v-else class="row g-3">
            <div class="col-12 col-lg-5">
              <label class="form-label d-flex align-items-center justify-content-between gap-2 flex-wrap">
                <span>Ảnh sản phẩm</span>
                <span v-if="activeImageGroup" class="small opacity-75">
                  {{ activeImageGroup.label }} ({{ activeImageGroup.count }} ảnh)
                </span>
              </label>

              <div v-if="imageColorGroups.length > 1" class="image-filter-list">
                <button type="button" class="image-filter"
                  :class="{ 'image-filter--active': activeImageColorKey === IMAGE_FILTER_ALL }"
                  @click="activeImageColorKey = IMAGE_FILTER_ALL">
                  Tất cả
                  <span class="image-filter__count">{{ images.length }}</span>
                </button>
                <button v-for="group in imageColorGroups" :key="group.key" type="button" class="image-filter"
                  :class="{ 'image-filter--active': activeImageColorKey === group.key }"
                  @click="activeImageColorKey = group.key">
                  {{ group.label }}
                  <span class="image-filter__count">{{ group.count }}</span>
                </button>
              </div>

              <div v-if="visibleImages.length" class="image-grid">
                <div v-for="img in visibleImages" :key="img.id || img.url" class="img-item">
                  <img :src="img.url" :alt="product.name || 'product'" />
                  <div class="img-meta">
                    <span v-if="showImageColorBadge" class="img-badge">
                      {{ imageColorLabel(img.color_id) }}
                    </span>
                    <span v-if="img.view_image_key" class="img-badge img-badge--accent">
                      {{ imageViewLabel(img.view_image_key) }}
                    </span>
                  </div>
                </div>
              </div>
              <div v-else class="img-empty">
                {{ images.length ? "Không có ảnh cho nhóm màu này." : "Không có ảnh." }}
              </div>
            </div>

            <div class="col-12 col-lg-7">
              <div class="mb-2">
                <span class="label">Tên:</span> {{ product.name || "-" }}
              </div>
              <div class="mb-2">
                <span class="label">Danh mục:</span>
                {{ product.category?.name || "-" }}
              </div>
              <div class="mb-2">
                <span class="label">Đơn vị:</span> {{ product.unit || "-" }}
              </div>
              <div class="mb-3">
                <span class="label">Mô tả:</span>
                <div class="text-muted mt-1">
                  {{ product.description || "-" }}
                </div>
              </div>
              <!-- <div class="mb-3">
                <span class="label">Model 3D:</span>
                <div class="text-muted mt-1">
                  <a v-if="product.model_3d_url" :href="product.model_3d_url" target="_blank" rel="noopener noreferrer">
                    {{ product.model_3d_url }}
                  </a>
                  <span v-else>-</span>
                </div>
              </div> -->

              <div class="table-responsive">
                <table class="table table-sm align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Màu</th>
                      <th>Kích thước</th>
                      <th class="text-end">Giá</th>
                    </tr>
                  </thead>
                  <tbody v-if="details.length">
                    <tr v-for="d in details" :key="d.id">
                      <td>{{ d.color?.name || "-" }}</td>
                      <td>{{ d.size?.size || "-" }}</td>
                      <td class="text-end">{{ d.price ?? "-" }}</td>
                    </tr>
                  </tbody>
                  <tbody v-else>
                    <tr>
                      <td colspan="3" class="text-center opacity-75 py-3">
                        Chưa có biến thể.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";
import ProductService from "@/services/product.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const product = ref(null);

const IMAGE_FILTER_ALL = "__all__";
const IMAGE_FILTER_NONE = "__none__";
const activeImageColorKey = ref("");

function normalizeImageColorKey(colorId) {
  return colorId === null || colorId === undefined || colorId === ""
    ? IMAGE_FILTER_NONE
    : String(colorId);
}

const images = computed(() => {
  const rawImages = Array.isArray(product.value?.product_images)
    ? [...product.value.product_images]
    : [];

  rawImages.sort((left, right) => {
    const leftColor = Number(left?.color_id || 0);
    const rightColor = Number(right?.color_id || 0);
    if (leftColor !== rightColor) return leftColor - rightColor;

    const keyOrder = {
      front: 0,
      front_right: 1,
      right: 2,
      back: 3,
      left: 4,
      front_left: 5,
    };
    const leftKey = keyOrder[String(left?.view_image_key || "").trim()] ?? 999;
    const rightKey = keyOrder[String(right?.view_image_key || "").trim()] ?? 999;
    if (leftKey !== rightKey) return leftKey - rightKey;

    return Number(left?.id || 0) - Number(right?.id || 0);
  });

  return rawImages;
});

const imageColorGroups = computed(() => {
  const groups = [];
  const groupMap = new Map();

  images.value.forEach((img) => {
    const key = normalizeImageColorKey(img?.color_id);
    if (!groupMap.has(key)) {
      const group = {
        key,
        colorId: img?.color_id ?? null,
        label: imageColorLabel(img?.color_id),
        count: 0,
      };
      groupMap.set(key, group);
      groups.push(group);
    }

    groupMap.get(key).count += 1;
  });

  return groups;
});

const visibleImages = computed(() => {
  if (!images.value.length) return [];
  if (activeImageColorKey.value === IMAGE_FILTER_ALL) return images.value;

  const effectiveColorKey = activeImageColorKey.value || imageColorGroups.value[0]?.key;
  if (!effectiveColorKey) return images.value;

  return images.value.filter(
    (img) => normalizeImageColorKey(img?.color_id) === effectiveColorKey
  );
});

const activeImageGroup = computed(() => {
  if (!images.value.length) return null;
  if (activeImageColorKey.value === IMAGE_FILTER_ALL) {
    return { label: "Tất cả màu", count: images.value.length };
  }

  return (
    imageColorGroups.value.find((group) => group.key === activeImageColorKey.value) ||
    imageColorGroups.value[0] ||
    null
  );
});

const details = computed(() => product.value?.product_details ?? []);
const canDelete = computed(() => Boolean(product.value) && product.value.can_delete !== false);
const showImageColorBadge = computed(
  () => imageColorGroups.value.length > 1 && activeImageColorKey.value === IMAGE_FILTER_ALL
);

watch(
  imageColorGroups,
  (groups) => {
    if (!groups.length) {
      activeImageColorKey.value = "";
      return;
    }

    const hasActiveGroup = groups.some((group) => group.key === activeImageColorKey.value);
    if (
      !activeImageColorKey.value ||
      (!hasActiveGroup && activeImageColorKey.value !== IMAGE_FILTER_ALL)
    ) {
      activeImageColorKey.value = groups[0].key;
    }
  },
  { immediate: true }
);

function imageColorLabel(colorId) {
  if (colorId === null || colorId === undefined) return "Không có màu";
  const detail = details.value.find(
    (item) => String(item?.color?.id ?? item?.color_id) === String(colorId)
  );
  return detail?.color?.name || `Màu #${colorId}`;
}

function imageViewLabel(viewKey) {
  const labels = {
    front: "Mặt trước",
    front_right: "Trước phải",
    right: "Bên phải",
    back: "Mặt sau",
    left: "Bên trái",
    front_left: "Trước trái",
  };
  return labels[String(viewKey || "").trim()] || "Ảnh thường";
}

async function fetchProduct() {
  loading.value = true;
  try {
    const res = await ProductService.get(props.id);
    product.value = res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải sản phẩm.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "products.list" });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
  if (!canDelete.value) {
    await Swal.fire(
      "Không thể xóa",
      product.value?.delete_block_reason || "Sản phẩm này không được phép xóa.",
      "info"
    );
    return;
  }

  const result = await Swal.fire({
    title: "Xóa sản phẩm này?",
    text: "Không thể hoàn tác!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xóa",
    cancelButtonText: "Hủy",
  });

  if (result.isConfirmed) {
    try {
      await ProductService.delete(props.id);
      await Swal.fire({ title: "Xóa thành công", icon: "success" });
      router.push({ name: "products.list" });
    } catch (err) {
      await Swal.fire({
        title: "Lỗi",
        text: err?.response?.data?.message || err?.response?.data?.detail || "Không thể xóa",
        icon: "error",
      });
    }
  }
}

onMounted(fetchProduct);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.label {
  font-weight: 600;
}

.image-filter-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}

.image-filter {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 7px 12px;
  border-radius: 999px;
  border: 1px solid var(--border-color);
  background: color-mix(in srgb, var(--main-extra-bg) 88%, transparent);
  color: var(--font-color);
  font-size: 13px;
  line-height: 1;
  transition:
    background-color 0.15s ease,
    border-color 0.15s ease,
    transform 0.15s ease;
}

.image-filter:hover {
  border-color: var(--hover-border-color);
  transform: translateY(-1px);
}

.image-filter--active {
  border-color: var(--hover-border-color);
  background: color-mix(in srgb, var(--main-color) 20%, var(--main-extra-bg));
}

.image-filter__count {
  min-width: 20px;
  padding: 3px 6px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.12);
  font-size: 11px;
  text-align: center;
}

.image-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 12px;
}

.img-item {
  position: relative;
  width: 100%;
  border-radius: 0.75rem;
  overflow: hidden;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.03);
}

.img-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.img-meta {
  position: absolute;
  left: 6px;
  right: 6px;
  bottom: 6px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.img-badge {
  padding: 4px 8px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.65);
  color: #fff;
  font-size: 12px;
  line-height: 1;
}

.img-badge--accent {
  background: rgba(13, 110, 253, 0.78);
}

.img-empty {
  padding: 16px;
  border-radius: 0.75rem;
  border: 1px dashed var(--border-color);
  color: var(--font-extra-color);
  text-align: center;
}
</style>
