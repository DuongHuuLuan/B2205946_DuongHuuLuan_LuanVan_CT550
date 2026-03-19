<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa sản phẩm</h4>
          <div class="small opacity-75">
            Cập nhật thông tin, Kích thước, màu và ảnh sản phẩm
          </div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'products.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Form -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <!-- Loading -->
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }">
            <div class="row g-3">
              <!-- name + unit -->
              <div class="col-12 col-md-8">
                <label class="form-label">Tên</label>
                <Field name="name" v-slot="{ field, meta, errors }">
                  <input v-bind="field" type="text" class="form-control bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" placeholder="Ví dụ: Nón bảo hiểm Royal M103..." />
                </Field>
                <ErrorMessage name="name" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label">Đơn vị tính</label>
                <Field name="unit" v-slot="{ field, meta, errors }">
                  <input v-bind="field" type="text" class="form-control bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" placeholder="Ví dụ: Chiếc / cái..." />
                </Field>
                <ErrorMessage name="unit" class="invalid-feedback d-block" />
              </div>

              <!-- category -->
              <div class="col-6">
                <label class="form-label">Danh mục sản phẩm</label>

                <input class="form-control bg-transparent mb-2" v-model="categoryKeyword"
                  placeholder="Gõ để tìm danh mục..." />

                <Field name="category_id" v-slot="{ field, meta, errors }">
                  <select v-bind="field" class="form-select bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" @change="selectedCategoryId = $event.target.value">
                    <option value="">-- Chọn danh mục --</option>
                    <option v-for="c in filteredCategories" :key="c.id" :value="c.id">
                      {{ c.name }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage name="category_id" class="invalid-feedback d-block" />
              </div>

              <!-- color -->
              <div class="col-6">
                <label class="form-label">Màu sản phẩm</label>

                <Field name="color_ids" v-slot="{ field, meta, errors, handleChange }">
                  <select class="form-select" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" multiple :name="field.name" :size="isColorOpen ? 6 : 1" @focus="isColorOpen = true" @blur="
                    (e) => {
                      isColorOpen = false;
                      field.onBlur(e);
                    }
                  " @change="(e) => onColorChange(e, handleChange)">
                    <option value="">Không có màu</option>
                    <option v-for="c in colors" :key="c.id" :value="String(c.id)"
                      :selected="field.value.includes(String(c.id))">
                      {{ c.name }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage name="color_ids" class="invalid-feedback d-block" />
              </div>

              <!-- description -->
              <div class="col-12">
                <label class="form-label">Mô tả</label>
                <Field name="description" v-slot="{ field, meta, errors }">
                  <textarea v-bind="field" rows="4" class="form-control bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" placeholder="Mô tả về sản phẩm..."></textarea>
                </Field>
                <ErrorMessage name="description" class="invalid-feedback d-block" />
              </div>

              <!-- <div class="col-12">
                <label class="form-label">URL model 3D (.glb)</label>
                <Field name="model_3d_url" v-slot="{ field, meta, errors }">
                  <input
                    v-bind="field"
                    type="url"
                    class="form-control bg-transparent"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    placeholder="https://your-api-host/static/models/helmet.glb"
                  />
                </Field>
                <div class="form-text">
                  Để trống để tắt luồng `Xem 3D` cho sản phẩm này. Nếu upload file mới, backend sẽ lưu trong `static/models`.
                </div>
                <ErrorMessage name="model_3d_url" class="invalid-feedback d-block" />
              </div> -->

              <div class="col-12">
                <label class="form-label">Upload model 3D (.glb)</label>
                <input ref="model3dFileInput" type="file" accept=".glb,model/gltf-binary,application/octet-stream"
                  class="form-control bg-transparent" @change="onModel3dFileChange" />
                <div class="form-text">
                  Chọn file mới nếu muốn thay model hiện tại.
                </div>
                <div v-if="model3dFileName" class="small mt-2 opacity-75">
                  Đã chọn: {{ model3dFileName }}
                </div>
              </div>

              <!-- variants -->
              <div class="col-12">
                <div class="d-flex align-items-center justify-content-between">
                  <div>
                    <label class="form-label mb-0">Biến thể sản phẩm</label>
                    <div class="small opacity-75 mt-1">
                      Biến thể đã có chỉ sửa được giá. Ảnh sản phẩm được quản lý riêng theo màu và góc chụp ở mục bên
                      dưới.
                    </div>
                  </div>
                  <button type="button" class="btn btn-sm btn-outline-secondary" @click="addVariant">
                    <i class="fa-solid fa-plus me-1"></i> Thêm biến thể
                  </button>
                </div>

                <div class="table-responsive mt-2">
                  <table class="table table-sm align-middle mb-0">
                    <thead>
                      <tr>
                        <th>Màu</th>
                        <th>Kích thước</th>
                        <th>Ảnh</th>
                        <th>Giá</th>
                        <th class="text-end">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody v-if="variants.length">
                      <tr v-for="(v, idx) in variants" :key="v.key">
                        <td>
                          <select class="form-select" v-model="v.color_id" :disabled="v.isExisting">
                            <option value="">Chọn màu</option>
                            <option v-for="c in colors" :key="c.id" :value="String(c.id)">
                              {{ c.name }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <select class="form-select" v-model="v.size_id" :disabled="v.isExisting">
                            <option value="">Chọn kích thước</option>
                            <option v-for="s in sizes" :key="s.id" :value="String(s.id)">
                              {{ s.size }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <div v-if="getVariantDisplayImage(v)" class="variant-thumb">
                            <img :src="getVariantDisplayImage(v)" alt="variant" />
                          </div>
                          <div v-else class="small opacity-75">
                            Chưa có ảnh
                          </div>
                        </td>
                        <td>
                          <input v-model="v.price" type="number" min="0" class="form-control bg-transparent"
                            placeholder="Giá" />
                        </td>
                        <td class="text-end">
                          <button type="button" class="btn btn-sm"
                            :class="canDelete ? 'btn-outline-danger' : 'btn-cannot-delete'" :disabled="!canDelete"
                            @click="removeVariant(idx)" :title="canDelete ? 'Xóa biến thể' : deleteBlockedMessage">
                            <i class="fa-solid" :class="canDelete ? 'fa-trash' : 'fa-lock'"></i>
                            <span class="ms-1 d-none d-xl-inline">
                              {{ canDelete ? "Xóa" : "Không thể xóa" }}
                            </span>
                          </button>
                        </td>
                      </tr>
                    </tbody>
                    <tbody v-else>
                      <tr>
                        <td colspan="5" class="text-center opacity-75 py-3">
                          Chưa có biến thể.
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div v-if="variantsError" class="invalid-feedback d-block mt-2">
                  {{ variantsError }}
                </div>
              </div>

              <div class="col-12">
                <div class="d-flex align-items-center justify-content-between">
                  <div>
                    <label class="form-label mb-0">Ảnh sản phẩm theo màu / góc chụp</label>

                  </div>
                  <button type="button" class="btn btn-sm btn-outline-secondary" @click="addImageEntry">
                    <i class="fa-solid fa-plus me-1"></i> Thêm ảnh
                  </button>
                </div>
                <div class="table-responsive mt-2">
                  <table class="table table-sm align-middle mb-0">
                    <thead>
                      <tr>
                        <th style="width: 200px">Màu</th>
                        <th style="width: 220px">Góc nhìn</th>
                        <th style="width: 120px">Xem trước</th>
                        <th>Ảnh</th>
                        <th class="text-end">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody v-if="activeImageEntries.length">
                      <tr v-for="entry in activeImageEntries" :key="entry.key">
                        <td>
                          <select class="form-select" v-model="entry.color_id" :disabled="entry.isExisting">
                            <option value="">Không có màu</option>
                            <option v-for="c in colors" :key="c.id" :value="String(c.id)">
                              {{ c.name }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <select class="form-select" v-model="entry.view_image_key">
                            <option v-for="option in viewImageKeyOptions" :key="option.value || 'default'"
                              :value="option.value">
                              {{ option.label }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <div v-if="getImageEntryDisplayImage(entry)" class="variant-thumb">
                            <img :src="getImageEntryDisplayImage(entry)" alt="product" />
                          </div>
                          <div v-else class="small opacity-75">Chưa có ảnh</div>
                        </td>
                        <td>
                          <input type="file" accept="image/*" class="form-control form-control-sm"
                            @change="(e) => onImageEntryFileChange(entry, e)" />
                          <div class="small opacity-75 mt-1" v-if="entry.isExisting">
                            Ảnh hiện có
                          </div>
                        </td>
                        <td class="text-end">
                          <button type="button" class="btn btn-sm"
                            :class="canDelete ? 'btn-outline-danger' : 'btn-cannot-delete'" :disabled="!canDelete"
                            @click="removeImageEntry(entry)" :title="canDelete ? 'Xóa ảnh' : deleteBlockedMessage">
                            <i class="fa-solid" :class="canDelete ? 'fa-trash' : 'fa-lock'"></i>
                          </button>
                        </td>
                      </tr>
                    </tbody>
                    <tbody v-else>
                      <tr>
                        <td colspan="5" class="text-center opacity-75 py-3">
                          Chưa có ảnh nào.
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div v-if="imageEntriesError" class="invalid-feedback d-block mt-2">
                  {{ imageEntriesError }}
                </div>
              </div>

            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ isSubmitting ? "Đang lưu..." : "Lưu thay đổi" }}
              </button>

              <button class="btn btn-outline-secondary" type="button" :disabled="isSubmitting"
                @click="onReset(resetForm)">
                <i class="fa-solid fa-rotate-left me-1"></i> Làm mới
              </button>
            </div>
          </Form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import ProductService from "@/services/product.service";
import CategoryService from "@/services/category.service";
import ColorService from "@/services/color.service";
import SizeService from "@/services/size.service";
import ProductDetailService from "@/services/product-detail.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;
const model3dFile = ref(null);
const model3dFileName = ref("");
const model3dFileInput = ref(null);

const loading = ref(true);
const formKey = ref(0);
const product = ref(null);

const categories = ref([]);
const colors = ref([]);
const sizes = ref([]);

const categoryKeyword = ref("");
const selectedCategoryId = ref("");

const initialValues = ref({
  name: "",
  description: "",
  model_3d_url: "",
  unit: "",
  category_id: "",
  color_ids: [], // auto chọn
});

// giữ bản gốc để reset ảnh
const variants = ref([]);
let variantSeq = 0;
const variantsError = ref("");
const viewImageKeyOptions = [
  { value: "", label: "Ảnh thường" },
  { value: "front", label: "Mặt trước" },
  { value: "front_right", label: "Trước phải" },
  { value: "right", label: "Bên phải" },
  { value: "back", label: "Mặt sau" },
  { value: "left", label: "Bên trái" },
  { value: "front_left", label: "Trước trái" },
];
const imageEntries = ref([]);
const originalImageEntries = ref([]);
const imageEntriesError = ref("");
let imageSeq = 0;

function normalizeViewImageKey(value) {
  return String(value ?? "").trim();
}

function cloneImageEntry(entry) {
  return {
    ...entry,
    image_file: null,
    image_preview: "",
    markedRemoved: false,
  };
}

function createImageEntry(data = {}) {
  imageSeq += 1;
  return {
    key: data.key ?? `image-${imageSeq}`,
    image_id: data.image_id ?? null,
    color_id:
      data.color_id !== null && data.color_id !== undefined
        ? String(data.color_id)
        : "",
    view_image_key: normalizeViewImageKey(data.view_image_key),
    original_view_image_key: normalizeViewImageKey(
      data.original_view_image_key ?? data.view_image_key
    ),
    image_url: data.image_url ?? "",
    image_file: null,
    image_preview: "",
    isExisting: Boolean(data.isExisting),
    markedRemoved: false,
  };
}

function clearImageEntryPreview(entry) {
  if (entry?.image_preview) {
    URL.revokeObjectURL(entry.image_preview);
  }
  entry.image_preview = "";
  entry.image_file = null;
}

function onImageEntryFileChange(entry, event) {
  const file = (event?.target?.files || [])[0] || null;
  clearImageEntryPreview(entry);
  if (file) {
    entry.image_file = file;
    entry.image_preview = URL.createObjectURL(file);
  }
}

function addImageEntry() {
  imageEntries.value.push(createImageEntry());
}

function removeImageEntry(entry) {
  if (!canDelete.value) return;
  clearImageEntryPreview(entry);
  if (entry.isExisting) {
    entry.markedRemoved = true;
    return;
  }
  imageEntries.value = imageEntries.value.filter((item) => item.key !== entry.key);
}

const activeImageEntries = computed(() =>
  imageEntries.value.filter((entry) => !entry.markedRemoved)
);

function clearModel3dFile() {
  model3dFile.value = null;
  model3dFileName.value = "";
  if (model3dFileInput.value) {
    model3dFileInput.value.value = "";
  }
}

function onModel3dFileChange(event) {
  const file = (event?.target?.files || [])[0] || null;
  model3dFile.value = file;
  model3dFileName.value = file?.name || "";
}

const removedVariantIds = ref(new Set());
const originalVariantPrices = ref(new Map());
const originalVariants = ref([]);

// New images

const isColorOpen = ref(false);

const filteredCategories = computed(() => {
  const kw = categoryKeyword.value.trim().toLowerCase();
  const list = categories.value || [];

  let arr = !kw
    ? list
    : list.filter((c) => (c.name || "").toLowerCase().includes(kw));

  if (selectedCategoryId.value) {
    const sel = list.find(
      (c) => String(c.id) === String(selectedCategoryId.value)
    );
    if (sel && !arr.some((c) => String(c.id) === String(sel.id))) {
      arr = [sel, ...arr];
    }
  }
  return arr;
});

const canDelete = computed(() => Boolean(product.value) && product.value.can_delete !== false);
const deleteBlockedMessage = computed(
  () =>
    product.value?.delete_block_reason ||
    "Sản phẩm này không được phép xóa vì đã phát sinh dữ liệu liên quan."
);

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên sản phẩm")
    .max(150, "Tên tối đa 150 ký tự"),
  description: yup
    .string()
    .trim()
    .nullable()
    .max(2000, "Mô tả tối đa 2000 ký tự")
    .required("Vui lòng nhập mô tả"),
  model_3d_url: yup
    .string()
    .trim()
    .nullable()
    .transform((value, originalValue) => {
      const normalized = String(originalValue ?? "").trim();
      return normalized === "" ? null : value;
    })
    .url("URL model 3D không hợp lệ")
    .max(2000, "URL model 3D tối đa 2000 ký tự"),
  unit: yup
    .string()
    .trim()
    .required("Vui lòng nhập đơn vị tính")
    .max(30, "Đơn vị tính tối đa 30 ký tự"),
  category_id: yup.string().required("Vui lòng chọn danh mục sản phẩm"),
  color_ids: yup.array().default([]), // để không bị undefined
});

// ---- Load data ----
async function getCategories() {
  const res = await CategoryService.getAll({ per_page: 200 });
  categories.value = res.items
}

async function getColors() {
  const res = await ColorService.getAll();
  colors.value = Array.isArray(res) ? res : [];
}

async function getSizes() {
  const res = await SizeService.getAll();
  sizes.value = Array.isArray(res) ? res : [];
}

async function getProduct() {
  return (async () => {
    try {
      const res = await ProductService.get(id);
      const p = res;
      product.value = p;

      let colorIds = Array.from(
        new Set(
          (p.product_details ?? [])
            .map((detail) => detail.color?.id ?? detail.color_id)
            .filter((value) => value !== null && value !== undefined)
            .map((value) => String(value))
        )
      );

      if (!colorIds.length) {
        const imageColorIds = (p?.product_images ?? [])
          .map((img) => img?.color_id)
          .filter((value) => value !== null && value !== undefined)
          .map((value) => String(value));
        colorIds = Array.from(new Set(imageColorIds));
      }

      const detailItems = p.product_details ?? [];
      variants.value = detailItems.map((d) => {
        const colorValue = d?.color?.id ?? d?.color_id;
        const sizeValue = d?.size?.id ?? d?.size_id;
        const colorKey =
          colorValue !== undefined && colorValue !== null
            ? String(colorValue)
            : "";
        return {
          key: d.id,
          id: d.id,
          color_id: colorKey,
          size_id:
            sizeValue !== undefined && sizeValue !== null ? String(sizeValue) : "",
          price: d?.price ?? "",
          isExisting: true,
        };
      });
      variantSeq = variants.value.length;
      originalVariantPrices.value = new Map(
        detailItems.map((d) => [d.id, d.price])
      );
      originalVariants.value = variants.value.map((v) => ({ ...v }));
      removedVariantIds.value = new Set();
      imageSeq = 0;
      imageEntries.value = (p?.product_images ?? []).map((image) =>
        createImageEntry({
          key: `existing-${image.id}`,
          image_id: image.id,
          color_id: image?.color_id,
          view_image_key: image?.view_image_key,
          original_view_image_key: image?.view_image_key,
          image_url: image?.url ?? "",
          isExisting: true,
        })
      );
      originalImageEntries.value = imageEntries.value.map((entry) =>
        cloneImageEntry(entry)
      );

      initialValues.value = {
        name: p?.name ?? "",
        description: p?.description ?? "",
        model_3d_url: p?.model_3d_url ?? "",
        unit: p?.unit ?? "",
        category_id: String(p?.category_id ?? ""),
        color_ids: colorIds,
      };

      selectedCategoryId.value = initialValues.value.category_id;

      formKey.value += 1;
    } catch (e) {
      console.log(e);
    }
  })();
}

async function fetchAll() {
  loading.value = true;
  try {
    await Promise.all([getCategories(), getColors(), getSizes(), getProduct()]);
  } catch (e) {
    console.log(e)
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

// ---- Color change ----
function onColorChange(e, handleChange) {
  const selected = Array.from(e.target.selectedOptions).map((o) => o.value);

  // chọn "" và màu khác -> chỉ giữ ""
  if (selected.includes("") && selected.length > 1) {
    Array.from(e.target.options).forEach(
      (opt) => (opt.selected = opt.value === "")
    );
    handleChange([""]);
    return;
  }

  handleChange(selected);
}

function addVariant() {
  variantSeq += 1;
  variants.value.push({
    key: `new-${variantSeq}`,
    color_id: "",
    size_id: "",
    price: "",
    isExisting: false,
  });
}

function removeVariant(index) {
  if (!canDelete.value) return;

  const v = variants.value[index];
  if (v?.id) {
    removedVariantIds.value.add(v.id);
  }
  variants.value.splice(index, 1);
}

function getVariantColorKey(variant) {
  const colorId = variant?.color_id;
  return colorId !== null && colorId !== undefined && colorId !== ""
    ? String(colorId)
    : "";
}

function getImageEntryColorKey(entry) {
  const colorId = entry?.color_id;
  return colorId !== null && colorId !== undefined && colorId !== ""
    ? String(colorId)
    : "";
}

function getImageEntryPriority(entry) {
  const key = normalizeViewImageKey(entry?.view_image_key);
  if (key === "front") return 0;
  if (!key) return 1;
  return 2;
}

function pickPrimaryImageEntry(entries) {
  const items = [...(entries || [])];
  if (!items.length) return null;
  items.sort((left, right) => {
    const priority = getImageEntryPriority(left) - getImageEntryPriority(right);
    if (priority !== 0) return priority;
    return String(left.key).localeCompare(String(right.key));
  });
  return items[0] || null;
}

function getImageEntryDisplayImage(entry) {
  return entry?.image_preview || entry?.image_url || "";
}

function getVariantDisplayImage(variant) {
  const colorKey = getVariantColorKey(variant);
  const sameColorImages = activeImageEntries.value.filter(
    (item) => getImageEntryColorKey(item) === colorKey
  );
  const genericImages = activeImageEntries.value.filter(
    (item) => !getImageEntryColorKey(item)
  );
  const chosen = pickPrimaryImageEntry(
    sameColorImages.length
      ? sameColorImages
      : genericImages.length
        ? genericImages
        : activeImageEntries.value
  );
  return getImageEntryDisplayImage(chosen);
}

function getVariantComboKey(colorId, sizeId) {
  return `${colorId}::${sizeId}`;
}

function getVariantComboLabel(colorId, sizeId) {
  const colorName =
    colors.value.find((item) => String(item.id) === String(colorId))?.name || `Màu #${colorId}`;
  const sizeName =
    sizes.value.find((item) => String(item.id) === String(sizeId))?.size || `Size #${sizeId}`;
  return `${colorName} / ${sizeName}`;
}

function getColorLabel(colorId) {
  if (colorId === null || colorId === undefined || colorId === "") {
    return "Không có màu";
  }
  return (
    colors.value.find((item) => String(item.id) === String(colorId))?.name ||
    `Màu #${colorId}`
  );
}

function getViewImageKeyLabel(viewImageKey) {
  const normalized = normalizeViewImageKey(viewImageKey);
  return (
    viewImageKeyOptions.find((option) => option.value === normalized)?.label ||
    "Ảnh thường"
  );
}

function collectVariants() {
  const invalid = [];
  const newVariants = [];
  const updates = [];
  const duplicateCombos = [];
  const seenCombos = new Set();
  const usedColorIds = new Set();
  let validCount = 0;

  variants.value.forEach((v) => {
    const hasAny = v.color_id || v.size_id || v.price !== "";
    const colorId = v.color_id ? Number(v.color_id) : null;
    const sizeId = v.size_id ? Number(v.size_id) : null;
    const price = v.price === "" || v.price === null ? null : Number(v.price);

    const isValid = colorId && sizeId && Number.isFinite(price);
    if (!isValid && hasAny) {
      invalid.push(v);
    }

    if (isValid) {
      const comboKey = getVariantComboKey(colorId, sizeId);
      if (seenCombos.has(comboKey)) {
        duplicateCombos.push(getVariantComboLabel(colorId, sizeId));
      } else {
        seenCombos.add(comboKey);
      }

      validCount += 1;
      usedColorIds.add(colorId);

      if (v.id) {
        const originalPrice = originalVariantPrices.value.get(v.id);
        if (originalPrice !== price) {
          updates.push({ id: v.id, price });
        }
      } else {
        newVariants.push({ color_id: colorId, size_id: sizeId, price });
      }
    }
  });

  return {
    invalid,
    newVariants,
    updates,
    validCount,
    duplicateCombos: [...new Set(duplicateCombos)],
    usedColorIds: [...usedColorIds],
  };
}

function collectImageChanges() {
  const invalid = [];
  const replaceImages = [];
  const newImages = [];
  const removeImageIds = [];
  const viewKeyUpdates = [];
  const duplicateViewKeys = [];
  const seenViewKeys = new Set();
  const colorIdsWithImages = new Set();
  let hasGenericImage = false;

  activeImageEntries.value.forEach((entry) => {
    const colorId = entry.color_id ? Number(entry.color_id) : null;
    const viewImageKey = normalizeViewImageKey(entry.view_image_key);
    const displayImage = getImageEntryDisplayImage(entry);

    if (displayImage) {
      if (colorId) {
        colorIdsWithImages.add(colorId);
      } else {
        hasGenericImage = true;
      }
    }

    if (viewImageKey) {
      const duplicateKey = `${colorId ?? "generic"}::${viewImageKey}`;
      if (seenViewKeys.has(duplicateKey)) {
        duplicateViewKeys.push(
          `${getColorLabel(colorId)} / ${getViewImageKeyLabel(viewImageKey)}`
        );
      } else {
        seenViewKeys.add(duplicateKey);
      }
    }

    if (entry.isExisting) {
      if (
        normalizeViewImageKey(entry.original_view_image_key) !== viewImageKey &&
        entry.image_id !== null &&
        entry.image_id !== undefined
      ) {
        viewKeyUpdates.push({
          image_id: entry.image_id,
          view_image_key: viewImageKey,
        });
      }
      if (entry.image_file && entry.image_id) {
        replaceImages.push({
          image_id: entry.image_id,
          file: entry.image_file,
        });
      }
      return;
    }

    const hasAny = entry.image_file || colorId !== null || viewImageKey;
    if (!hasAny) return;
    if (!entry.image_file) {
      invalid.push(entry);
      return;
    }

    newImages.push({
      file: entry.image_file,
      color_id: colorId,
      view_image_key: viewImageKey,
    });
  });

  imageEntries.value.forEach((entry) => {
    if (entry.isExisting && entry.markedRemoved && entry.image_id) {
      removeImageIds.push(entry.image_id);
    }
  });

  return {
    invalid,
    replaceImages,
    newImages,
    removeImageIds,
    viewKeyUpdates,
    duplicateViewKeys: [...new Set(duplicateViewKeys)],
    colorIdsWithImages,
    hasGenericImage,
  };
}

// ---- Reset ----
function onReset(resetFormFn) {
  resetFormFn({ values: { ...initialValues.value } });
  clearModel3dFile();

  imageEntries.value.forEach((entry) => clearImageEntryPreview(entry));
  imageEntries.value = originalImageEntries.value.map((entry) =>
    cloneImageEntry(entry)
  );
  variants.value = originalVariants.value.map((v) => ({ ...v }));
  variantSeq = variants.value.length;
  variantsError.value = "";
  imageEntriesError.value = "";
  removedVariantIds.value = new Set();
}

// ---- Submit ----
async function onSubmit(values, { setErrors }) {
  try {
    variantsError.value = "";
    imageEntriesError.value = "";
    const {
      invalid,
      newVariants,
      updates,
      validCount,
      duplicateCombos,
      usedColorIds,
    } = collectVariants();
    const {
      invalid: invalidImages,
      replaceImages,
      newImages,
      removeImageIds,
      viewKeyUpdates,
      duplicateViewKeys,
      colorIdsWithImages,
      hasGenericImage,
    } = collectImageChanges();
    if (invalid.length) {
      variantsError.value = "Vui lòng nhập đầy đủ màu, kích thước, và giá";
      return;
    }
    if (duplicateCombos.length) {
      variantsError.value = `Biến thể bị trùng màu và kích thước: ${duplicateCombos.join(", ")}`;
      return;
    }
    if (invalidImages.length) {
      imageEntriesError.value = "Vui lòng chọn file cho các ảnh mới đã thêm.";
      return;
    }
    if (duplicateViewKeys.length) {
      imageEntriesError.value = `Một màu không được gắn trùng góc nhìn: ${duplicateViewKeys.join(", ")}`;
      return;
    }
    const missingColorImages = usedColorIds.filter(
      (colorId) => !colorIdsWithImages.has(colorId) && !hasGenericImage
    );
    if (missingColorImages.length) {
      imageEntriesError.value = `Vui lòng thêm ảnh cho các màu: ${missingColorImages
        .map((colorId) => getColorLabel(colorId))
        .join(", ")}`;
      return;
    }
    if (!validCount) {
      variantsError.value = "Vui lòng thêm ít nhất một biến thể";
      return;
    }

    const fd = new FormData();
    fd.append("_method", "PUT");
    fd.append("name", values.name);
    fd.append("description", values.description || "");
    const rawModel3dUrl = values.model_3d_url?.trim() || "";
    if (rawModel3dUrl) {
      fd.append("model_3d_url", rawModel3dUrl);
    }
    if (model3dFile.value) {
      fd.append("model_3d_file", model3dFile.value);
    }
    fd.append("unit", values.unit);
    fd.append("category_id", values.category_id);

    const colorIds = Array.isArray(values.color_ids)
      ? values.color_ids.filter(Boolean)
      : [];
    colorIds.forEach((id) => fd.append("color_ids[]", id));

    replaceImages.forEach((img) => {
      fd.append(`replace_images[${img.image_id}]`, img.file);
    });
    viewKeyUpdates.forEach((item) => {
      fd.append(`view_image_keys[${item.image_id}]`, item.view_image_key || "");
    });
    newImages.forEach((img) => {
      fd.append("images[]", img.file);
      fd.append(
        "image_color_ids[]",
        img.color_id !== null && img.color_id !== undefined ? String(img.color_id) : ""
      );
      fd.append("new_view_image_keys[]", img.view_image_key || "");
    });
    removeImageIds.forEach((imageId) => fd.append("remove_image_ids[]", imageId));

    console.log("FormData entries:");
    for (const pair of fd.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }

    const updated = await ProductService.update(id, fd);
    let persistedProduct = updated;
    try {
      persistedProduct = await ProductService.get(id);
    } catch (verifyError) {
      console.log("Verify product after update failed:", verifyError);
    }
    const persistedModel3dUrl =
      persistedProduct?.model_3d_url ||
      persistedProduct?.model3dUrl ||
      updated?.model_3d_url ||
      updated?.model3dUrl ||
      "";
    if (model3dFile.value && !persistedModel3dUrl) {
      throw new Error("MODEL_3D_UPLOAD_FAILED");
    }

    const tasks = [];
    updates.forEach((u) => tasks.push(ProductDetailService.update(u.id, { price: u.price })));
    newVariants.forEach((v) => tasks.push(ProductDetailService.create(id, v)));
    removedVariantIds.value.forEach((variantId) =>
      tasks.push(ProductDetailService.delete(variantId))
    );

    if (tasks.length) {
      await Promise.all(tasks);
    }

    await Swal.fire("Thành công!", "Cập nhật sản phẩm thành công!", "success");
    clearModel3dFile();
    router.push({ name: "products.list" });
  } catch (e) {
    console.log(e);
    const status = e?.response?.status;
    const data = e?.response?.data;

    if (status === 422 && data?.errors) {
      const mapped = {};
      Object.keys(data.errors).forEach((k) => {
        mapped[k] = Array.isArray(data.errors[k])
          ? data.errors[k][0]
          : String(data.errors[k]);
      });
      setErrors(mapped);
      return;
    }

    const msg =
      e?.message === "MODEL_3D_UPLOAD_FAILED"
        ? "Lưu sản phẩm thành công nhưng model 3D chưa được ghi nhận. Hãy kiểm tra lại backend."
        :
        data?.message ||
        data?.error ||
        "Cập nhật sản phẩm thất bại. Vui lòng thử lại.";
    Swal.fire("Cập nhật sản phẩm thất bại", msg, "error");
  }
}

onMounted(async () => {
  await fetchAll();
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.btn-accent {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
}

.btn-accent:hover {
  filter: var(--brightness);
}

.variant-thumb {
  position: relative;
  width: 5rem;
  height: 5rem;
  border-radius: 0.6rem;
  overflow: hidden;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.03);
}

.variant-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.img-item {
  position: relative;
  width: 12rem;
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

.img-actions {
  position: absolute;
  left: 6px;
  right: 6px;
  bottom: 6px;
  display: flex;
  gap: 6px;
  justify-content: space-between;
}

.img-remove {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 24px;
  height: 24px;
  border: 0;
  border-radius: 0.5rem;
  background: rgba(0, 0, 0, 0.55);
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.img-remove:hover {
  filter: brightness(1.1);
}

.img-remove:disabled,
.img-remove--disabled {
  cursor: not-allowed;
  background: rgba(79, 79, 79, 0.7);
  color: rgba(255, 255, 255, 0.75);
  filter: none;
}

.img-item--deleted {
  opacity: 0.75;
  filter: grayscale(0.2);
}

.img-undo {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 0.5rem;
  background: rgba(0, 0, 0, 0.55);
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.img-undo:hover {
  filter: brightness(1.1);
}

.btn-cannot-delete {
  border: 1px solid color-mix(in srgb, var(--border-color) 85%, transparent);
  background: color-mix(in srgb, var(--main-extra-bg) 92%, #7f8c8d 8%);
  color: var(--font-extra-color);
}

.btn-cannot-delete:disabled {
  opacity: 1;
  cursor: not-allowed;
}
</style>
