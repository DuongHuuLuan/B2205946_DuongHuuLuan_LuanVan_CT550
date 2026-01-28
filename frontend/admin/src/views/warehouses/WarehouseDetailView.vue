<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết kho</h4>
          <div class="small opacity-75">
            Xem thông tin kho và danh sách tồn kho theo sản phẩm/màu
          </div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'warehouses.list' }">
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
              <div class="col-12 col-md-4">
                <label class="form-label">Địa chỉ kho</label>
                <div class="form-control bg-transparent">
                  {{ warehouse?.address || "—" }}
                </div>
              </div>

              <div class="col-12 col-md-2">
                <label class="form-label">SL tồn kho</label>
                <div class="d-flex align-items-center gap-2">
                  <span class="badge badge-completed">{{
                    warehouse?.total_quantity ?? 0
                  }}</span>
                </div>
              </div>

              <div class="col-12 col-md-2">
                <label class="form-label">Đang duyệt</label>
                <div class="d-flex align-items-center gap-2">
                  <span class="badge badge-pending">{{
                    warehouse?.pending_quantity ?? 0
                  }}</span>
                </div>
              </div>
            </div>

            <!-- Filters -->
            <div class="row g-2 mt-3">
              <div class="col-12 col-md-6">
                <input v-model="keyword" class="form-control bg-transparent" placeholder="Tìm theo tên sản phẩm..." />
              </div>

              <div class="col-12 col-md-4">
                <select v-model="categoryId" class="form-select bg-transparent">
                  <option value="">-- Tất cả danh mục --</option>
                  <option v-for="c in categories" :key="c.id" :value="String(c.id)">
                    {{ c.name }}
                  </option>
                </select>
              </div>

              <div class="col-12 col-md-2 d-flex gap-2">
                <button class="btn btn-outline-secondary w-100" type="button" @click="onClearFilters">
                  <i class="fa-solid fa-eraser me-1"></i> Xóa
                </button>
              </div>
            </div>

            <!-- Table -->
            <div class="mt-3">
              <div class="fw-semibold">Tồn kho theo sản phẩm</div>
              <div class="small opacity-75">
                Danh sách tồn kho theo sản phẩm
              </div>

              <div class="table-responsive mt-2">
                <table class="table align-middle mb-0">
                  <thead>
                    <tr class="small opacity-75">
                      <th style="min-width: 360px">Sản phẩm</th>
                      <th style="min-width: 200px">Màu</th>
                      <th style="min-width: 160px">Kích thước</th>
                      <th style="width: 140px">Số lượng</th>
                    </tr>
                  </thead>

                  <tbody>
                    <tr v-for="(it, idx) in items" :key="it.id || idx">
                      <!-- Product -->
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
                              ID: P{{
                                it?.product?.id || it?.product_id || "—"
                              }}
                            </div>
                            <div class="small opacity-75">
                              Danh mục: {{ it?.product?.category?.name || "—" }}
                            </div>
                          </div>
                        </div>
                      </td>

                      <!-- Color -->
                      <td>
                        <div class="form-control bg-transparent">
                          {{ it?.color?.name || "Khong co mau" }}
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
                          {{ it?.quantity ?? 0 }}
                        </div>
                      </td>
                    </tr>

                    <tr v-if="!items.length">
                      <td colspan="4" class="text-center opacity-75 py-4">
                        Không có dữ liệu.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- Pagination  -->
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

              <!-- Optional meta -->
              <div class="row g-3 mt-3" v-if="warehouse?.created_at || warehouse?.updated_at">
                <div class="col-12 col-md-6">
                  <div class="small opacity-75">Ngày tạo</div>
                  <div>{{ formatDateTimeVN(warehouse?.created_at) }}</div>
                </div>
                <div class="col-12 col-md-6">
                  <div class="small opacity-75">Cập nhật</div>
                  <div>{{ formatDateTimeVN(warehouse?.updated_at) }}</div>
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
import { computed, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";

import WarehouseService from "@/services/warehouse.service";
import CategoryService from "@/services/category.service";
import { formatDateTimeVN } from "@/utils/utils";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const warehouse = ref(null);

const items = ref([]);
const meta = ref({ current_page: 1, last_page: 1, per_page: 8, total: 0 });
const page = ref(1);
const perPage = 8;

const keyword = ref("");
const categoryId = ref("");
const categories = ref([]);


function getProductThumb(product) {
  return product?.product_images?.[0]?.url || product?.images?.[0]?.url || "";
}


async function fetchData() {
  loading.value = true;
  try {
    const res = await WarehouseService.getDetails(id, {
      page: page.value,
      per_page: perPage,
      q: keyword.value.trim(),
      category_id: categoryId.value || undefined,
    });

    const data = res ?? {};
    console.log(data);
    warehouse.value = data?.warehouse || null;
    items.value = data?.items || [];
    meta.value = data?.meta ?? {
      current_page: 1,
      per_page: perPage,
      total: 0,
      last_page: 1,
    };

    console.log(meta.value)
  } catch (e) {
    console.log(e);
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải dữ liệu kho.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "warehouses.list" });
  } finally {
    loading.value = false;
  }
}

watch(page, async () => {
  await fetchData();
});

function onClearFilters() {
  keyword.value = "";
  categoryId.value = "";
  fetchData(1);
}

// pagination list (window 5 pages)
const pageList = computed(() => {
  const cur = meta.value.current_page || 1;
  const last = meta.value.last_page || 1;

  const start = Math.max(1, cur - 2);
  const end = Math.min(last, cur + 2);

  const arr = [];
  for (let i = start; i <= end; i++) arr.push(i);
  return arr;
});

// debounce search
let t = null;
watch([keyword, categoryId], () => {
  clearTimeout(t);
  t = setTimeout(() => fetchData(1), 500);
});



onMounted(async () => {
  // categories for filter
  const cateRes = await CategoryService.getAll({ per_page: 200 });
  const payload = cateRes?.data ?? cateRes;
  categories.value = payload?.items || [];

  await fetchData(1);
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

/* thumb */
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

/* badges */
.badge {
  padding: 0.45rem 0.6rem;
  border-radius: 0.6rem;
  font-weight: 600;
}

.badge-pending {
  background: var(--status-warning-bg);
  border: 1px solid color-mix(in srgb, var(--status-warning) 55%, transparent);
  color: var(--status-warning);
}

.badge-completed {
  background: var(--status-success-bg);
  border: 1px solid color-mix(in srgb, var(--status-success) 55%, transparent);
  color: var(--status-success);
}

.badge-canceled {
  background: var(--status-danger-bg);
  border: 1px solid color-mix(in srgb, var(--status-danger) 55%, transparent);
  color: var(--status-danger);
}
</style>
