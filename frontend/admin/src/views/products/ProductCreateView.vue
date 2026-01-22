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
                        <th>Giá</th>
                        <th class="text-end">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody v-if="variants.length">
                      <tr v-for="(v, idx) in variants" :key="v.key">
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
                        <td colspan="4" class="text-center opacity-75 py-3">
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
              <!-- images -->
              <div class="col-12">
                <label class="form-label">Ảnh sản phẩm</label>

                <input class="form-control bg-transparent" type="file" accept="image/*" multiple @change="onFilesChange"
                  :class="{ 'is-invalid': imagesError }" name="files" />

                <div class="small opacity-75 mt-2" v-if="!previews.length">
                  Chưa chọn ảnh.
                </div>

                <div class="d-flex flex-wrap gap-2 mt-2" v-else>
                  <div v-for="(src, idx) in previews" :key="src" class="img-item">
                    <img :src="src" alt="preview" />
                    <button type="button" class="img-remove" @click="removeImage(idx)" title="Xóa ảnh">
                      <i class="fa-solid fa-xmark"></i>
                    </button>
                  </div>
                </div>

                <div v-if="imagesError" class="invalid-feedback d-block mt-2">
                  {{ imagesError }}
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

const files = ref([]); // File[]
const previews = ref([]); // string[]
const imagesError = ref("");
const sizes = ref([]);
const variants = ref([{ key: 1, color_id: "", size_id: "", price: "" }]);
let variantSeq = 1;
const variantsError = ref("");

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
});

function onFilesChange(e) {
  imagesError.value = "";
  const selected = Array.from(e.target.files || []);
  files.value = selected;

  // preview
  previews.value.forEach((u) => URL.revokeObjectURL(u));
  previews.value = selected.map((f) => URL.createObjectURL(f));
}

function removeImage(index) {
  const arr = [...files.value];
  arr.splice(index, 1);
  files.value = arr;

  previews.value.forEach((u) => URL.revokeObjectURL(u));
  previews.value = files.value.map((f) => URL.createObjectURL(f));
}

function addVariant() {
  variantSeq += 1;
  variants.value.push({ key: variantSeq, color_id: "", size_id: "", price: "" });
}

function removeVariant(index) {
  variants.value.splice(index, 1);
}

function collectVariants() {
  const valid = [];
  const invalid = [];

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
      valid.push({ color_id: colorId, size_id: sizeId, price });
    }
  });

  return { valid, invalid };
}

function onReset(resetFormFn) {
  resetFormFn({
    values: {
      name: "",
      description: "",
      unit: "",
      category_id: "",
      color_ids: [],
      files: [],
    },
  });
  files.value = [];
  previews.value.forEach((u) => URL.revokeObjectURL(u));
  previews.value = [];
  imagesError.value = "";
  variants.value = [{ key: 1, color_id: "", size_id: "", price: "" }];
  variantSeq = 1;
  variantsError.value = "";
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    console.log(files.value);
    variantsError.value = "";
    const { valid: validVariants, invalid: invalidVariants } = collectVariants();
    if (invalidVariants.length) {
      variantsError.value = "Vui lòng nhập đầy đủ màu sắc, kích thước và giá";
      return;
    }
    if (!validVariants.length) {
      variantsError.value = "Vui lòng thêm ích nhất một biến thể";
      return;
    }

    if (files.value.length == 0) {
      imagesError.value = "Vui lòng chọn ít nhất 1 ảnh";
      return;
    }

    const fd = new FormData();
    fd.append("name", values.name);
    fd.append("description", values.description || "");
    fd.append("unit", values.unit);
    fd.append("category_id", values.category_id);
    const colorIds = values.color_ids ? [...values.color_ids] : [];
    if (colorIds.length != 0 && colorIds[0] !== "") {
      colorIds.forEach((id) => fd.append("color_ids[]", id));
    }
    files.value.forEach((f) => fd.append("images[]", f));

    console.log("FormData entries:");
    for (const pair of fd.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }
    const created = await ProductService.create(fd);
    const productId = created?.data?.id ?? created?.id;

    if (productId) {
      await Promise.all(
        validVariants.map((v) => ProductDetailService.create(productId, v))
      );
    }

    await Swal.fire("Thành công!", "Tạo sản phẩm thành công!", "success");
    resetForm({ values: { name: "", description: "", unit: "", category_id: "" } });
    onReset(() => { });

    // router.push({ name: "products.list" });
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
