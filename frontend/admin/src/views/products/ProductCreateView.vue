<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Tạo sản phẩm</h4>
          <div class="small opacity-75">Nhập thông tin sản phẩm và tạo mới</div>
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
          <Form :validation-schema="schema" @submit="onSubmit" v-slot="{ isSubmitting, resetForm }">
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
                  }" placeholder="Ví dụ: chiếc..." />
                </Field>
                <ErrorMessage name="unit" class="invalid-feedback d-block" />
              </div>

              <!-- category -->
              <div class="col-6">
                <label class="form-label">Danh mục sản phẩm</label>

                <!-- input tìm -->
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
                  Để trống nếu sản phẩm chưa có model 3D. Khi upload file, backend sẽ lưu vào `static/models` và tự sinh URL cho sản phẩm.
                </div>
                <ErrorMessage name="model_3d_url" class="invalid-feedback d-block" />
              </div> -->

              <!-- <div class="col-12">
                <label class="form-label">Upload model 3D (.glb)</label>
                <input ref="model3dFileInput" type="file" accept=".glb,model/gltf-binary,application/octet-stream"
                  class="form-control bg-transparent" @change="onModel3dFileChange" />

                <div v-if="model3dFileName" class="small mt-2 opacity-75">
                  Đã chọn: {{ model3dFileName }}
                </div>
              </div> -->



              <!-- product_details -->
              <div class="col-12">
                <div class="d-flex align-items-center justify-content-between">
                  <label class="form-label mb-0">Biến thể sản phẩm</label>
                  <button type="button" class="btn btn-sm btn-outline-secondary" @click="addProduct_detail">
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
                    <tbody v-if="product_details.length">
                      <tr v-for="(v, idx) in product_details" :key="v.key">
                        <td>
                          <select class="form-select" v-model="v.color_id">
                            <option value="">Chọn màu</option>
                            <option v-for="c in colors" :key="c.id" :value="String(c.id)">
                              {{ c.name }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <select class="form-select" v-model="v.size_id">
                            <option value="">Chọn kích thước</option>
                            <option v-for="s in sizes" :key="s.id" :value="String(s.id)">
                              {{ s.size }}
                            </option>
                          </select>
                        </td>
                        <td>
                          <div class="d-flex flex-column gap-2">
                            <input type="file" accept="image/*" class="form-control form-control-sm"
                              @change="(e) => onProduct_detailImageChange(v, e)" />
                            <div v-if="getProductDetailDisplayImage(v)" class="product_detail-thumb">
                              <img :src="getProductDetailDisplayImage(v)" alt="product_detail" />
                              <button v-if="v.image_preview" type="button" class="img-remove"
                                @click="clearProduct_detailImage(v)" title="Xóa ảnh">
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
                          <button type="button" class="btn btn-sm btn-outline-danger"
                            @click="removeProduct_detail(idx)">
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

                <div v-if="product_detailsError" class="invalid-feedback d-block mt-2">
                  {{ product_detailsError }}
                </div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo sản phẩm" }}
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
import { useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import ProductService from "../../services/product.service";
import CategoryService from "../../services/category.service";
import ColorService from "@/services/color.service";
import SizeService from "@/services/size.service";
import ProductDetailService from "@/services/product-detail.service";

const router = useRouter();
const model3dFile = ref(null);
const model3dFileName = ref("");
const model3dFileInput = ref(null);

const categories = ref([]);
const getCategories = async () => {
  const res = await CategoryService.getAll({ per_page: 200 });
  console.log("Fetched categories:", res);
  categories.value = res.items;
};

const categoryKeyword = ref("");
const selectedCategoryId = ref("");

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
const sizes = ref([]);
const product_details = ref([{ key: 1, color_id: "", size_id: "", price: "", image_file: null, image_preview: "" }]);
let product_detailSeq = 1;
const product_detailsError = ref("");

function clearProduct_detailImage(product_detail) {
  if (product_detail?.image_preview) {
    URL.revokeObjectURL(product_detail.image_preview);
  }
  product_detail.image_preview = "";
  product_detail.image_file = null;
}

function onProduct_detailImageChange(product_detail, e) {
  const file = (e.target.files || [])[0] || null;
  clearProduct_detailImage(product_detail);
  if (file) {
    product_detail.image_file = file;
    product_detail.image_preview = URL.createObjectURL(file);
  }
}

function resetProduct_details() {
  product_details.value.forEach((v) => clearProduct_detailImage(v));
  product_details.value = [
    { key: 1, color_id: "", size_id: "", price: "", image_file: null, image_preview: "" },
  ];
  product_detailSeq = 1;
  product_detailsError.value = "";
}

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
});





