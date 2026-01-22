<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Chỉnh sửa danh mục</h4>
          <div class="small opacity-75">Cập nhật tên danh mục</div>
        </div>

        <RouterLink
          class="btn btn-outline-secondary"
          :to="{ name: 'categories.list' }"
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

          <!-- Form (mount lại khi formKey đổi) -->
          <Form
            v-else
            :key="formKey"
            :initial-values="initialValues"
            :validation-schema="schema"
            @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }"
          >
            <div class="mb-3">
              <label class="form-label">Tên danh mục</label>

              <Field name="name" v-slot="{ field, meta }">
                <input
                  v-bind="field"
                  type="text"
                  class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Ví dụ: Bút, Vở, Sổ tay..."
                />
              </Field>

              <ErrorMessage name="name" class="invalid-feedback d-block" />
            </div>

            <div class="d-flex gap-2">
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
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import CategoryService from "../../services/category.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);

const formKey = ref(0);

const initialValues = ref({ name: "" });
const originalName = ref("");

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên danh mục")
    .min(2, "Tên danh mục tối thiểu 2 ký tự")
    .max(100, "Tên danh mục tối đa 100 ký tự"),
});

async function fetchCategory() {
  loading.value = true;
  try {
    const res = await CategoryService.get(id);
    const data = res?.data ?? res;

    const name = data?.name ?? "";

    originalName.value = name;
    initialValues.value = { name };

    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải danh mục. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "categories.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { name: originalName.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await CategoryService.update(id, { name: values.name });

    await Swal.fire("Thành công!", "Cập nhật danh mục thành công!", "success");

    originalName.value = values.name;

    resetForm({ values: { name: values.name } });
    router.push({ name: "categories.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật danh mục thất bại. Vui lòng thử lại.";
    await Swal.fire("Cập nhật danh mục thất bại", msg, "error");

    const errorsObj = e?.response?.data?.errors || {};
    const mapped = {};
    Object.keys(errorsObj).forEach((k) => {
      mapped[k] = Array.isArray(errorsObj[k])
        ? errorsObj[k][0]
        : String(errorsObj[k]);
    });
    setErrors(mapped);
    return;
  }
}

onMounted(fetchCategory);
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
