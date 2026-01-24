<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Tạo khuyến mãi</h4>
          <div class="small opacity-75">Nhập thông tin khuyến mãi và tạo mới</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'discounts.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <Form :validation-schema="schema" @submit="onSubmit" v-slot="{ isSubmitting, resetForm }">
            <div class="row g-3">
              <div class="col-12 col-lg-6">
                <label class="form-label">Mã/tên khuyến mãi</label>
                <Field name="name" v-slot="{ field, meta }">
                  <input v-bind="field" type="text" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" placeholder="VD: KM10" />
                </Field>
                <ErrorMessage name="name" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-lg-6">
                <label class="form-label">Danh mục áp dụng</label>
                <Field name="category_id" v-slot="{ field, meta }">
                  <select v-bind="field" class="form-select bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }">
                    <option value="">Chọn danh mục</option>
                    <option v-for="c in categories" :key="c.id" :value="String(c.id)">
                      {{ c.name }}
                    </option>
                  </select>
                </Field>
                <ErrorMessage name="category_id" class="invalid-feedback d-block" />
              </div>

              <div class="col-12">
                <label class="form-label">Mô tả</label>
                <Field name="description" v-slot="{ field, meta }">
                  <textarea v-bind="field" rows="3" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }"
                    placeholder="Mô tả ngắn về khuyến mãi"></textarea>
                </Field>
                <ErrorMessage name="description" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label">Phần trăm</label>
                <Field name="percent" v-slot="{ field, meta }">
                  <input v-bind="field" type="number" min="0" max="100" step="0.01" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" placeholder="VD: 10" />
                </Field>
                <ErrorMessage name="percent" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label">Bắt đầu</label>
                <Field name="start_at" v-slot="{ field, meta }">
                  <input v-bind="field" type="datetime-local" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="start_at" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label">Kết thúc</label>
                <Field name="end_at" v-slot="{ field, meta }">
                  <input v-bind="field" type="datetime-local" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="end_at" class="invalid-feedback d-block" />
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo khuyến mãi" }}
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
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import DiscountService from "@/services/discount.service";
import CategoryService from "@/services/category.service";

const router = useRouter();
const categories = ref([]);

const schema = yup.object({
  name: yup.string().trim().required("Vui lòng nhập mã/tên khuyến mãi"),
  description: yup.string().trim().nullable(),
  category_id: yup.string().required("Vui lòng chọn danh mục"),
  percent: yup
    .number()
    .typeError("Phần trăm không hợp lệ")
    .min(0, "Phần trăm tối thiểu là 0")
    .max(100, "Phần trăm tối đa là 100")
    .required("Vui lòng nhập phần trăm"),
  start_at: yup.string().required("Vui lòng chọn ngày bắt đầu"),
  end_at: yup
    .string()
    .required("Vui lòng chọn ngày kết thúc")
    .test("end_after", "Ngày kết thúc phải sau ngày bắt đầu", function (value) {
      const { start_at } = this.parent;
      if (!value || !start_at) return true;
      return new Date(value) >= new Date(start_at);
    }),
});

async function fetchCategories() {
  try {
    const res = await CategoryService.getAll({ per_page: 200 });
    categories.value = res?.items ?? [];
  } catch (e) {
    categories.value = [];
  }
}

function onReset(resetFormFn) {
  resetFormFn({
    values: {
      name: "",
      description: "",
      category_id: "",
      percent: "",
      start_at: "",
      end_at: "",
    },
  });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await DiscountService.create({
      name: values.name?.trim(),
      description: values.description?.trim() || null,
      category_id: Number(values.category_id),
      percent: Number(values.percent),
      start_at: values.start_at,
      end_at: values.end_at,
    });

    await Swal.fire("Thành công!", "Tạo khuyến mãi thành công!", "success");
    onReset(resetForm);
    router.push({ name: "discounts.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Tạo khuyến mãi thất bại. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");

    const errorsObj = e?.response?.data?.errors || {};
    const mapped = {};
    Object.keys(errorsObj).forEach((k) => {
      mapped[k] = Array.isArray(errorsObj[k])
        ? errorsObj[k][0]
        : String(errorsObj[k]);
    });
    setErrors(mapped);
  }
}

onMounted(fetchCategories);
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
</style>