function addProduct_detail() {
  product_detailSeq += 1;
  product_details.value.push({
    key: product_detailSeq,
    color_id: "",
    size_id: "",
    price: "",
    image_file: null,
    image_preview: "",
  });
}


function removeProduct_detail(index) {
  const item = product_details.value[index];
  if (item) {
    clearProduct_detailImage(item);
  }
  product_details.value.splice(index, 1);
}

function getProductDetailColorKey(product_detail) {
  const colorId = product_detail?.color_id;
  return colorId !== null && colorId !== undefined && colorId !== ""
    ? String(colorId)
    : "";
}

function getProductDetailDisplayImage(product_detail) {
  const colorKey = getProductDetailColorKey(product_detail);
  if (!colorKey) {
    return product_detail?.image_preview || "";
  }

  const sameColorDetails = product_details.value.filter(
    (item) => getProductDetailColorKey(item) === colorKey
  );
  return sameColorDetails.find((item) => item?.image_preview)?.image_preview || "";
}

function getProductDetailComboKey(colorId, sizeId) {
  return `${colorId}::${sizeId}`;
}

function getProductDetailComboLabel(colorId, sizeId) {
  const colorName =
    colors.value.find((item) => String(item.id) === String(colorId))?.name || `Màu #${colorId}`;
  const sizeName =
    sizes.value.find((item) => String(item.id) === String(sizeId))?.size || `Size #${sizeId}`;
  return `${colorName} / ${sizeName}`;
}


function collectProduct_details() {
  const valid = [];
  const invalid = [];
  const missingImage = [];
  const imageUploadsByColor = new Map();
  const duplicateCombos = [];
  const seenCombos = new Set();
  const colorWithImage = new Set();
  const missingImageColors = new Set();

  product_details.value.forEach((v) => {
    const colorId = v.color_id ? Number(v.color_id) : null;
    if (colorId && (v.image_file || v.image_preview)) {
      colorWithImage.add(colorId);
    }
  });

  product_details.value.forEach((v) => {
    const hasAny = v.color_id || v.size_id || v.price !== "" || v.image_file;
    const colorId = v.color_id ? Number(v.color_id) : null;
    const sizeId = v.size_id ? Number(v.size_id) : null;
    const price = v.price === "" || v.price === null ? null : Number(v.price);

    const isValid = colorId && sizeId && Number.isFinite(price);
    if (!isValid && hasAny) {
      invalid.push(v);
      return;
    }

    if (isValid) {
      const comboKey = getProductDetailComboKey(colorId, sizeId);
      if (seenCombos.has(comboKey)) {
        duplicateCombos.push(getProductDetailComboLabel(colorId, sizeId));
      } else {
        seenCombos.add(comboKey);
      }
      if (!colorWithImage.has(colorId) && !missingImageColors.has(colorId)) {
        missingImage.push(v);
        missingImageColors.add(colorId);
      }
      if (v.image_file) {
        imageUploadsByColor.set(colorId, { color_id: colorId, image_file: v.image_file });
      }
      valid.push({ color_id: colorId, size_id: sizeId, price, image_file: v.image_file });
    }
  });

  return {
    valid,
    invalid,
    missingImage,
    duplicateCombos: [...new Set(duplicateCombos)],
    imageUploads: Array.from(imageUploadsByColor.values()),
  };
}


function onReset(resetFormFn) {
  resetFormFn({
    values: {
      name: "",
      description: "",
      model_3d_url: "",
      unit: "",
      category_id: "",
      color_ids: [],
      files: [],
    },
  });
  clearModel3dFile();
  resetProduct_details();
}


