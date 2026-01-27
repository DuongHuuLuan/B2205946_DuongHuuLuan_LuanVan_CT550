<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Tạo danh mục</h4>
          <div class="small opacity-75">Nhập tên danh mục và tạo mới</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'categories.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Form -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <Form :validation-schema="schema" @submit="onSubmit" v-slot="{ isSubmitting, resetForm, }">
            <div class="mb-3">
              <label class="form-label">Tên danh mục</label>

              <Field name="name" v-slot="{ field, meta }">
                <input v-bind="field" type="text" class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Ví dụ: Mũ nữa đầu, mũ lật hàm..." />
              </Field>

              <ErrorMessage name="name" class="invalid-feedback d-block" />
            </div>

            <div class="d-flex gap-2">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo danh mục" }}
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
import { ref } from "vue";
import { useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import CategoryService from "../../services/category.service";

const router = useRouter();

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên danh mục")
    .min(2, "Tên danh mục tối thiểu 2 ký tự")
    .max(100, "Tên danh mục tối đa 100 ký tự"),
});

function onReset(resetFormFn) {
  resetFormFn({ values: { name: "" } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await CategoryService.create({ name: values.name });
    await Swal.fire("Thành công!", "Tạo danh mục thành công!", "success");
    resetForm({ values: { name: "" } });

    router.push({ name: "categories.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Tạo danh mục thất bại. Vui lòng thử lại.";
    await Swal.fire("Tạo danh mục thất bại", msg, "error");
    const errorsObj = e?.response?.data?.errors || {};
    const mapped = {};
    console.log(errorsObj);
    Object.keys(errorsObj).forEach((k) => {
      mapped[k] = Array.isArray(errorsObj[k])
        ? errorsObj[k][0]
        : String(errorsObj[k]);
    });
    console.log(mapped);
    setErrors(mapped);
    return;
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

.btn-accent {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
}

.btn-accent:hover {
  filter: var(--brightness);
}
</style>
