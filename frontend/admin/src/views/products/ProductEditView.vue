<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Chỉnh sửa sản phẩm</h4>
          <div class="small opacity-75">
            Cập nhật thông tin, màu và ảnh sản phẩm
          </div>
        </div>

        <RouterLink
          class="btn btn-outline-secondary"
          :to="{ name: 'products.list' }"
        >
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

          <Form
            v-else
            :key="formKey"
            :initial-values="initialValues"
            :validation-schema="schema"
            @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }"
          >
            <div class="row g-3">
              <!-- name + unit -->
              <div class="col-12 col-md-8">
                <label class="form-label">Tên</label>
                <Field name="name" v-slot="{ field, meta, errors }">
                  <input
                    v-bind="field"
                    type="text"
                    class="form-control bg-transparent"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    placeholder="Ví dụ: Bút bi Thiên Long..."
                  />
                </Field>
                <ErrorMessage name="name" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label">Đơn vị tính</label>
                <Field name="unit" v-slot="{ field, meta, errors }">
                  <input
                    v-bind="field"
                    type="text"
                    class="form-control bg-transparent"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    placeholder="Ví dụ: cây / quyển..."
                  />
                </Field>
                <ErrorMessage name="unit" class="invalid-feedback d-block" />
              </div>

              <!-- category -->
              <div class="col-6">
                <label class="form-label">Danh mục sản phẩm</label>

                <input
                  class="form-control bg-transparent mb-2"
                  v-model="categoryKeyword"
                  placeholder="Gõ để tìm danh mục..."
                />

                <Field name="category_id" v-slot="{ field, meta, errors }">
                  <select
                    v-bind="field"
                    class="form-select bg-transparent"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    @change="selectedCategoryId = $event.target.value"
                  >
                    <option value="">-- Chọn danh mục --</option>
                    <option
                      v-for="c in filteredCategories"
                      :key="c.id"
                      :value="c.id"
                    >
                      {{ c.name }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage
                  name="category_id"
                  class="invalid-feedback d-block"
                />
              </div>

              <!-- color -->
              <div class="col-6">
                <label class="form-label">Màu sản phẩm</label>

                <Field
                  name="color_ids"
                  v-slot="{ field, meta, errors, handleChange }"
                >
                  <select
                    class="form-select"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    multiple
                    :name="field.name"
                    :size="isColorOpen ? 6 : 1"
                    @focus="isColorOpen = true"
                    @blur="
                      (e) => {
                        isColorOpen = false;
                        field.onBlur(e);
                      }
                    "
                    @change="(e) => onColorChange(e, handleChange)"
                  >
                    <option value="">Không có màu</option>
                    <option
                      v-for="c in colors"
                      :key="c.id"
                      :value="String(c.id)"
                      :selected="field.value.includes(String(c.id))"
                    >
                      {{ c.color_name }}
                    </option>
                  </select>
                </Field>

                <ErrorMessage
                  name="color_ids"
                  class="invalid-feedback d-block"
                />
              </div>

              <!-- des -->
              <div class="col-12">
                <label class="form-label">Mô tả</label>
                <Field name="des" v-slot="{ field, meta, errors }">
                  <textarea
                    v-bind="field"
                    rows="4"
                    class="form-control bg-transparent"
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    placeholder="Mô tả về sản phẩm..."
                  ></textarea>
                </Field>
                <ErrorMessage name="des" class="invalid-feedback d-block" />
              </div>

              <!-- Existing images -->
              <div class="col-12">
                <label class="form-label">Ảnh hiện có</label>

                <div
                  v-if="!existingImagesVisible.length"
                  class="small opacity-75"
                >
                  Không có ảnh hiện có.
                </div>

                <div v-else class="d-flex flex-wrap gap-2 mt-2">
                  <div
                    v-for="img in existingImagesVisible"
                    :key="img.id"
                    class="img-item"
                  >
                    <img
                      :src="img.replacePreview || img.url"
                      alt="product-image"
                    />

                    <!-- hidden input replace -->
                    <input
                      type="file"
                      accept="image/*"
                      class="d-none"
                      :ref="(el) => setReplaceInputRef(img.id, el)"
                      @change="(e) => onReplaceExisting(img.id, e)"
                    />

                    <div class="img-actions">
                      <button
                        type="button"
                        class="btn btn-sm btn-light"
                        @click="triggerReplace(img.id)"
                        title="Thay ảnh"
                      >
                        <i class="fa-solid fa-pen-to-square me-1"></i> Thay
                      </button>

                      <button
                        type="button"
                        class="btn btn-sm btn-danger"
                        @click="markDeleteExisting(img.id)"
                        title="Xóa ảnh"
                      >
                        <i class="fa-solid fa-trash me-1"></i> Xóa
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Deleted list (undo) -->
                <div v-if="deletedExistingImages.length" class="mt-3">
                  <div class="small opacity-75 mb-1">Ảnh sẽ bị xóa:</div>
                  <div class="d-flex flex-wrap gap-2">
                    <div
                      v-for="img in deletedExistingImages"
                      :key="'del-' + img.id"
                      class="img-item img-item--deleted"
                    >
                      <img :src="img.url" alt="deleted" />
                      <button
                        type="button"
                        class="img-undo"
                        @click="undoDeleteExisting(img.id)"
                        title="Hoàn tác"
                      >
                        <i class="fa-solid fa-rotate-left"></i>
                      </button>
                    </div>
                  </div>
                </div>

                <div v-if="imagesError" class="invalid-feedback d-block mt-2">
                  {{ imagesError }}
                </div>
              </div>

              <!-- Add new images -->
              <div class="col-12">
                <label class="form-label">Thêm ảnh mới</label>

                <input
                  class="form-control bg-transparent"
                  type="file"
                  accept="image/*"
                  multiple
                  @change="onNewFilesChange"
                  :class="{ 'is-invalid': imagesError }"
                />

                <div class="small opacity-75 mt-2" v-if="!newPreviews.length">
                  Chưa chọn ảnh mới.
                </div>

                <div class="d-flex flex-wrap gap-2 mt-2" v-else>
                  <div
                    v-for="(src, idx) in newPreviews"
                    :key="src"
                    class="img-item"
                  >
                    <img :src="src" alt="preview-new" />
                    <button
                      type="button"
                      class="img-remove"
                      @click="removeNewImage(idx)"
                      title="Xóa ảnh"
                    >
                      <i class="fa-solid fa-xmark"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button
                class="btn btn-accent"
                type="submit"
                :disabled="isSubmitting"
              >
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ isSubmitting ? "Đang lưu..." : "Lưu thay đổi" }}
              </button>

              <button
                class="btn btn-outline-secondary"
                type="button"
                :disabled="isSubmitting"
                @click="onReset(resetForm)"
              >
                <i class="fa-solid fa-rotate-left me-1"></i> Reset
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

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const categories = ref([]);
const colors = ref([]);