async function onSubmit(values, { resetForm, setErrors }) {
  try {
    product_detailsError.value = "";
    const {
      valid: validProduct_details,
      invalid: invalidProduct_details,
      missingImage,
      duplicateCombos,
      imageUploads,
    } = collectProduct_details();

    if (invalidProduct_details.length) {
      product_detailsError.value = "Vui lòng chọn màu sắc, kích thước là gì?";
      return;
    }
    if (duplicateCombos.length) {
      product_detailsError.value = `Biến thể bị trùng màu và kích thước: ${duplicateCombos.join(", ")}`;
      return;
    }
    if (missingImage.length) {
      product_detailsError.value = "Vui lòng chọn ảnh cho từng biến thể";
      return;
    }
    if (!validProduct_details.length) {
      product_detailsError.value = "Vui lòng thêm ít nhất một biến thể";
      return;
    }

    const fd = new FormData();
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
    const colorIds = values.color_ids ? [...values.color_ids] : [];
    if (colorIds.length != 0 && colorIds[0] !== "") {
      colorIds.forEach((id) => fd.append("color_ids[]", id));
    }

    imageUploads.forEach((img) => {
      fd.append("images[]", img.image_file);
      fd.append("image_color_ids[]", img.color_id);
    });

    console.log("FormData entries:");
    for (const pair of fd.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }
    const created = await ProductService.create(fd);
    const productId = created?.data?.id ?? created?.id;
    let persistedProduct = created;
    if (productId) {
      try {
        persistedProduct = await ProductService.get(productId);
      } catch (verifyError) {
        console.log("Verify product after create failed:", verifyError);
      }
    }
    const persistedModel3dUrl =
      persistedProduct?.model_3d_url ||
      persistedProduct?.model3dUrl ||
      created?.model_3d_url ||
      created?.model3dUrl ||
      "";
    if (model3dFile.value && !persistedModel3dUrl) {
      throw new Error("MODEL_3D_UPLOAD_FAILED");
    }

    if (productId) {
      await Promise.all(
        validProduct_details.map((v) =>
          ProductDetailService.create(productId, {
            color_id: v.color_id,
            size_id: v.size_id,
            price: v.price,
          })
        )
      );
    }

    await Swal.fire("Thành công!", "Tạo sản phẩm thành công!", "success");
    resetForm({
      values: {
        name: "",
        description: "",
        model_3d_url: "",
        unit: "",
        category_id: "",
      },
    });
    clearModel3dFile();
    resetProduct_details();
  } catch (e) {
    console.log("Error response data:", e);
    const status = e?.response?.status;
    const data = e?.response?.data;
    if (status === 422 && data?.errors) {
      const errorsObj = data.errors;
      const mapped = {};
      Object.keys(errorsObj).forEach((k) => {
        mapped[k] = Array.isArray(errorsObj[k])
          ? errorsObj[k][0]
          : String(errorsObj[k]);
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
        "Tạo sản phẩm thất bại. Vui lòng thử lại.";
    Swal.fire("Tạo sản phẩm thất bại", msg, "error");
  }
}

const colors = ref([]);
const getColors = async () => {
  try {
    const res = await ColorService.getAll();
    console.log(res)
    colors.value = res;
  } catch (e) {
    console.log(e);
  }
};

const getSizes = async () => {
  try {
    const res = await SizeService.getAll();
    sizes.value = Array.isArray(res) ? res : res?.data ?? [];
  } catch (e) {
    console.log(e);
  }
};
const isColorOpen = ref(false);

function onColorChange(e, handleChange) {
  const selected = Array.from(e.target.selectedOptions).map((o) => o.value);
  if (selected.includes("") && selected.length > 1) {
    Array.from(e.target.options).forEach((opt) => {
      opt.selected = opt.value === "";
    });

    handleChange([""]);
    return;
  }

  handleChange(selected);
}
onMounted(async () => {
  await getCategories();
  await getColors();
  await getSizes();
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

/* preview */
.product_detail-thumb {
  position: relative;
  width: 5rem;
  height: 5rem;
  border-radius: 0.6rem;
  overflow: hidden;
  border: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.03);
}

.product_detail-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
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
</style>
