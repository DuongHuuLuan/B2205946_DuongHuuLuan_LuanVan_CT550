<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Tạo cấp</h4>
          <div class="small opacity-75">Nhập thông tin cấp và tạo mới</div>
        </div>

        <RouterLink
          class="btn btn-outline-secondary"
          :to="{ name: 'tiers.list' }"
        >
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Form -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <Form
            :validation-schema="schema"
            @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }"
            :initial-values="{ status: 'actived' }"
          >
            <div class="mb-3">
              <label class="form-label">Tên cấp tài khoản</label>

              <Field name="name" v-slot="{ field, meta }">
                <input
                  v-bind="field"
                  type="text"
                  class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Ví dụ: Retail / Dealer Silver..."
                />
              </Field>

              <ErrorMessage name="name" class="invalid-feedback d-block" />
            </div>

            <div class="mb-3">
              <label class="form-label">Mã cấp tài khoản</label>

              <Field name="code" v-slot="{ field, meta }">
                <input
                  v-bind="field"
                  type="text"
                  class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Ví dụ: RETAIL / DEALER_SILVER..."
                />
              </Field>

              <ErrorMessage name="code" class="invalid-feedback d-block" />
            </div>

            <div class="mb-3">
              <label class="form-label">Trạng thái</label>

              <Field name="status" v-slot="{ field, meta }">
                <select
                  v-bind="field"
                  class="form-select bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                >
                  <option value="actived">Bật</option>
                  <option value="disabled">Tắt</option>
                </select>
              </Field>

              <ErrorMessage name="status" class="invalid-feedback d-block" />
            </div>

            <div class="form-check mb-3">
              <Field name="is_default" v-slot="{ value, handleChange }">
                <input
                  id="is_default"
                  class="form-check-input"
                  type="checkbox"
                  :checked="!!value"
                  @change="handleChange($event.target.checked)"
                />
              </Field>

              <label class="form-check-label" for="is_default"
                >Đặt làm mặc định khi user tạo tài khoản</label
              >
              <ErrorMessage
                name="is_default"
                class="invalid-feedback d-block"
              />
            </div>

            <div class="d-flex gap-2">
              <button
                class="btn btn-accent"
                type="submit"
                :disabled="isSubmitting"
              >
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo cấp" }}
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
import { useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import TierService from "../../services/tier.service";

const router = useRouter();

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên cấp tài khoản")
    .min(2, "Tên tối thiểu 2 ký tự")
    .max(100, "Tên tối đa 100 ký tự"),
  code: yup
    .string()
    .trim()
    .required("Vui lòng nhập mã cấp tài khoản")
    .min(2, "Mã tối thiểu 2 ký tự")
    .max(50, "Mã tối đa 50 ký tự")
    .matches(
      /^[A-Z0-9_]+$/i,
      "Mã chỉ gồm chữ/số/_ (không dấu, không khoảng trắng)"
    ),
  status: yup
    .string()
    .oneOf(["actived", "disabled"], "Trạng thái không hợp lệ")
    .required("Vui lòng chọn trạng thái"),
});

function onReset(resetFormFn) {
  resetFormFn({
    values: { name: "", code: "", status: "actived", is_default: false },
  });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await TierService.create({
      ...values,
      is_default: !!values.is_default,
    });

    await Swal.fire("Thành công!", "Tạo tier thành công!", "success");
    resetForm({
      values: { name: "", code: "", status: "actived", is_default: false },
    });

    router.push({ name: "tiers.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Tạo tier thất bại. Vui lòng thử lại.";
    await Swal.fire("Tạo tier thất bại", msg, "error");
  console.log(e)
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