const categoryKeyword = ref("");
const selectedCategoryId = ref("");

const initialValues = ref({
  name: "",
  des: "",
  unit: "",
  category_id: "",
  color_ids: [], // auto chọn
});

// giữ bản gốc để reset ảnh
const originalExistingImages = ref([]); // [{id,url,public_id?}]
const existingImages = ref([]); // [{id,url,replaceFile?,replacePreview?,toDelete:boolean}]
const imagesError = ref("");

// New images
const newFiles = ref([]); // File[]
const newPreviews = ref([]); // string[]

const isColorOpen = ref(false);

// refs cho input replace theo imageId
const replaceInputMap = ref(new Map());
function setReplaceInputRef(imageId, el) {
  if (!imageId) return;
  if (el) replaceInputMap.value.set(imageId, el);
  else replaceInputMap.value.delete(imageId);
}
function triggerReplace(imageId) {
  const el = replaceInputMap.value.get(imageId);
  el?.click();
}

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

const existingImagesVisible = computed(() =>
  existingImages.value.filter((x) => !x.toDelete)
);
const deletedExistingImages = computed(() =>
  existingImages.value.filter((x) => x.toDelete)
);

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên sản phẩm")
    .max(150, "Tên tối đa 150 ký tự"),
  des: yup
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

function revokeAll(urls) {
  (urls || []).forEach((u) => {
    try {
      URL.revokeObjectURL(u);
    } catch {}
  });
}

// ---- Load data ----
async function getCategories() {
  const res = await CategoryService.getAll({ per_page: 200 });
  categories.value = res.data.items;
  console.log("Loaded categories:", categories.value);
}

async function getColors() {
  const res = await ColorService.getAll();
  colors.value = res.colors;
  console.log("Loaded categories:", colors.value);
}


async function getProduct() {
  try {
    const res = await ProductService.get(id);
    const p = res.products;
  console.log(res)
    const colorIds = p?.colors
      ? p.colors.map((c) => String(c.id))
      : []

      console.log("Product colors:", colorIds);

    const imgs = p?.images
      ? p.images.map((im) => ({
          id: im.id,
          url: im.url,
          public_id: im.public_id,
        }))
      : [];

    initialValues.value = {
      name: p?.name ?? "",
      des: p?.des ?? "",
      unit: p?.unit ?? "",
      category_id: String(p?.category_id ?? ""),
      color_ids: colorIds,
    };

    selectedCategoryId.value = initialValues.value.category_id;

    originalExistingImages.value = imgs;
    existingImages.value = imgs.map((x) => ({
      ...x,
      replaceFile: null,
      replacePreview: "",
      toDelete: false,
    }));

    formKey.value += 1;
  } catch (e) {
    console.log(e);
  }
}

