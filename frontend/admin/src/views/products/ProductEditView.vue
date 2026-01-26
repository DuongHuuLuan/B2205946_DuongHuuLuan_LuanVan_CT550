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

              <!-- variants -->
              <div class="col-12">
                <div class="d-flex align-items-center justify-content-between">
                  <label class="form-label mb-0">Biến thể sản phẩm</label>
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
                          <div class="d-flex flex-column gap-2">
                            <input type="file" accept="image/*" class="form-control form-control-sm"
                              @change="(e) => onVariantImageChange(v, e)" />
                            <div v-if="v.image_preview || v.image_url" class="variant-thumb">
                              <img :src="v.image_preview || v.image_url" alt="variant" />
                              <button type="button" class="img-remove" @click="clearVariantImage(v)" title="Xóa ảnh">
                                <i class="fa-solid fa-xmark"></i>
                              </button>
                            </div>
                          </div>
                        </td>
                        <td>
                          <input v-model="v.price" type="number" min="0" class="form-control bg-transparent"
                            placeholder="Giá" />
                        </td>
                        <td class="text-end">
                          <button type="button" class="btn btn-sm btn-outline-danger" @click="removeVariant(idx)">
                            <i class="fa-solid fa-trash"></i>
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

const loading = ref(true);
const formKey = ref(0);

const categories = ref([]);
const colors = ref([]);
const sizes = ref([]);

const categoryKeyword = ref("");
const selectedCategoryId = ref("");

const initialValues = ref({
  name: "",
  description: "",
  unit: "",
  category_id: "",
  color_ids: [], // auto chọn
});

// giữ bản gốc để reset ảnh
const variants = ref([]);
let variantSeq = 0;
const variantsError = ref("");

function clearVariantImage(variant) {
  if (variant?.image_preview) {
    URL.revokeObjectURL(variant.image_preview);
  }
  variant.image_preview = "";
  variant.image_file = null;
}

function onVariantImageChange(variant, e) {
  const file = (e.target.files || [])[0] || null;
  clearVariantImage(variant);
  if (file) {
    variant.image_file = file;
    variant.image_preview = URL.createObjectURL(file);
  }
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
  console.log("Loaded categories:", res);
}

async function getColors() {
  const res = await ColorService.getAll();
  colors.value = Array.isArray(res) ? res : [];
  console.log("Loaded color:", colors.value);
}

async function getSizes() {
  const res = await SizeService.getAll();
  sizes.value = Array.isArray(res) ? res : [];
  console.log("Loaded sizes:", sizes.value);
}

async function getProduct() {
  return (async () => {
    try {
      const res = await ProductService.get(id);
      const p = res;

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

      const imageMap = new Map();
      (p?.product_images ?? []).forEach((im) => {
        if (im?.color_id === null || im?.color_id === undefined) return;
        const key = String(im.color_id);
        if (!imageMap.has(key)) {
          imageMap.set(key, im);
        }
      });

      const detailItems = p.product_details ?? [];
      variants.value = detailItems.map((d) => {
        const colorValue = d?.color?.id ?? d?.color_id;
        const sizeValue = d?.size?.id ?? d?.size_id;
        const colorKey =
          colorValue !== undefined && colorValue !== null
            ? String(colorValue)
            : "";
        const image = colorKey ? imageMap.get(colorKey) : null;
        return {
          key: d.id,
          id: d.id,
          color_id: colorKey,
          size_id:
            sizeValue !== undefined && sizeValue !== null ? String(sizeValue) : "",
          price: d?.price ?? "",
          isExisting: true,
          image_id: image?.id ?? null,
          image_url: image?.url ?? "",
          image_file: null,
          image_preview: "",
        };
      });
      variantSeq = variants.value.length;
      originalVariantPrices.value = new Map(
        detailItems.map((d) => [d.id, d.price])
      );
      originalVariants.value = variants.value.map((v) => ({ ...v }));
      removedVariantIds.value = new Set();

      initialValues.value = {
        name: p?.name ?? "",
        description: p?.description ?? "",
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
    image_id: null,
    image_url: "",
    image_file: null,
    image_preview: "",
  });
}

function removeVariant(index) {
  const v = variants.value[index];
  if (v) {
    clearVariantImage(v);
  }
  if (v?.id) {
    removedVariantIds.value.add(v.id);
  }
  variants.value.splice(index, 1);
}

function collectVariants() {
  const invalid = [];
  const newVariants = [];
  const updates = [];
  const missingImage = [];
  const imageUploads = [];
  let validCount = 0;

  variants.value.forEach((v) => {
    const hasAny = v.color_id || v.size_id || v.price !== "" || v.image_file;
    const colorId = v.color_id ? Number(v.color_id) : null;
    const sizeId = v.size_id ? Number(v.size_id) : null;
    const price = v.price === "" || v.price === null ? null : Number(v.price);

    const isValid = colorId && sizeId && Number.isFinite(price);
    if (!isValid && hasAny) {
      invalid.push(v);
    }

    if (isValid) {
      validCount += 1;
      if (!v.image_url && !v.image_file) {
        missingImage.push(v);
      }

      if (v.image_file) {
        imageUploads.push({
          file: v.image_file,
          color_id: colorId,
          image_id: v.image_id,
        });
      }

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

  return { invalid, newVariants, updates, validCount, missingImage, imageUploads };
}

// ---- Reset ----
function onReset(resetFormFn) {
  resetFormFn({ values: { ...initialValues.value } });

  variants.value.forEach((v) => clearVariantImage(v));
  variants.value = originalVariants.value.map((v) => ({
    ...v,
    image_file: null,
    image_preview: "",
  }));
  variantSeq = variants.value.length;
  variantsError.value = "";
  removedVariantIds.value = new Set();
}

// ---- Submit ----
async function onSubmit(values, { setErrors }) {
  try {
    variantsError.value = "";
    const { invalid, newVariants, updates, validCount, missingImage, imageUploads } = collectVariants();
    if (invalid.length) {
      variantsError.value = "Vui lòng nhập đầy đủ màu, kích thước, và giá";
      return;
    }
    if (missingImage.length) {
      variantsError.value = "Vui lòng chọn ảnh cho từng biến thể";
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
    fd.append("unit", values.unit);
    fd.append("category_id", values.category_id);

    const colorIds = Array.isArray(values.color_ids)
      ? values.color_ids.filter(Boolean)
      : [];
    colorIds.forEach((id) => fd.append("color_ids[]", id));

    imageUploads.forEach((img) => {
      if (img.image_id) {
        fd.append(`replace_images[${img.image_id}]`, img.file);
      } else {
        fd.append("images[]", img.file);
        fd.append("image_color_ids[]", img.color_id);
      }
    });

    console.log("FormData entries:");
    for (const pair of fd.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }

    await ProductService.update(id, fd);

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

/* variant image */
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

/* image blocks */
.img-item {
  position: relative;
  width: 12rem;
  /* height: 8rem; */
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

/* actions overlay */
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
</style>
