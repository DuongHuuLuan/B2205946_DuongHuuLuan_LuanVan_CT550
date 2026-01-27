<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Sản phẩm</h4>
          <div class="small opacity-75">Quản lý danh sách sản phẩm</div>
        </div>

        <RouterLink class="icon-btn icon-add" :to="{ name: 'products.create' }" title="Thêm sản phẩm">
          <i class="fa-solid fa-circle-plus"></i>
        </RouterLink>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md-6 col-lg-5">
              <div class="input-group">
                <span class="input-group-text bg-transparent">
                  <i class="fa-solid fa-magnifying-glass"></i>
                </span>
                <input v-model="keyword" type="text" class="form-control bg-transparent"
                  placeholder="Tìm theo tên sản phẩm..." />
                <button class="btn btn-outline-secondary" @click="keyword = ''" v-if="keyword" title="Clear">
                  <i class="fa-solid fa-xmark"></i>
                </button>
              </div>
            </div>

            <div class="col-12 col-md-6 col-lg-7 d-flex justify-content-md-end gap-2">
              <span class="badge bg-secondary-subtle text-secondary align-self-center">
                Tổng: {{ meta.total }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th class="ps-3" style="width: 140px">Mã SP</th>
                  <th style="width: 110px">Ảnh</th>
                  <th class="ps-5">Tên Sản Phẩm</th>
                  <th style="width: 180px">Đơn vị tính</th>
                  <th class="text-end pe-3" style="width: 160px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="p in items" :key="p.id">
                  <td class="ps-3">
                    <span class="code-pill">P{{ p.id }}</span>
                  </td>

                  <td class="text-start ps-0" style="width: 50px;">
                    <div class="thumb-wrap">
                      <img v-if="getFirstImage(p)" :src="getFirstImage(p)" class="thumb" :alt="p.name || 'product'" />
                      <div v-else class="thumb thumb-placeholder">
                        <i class="fa-regular fa-image"></i>
                      </div>
                    </div>
                  </td>

                  <td class="ps-5">
                    <RouterLink class="name-link" :to="{ name: 'products.detail', params: { id: p.id } }">
                      <div class="fw-semibold">{{ p.name }}</div>
                      <div class="small opacity-75">
                        Danh mục: {{ p?.category?.name || "—" }}
                      </div>
                    </RouterLink>
                  </td>

                  <!-- Unit -->
                  <td>
                    <span class="badge unit-badge">
                      {{ p.unit || "-" }}
                    </span>
                  </td>

                  <!-- Actions: edit + delete icons -->
                  <td class="text-end pe-3">
                    <div class="d-flex justify-content-end gap-2">
                      <RouterLink class="icon-btn icon-edit" :to="{ name: 'products.edit', params: { id: p.id } }"
                        title="Chỉnh sửa">
                        <i class="fa-solid fa-pen-to-square"></i>
                      </RouterLink>

                      <button class="icon-btn icon-delete" title="Xoá" @click="onDeleteClick(p.id)">
                        <i class="fa-solid fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="5" class="text-center py-5">
                    <div class="opacity-75">
                      <i class="fa-regular fa-folder-open fs-4 d-block mb-2"></i>
                      Không có sản phẩm phù hợp.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div class="d-flex justify-content-between align-items-center p-3 border-top" v-if="meta.total">
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
import { ref, watch, onMounted } from "vue";
import Swal from "sweetalert2";
import ProductService from "../../services/product.service";

const keyword = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });
const loading = ref(false);

function getFirstImage(product) {
  const first = product?.product_images?.[0];
  if (!first) return "";
  return first ? first.url : "";
}

async function fetchProducts() {
  loading.value = true;
  try {
    const res = await ProductService.getAll({
      q: keyword.value.trim() || undefined,
      page: page.value,
      per_page: perPage,
    });

    const list = res.items ?? [];
    items.value = Array.isArray(list) ? list : [];

    meta.value = res.meta ?? {
      current_page: 1,
      per_page: perPage,
      total: 0,
      last_page: 1,
    };
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải sản phẩm. Vui lòng thử lại!";
    Swal.fire("Lỗi", msg, "error");
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await fetchProducts();
});

watch(keyword, async () => {
  page.value = 1;
  await fetchProducts();
});

watch(page, async () => {
  await fetchProducts();
});

async function onDeleteClick(productId) {
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
      await ProductService.delete(productId);
      await fetchProducts();
      Swal.fire({ title: "Xóa thành công", icon: "success" });
    } catch (err) {
      await Swal.fire({
        title: "Lỗi",
        text: err?.response?.data?.message || "Không thể xóa",
        icon: "error",
      });
    }
  }
}
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

/* Badge cho đơn vị tính */
.unit-badge {
  background: color-mix(in srgb, var(--main-color) 10%, transparent);
  border: 1px solid var(--hover-border-color);
  color: var(--font-color);
  font-weight: 600;
}

/* Thumb */
.thumb-wrap {
  display: flex;
  align-items: start;
  justify-content: flex-start;
  margin-left: 0;
}

.thumb {
  width: 7rem;
  border-radius: 0.75rem;
  object-fit: cover;
  border: 1px solid var(--border-color);
  background: var(--main-extra-bg);
}

.thumb-placeholder {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  opacity: 0.7;
}

/* Icon buttons (only icons with color) */
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

.icon-add {
  color: #16a34a;
}

/* green */
.icon-edit {
  color: #f59e0b;
}

/* amber */
.icon-delete {
  color: #ef4444;
}

/* red */

/* cho icon add ở header to hơn chút */
.icon-add {
  width: 42px;
  height: 42px;
  border-radius: 1rem;
}
</style>