async function fetchAll() {
  loading.value = true;
  try {
    await Promise.all([getCategories(), getColors(), getProduct()]);
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

// ---- Existing images actions ----
function markDeleteExisting(imageId) {
  const img = existingImages.value.find((x) => x.id === imageId);
  if (!img) return;
  img.toDelete = true;

  // nếu đang replace preview thì revoke luôn để tránh leak
  if (img.replacePreview) {
    try {
      URL.revokeObjectURL(img.replacePreview);
    } catch {}
    img.replacePreview = "";
    img.replaceFile = null;
  }
}

function undoDeleteExisting(imageId) {
  const img = existingImages.value.find((x) => x.id === imageId);
  if (!img) return;
  img.toDelete = false;
}

function onReplaceExisting(imageId, e) {
  const file = e.target.files?.[0];
  if (!file) return;

  const img = existingImages.value.find((x) => x.id === imageId);
  if (!img) return;

  // revoke preview cũ
  if (img.replacePreview) {
    try {
      URL.revokeObjectURL(img.replacePreview);
    } catch {}
  }

  img.replaceFile = file;
  img.replacePreview = URL.createObjectURL(file);

  // nếu ảnh đang bị đánh dấu xóa thì bỏ xóa (vì user đang thay)
  img.toDelete = false;

  // reset input để chọn lại cùng file vẫn trigger change
  e.target.value = "";
}

// ---- New images actions ----
function onNewFilesChange(e) {
  imagesError.value = "";
  const selected = Array.from(e.target.files || []);
  newFiles.value = selected;

  revokeAll(newPreviews.value);
  newPreviews.value = selected.map((f) => URL.createObjectURL(f));
}

function removeNewImage(index) {
  const arr = [...newFiles.value];
  arr.splice(index, 1);
  newFiles.value = arr;

  revokeAll(newPreviews.value);
  newPreviews.value = newFiles.value.map((f) => URL.createObjectURL(f));
}

// ---- Reset ----
function onReset(resetFormFn) {
  resetFormFn({ values: { ...initialValues.value } });

  // reset images về bản gốc
  existingImages.value.forEach((img) => {
    if (img.replacePreview) {
      try {
        URL.revokeObjectURL(img.replacePreview);
      } catch {}
    }
  });
  existingImages.value = originalExistingImages.value.map((x) => ({
    ...x,
    replaceFile: null,
    replacePreview: "",
    toDelete: false,
  }));

  // reset new images
  revokeAll(newPreviews.value);
  newFiles.value = [];
  newPreviews.value = [];

  imagesError.value = "";
}

// ---- Submit ----
async function onSubmit(values, { setErrors }) {
  try {
    imagesError.value = "";

    // nếu bạn muốn bắt buộc có ít nhất 1 ảnh sau chỉnh sửa
    const remainExisting = existingImages.value.filter(
      (x) => !x.toDelete
    ).length;
    const addedNew = newFiles.value.length;
    if (remainExisting + addedNew === 0) {
      imagesError.value = "Vui lòng giữ hoặc thêm ít nhất 1 ảnh";
      return;
    }

    const fd = new FormData();
    fd.append("_method", "PUT"); 
    fd.append("name", values.name);
    fd.append("des", values.des || "");
    fd.append("unit", values.unit);
    fd.append("category_id", values.category_id);

    // color_ids[] (lọc bỏ "" nếu chọn “Không có màu”)
    const colorIds = Array.isArray(values.color_ids)
      ? values.color_ids.filter(Boolean)
      : [];

    console.log("COLOR VALUES:", values.color_ids); 
    console.log("COLOR ID:", colorIds); 
    colorIds.forEach((id) => fd.append("color_ids[]", id));

    // xóa ảnh: remove_image_ids[]
    existingImages.value
      .filter((x) => x.toDelete)
      .forEach((x) => fd.append("remove_image_ids[]", String(x.id)));

    // thay ảnh theo từng ảnh: replace_images[<id>]
    existingImages.value
      .filter((x) => x.replaceFile && !x.toDelete)
      .forEach((x) => fd.append(`replace_images[${x.id}]`, x.replaceFile));

    // thêm ảnh mới: images[]
    newFiles.value.forEach((f) => fd.append("images[]", f));

    console.log("FormData entries:");
    for (const pair of fd.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }
    
    await ProductService.update(id, fd);
    // return;

    await Swal.fire("Thành công!", "Cập nhật sản phẩm thành công!", "success");
    router.push({ name: "products.list" });
  } catch (e) {
    console.log(e)
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
