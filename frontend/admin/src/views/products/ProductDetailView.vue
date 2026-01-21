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
          <button class="btn btn-outline-danger" type="button" @click="onDelete">
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
              <label class="form-label">Ảnh sản phẩm</label>
              <div v-if="images.length" class="image-grid">
                <div v-for="img in images" :key="img.id" class="img-item">
                  <img :src="img.url" :alt="product.name || 'product'" />
                </div>
              </div>
              <div v-else class="img-empty">Không có ảnh.</div>
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
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";
import ProductService from "@/services/product.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const product = ref(null);

const images = computed(() => product.value?.product_images ?? []);
const details = computed(() => product.value?.product_details ?? []);

async function fetchProduct() {
  loading.value = true;
  try {
    const res = await ProductService.get(props.id);
    product.value = res?.data ?? res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thế tải sản phẩm.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "products.list" });
  } finally {
    loading.value = false;
  }
}

async function onDelete() {
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
        text: err?.response?.data?.message || "Không thể xóa",
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

.image-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 12px;
}

.img-item {
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

.img-empty {
  padding: 16px;
  border-radius: 0.75rem;
  border: 1px dashed var(--border-color);
  color: var(--font-extra-color);
  text-align: center;
}
</style>
