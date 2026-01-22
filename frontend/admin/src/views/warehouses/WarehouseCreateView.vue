<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Tạo kho</h4>
          <div class="small opacity-75">Nhập vào thông tin kho để tạo mới</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'warehouses.list' }">
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
            :initial-values="initialValues"
            @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }"
          >
            <div class="row g-3">
              <!-- address -->
              <div class="col-12">
                <label class="form-label">Địa chỉ kho</label>

                <Field name="address" v-slot="{ field, meta, errors }">
                  <input
                    v-bind="field"
                    type="text"
                    class="form-control bg-transparent"
                    :class="{ 'is-invalid': (meta.touched && !meta.valid) || errors.length }"
                    placeholder="Ví dụ: 12 Nguyễn Trãi, P. Bến Thành, Q1..."
                  />
                </Field>

                <ErrorMessage name="address" class="invalid-feedback d-block" />
              </div>

              <!-- capacity -->
              <div class="col-12 col-md-6">
                <label class="form-label">Dung tích kho</label>

                <Field name="capacity" v-slot="{ field, meta, errors }">
                  <input
                    v-bind="field"
                    type="number"
                    inputmode="numeric"
                    min="1"
                    step="1"
                    class="form-control bg-transparent"
                    :class="{ 'is-invalid': (meta.touched && !meta.valid) || errors.length }"
                    placeholder="Ví dụ: 1000"
                  />
                </Field>

                <ErrorMessage name="capacity" class="invalid-feedback d-block" />
                <div class="small opacity-75 mt-1">Phải là số nguyên lớn hơn 0.</div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo kho" }}
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

// Đổi service cho đúng dự án của bạn
import WarehouseService from "@/services/warehouse.service";

const router = useRouter();

const initialValues = {
  address: "",
  capacity: 1,
};

const schema = yup.object({
  address: yup
    .string()
    .trim()
    .required("Vui lòng nhập địa chỉ kho")
    .max(255, "Địa chỉ tối đa 255 ký tự"),
  capacity: yup
    .number()
    .typeError("Dung tích phải là số")
    .integer("Dung tích phải là số nguyên")
    .moreThan(0, "Dung tích phải lớn hơn 0")
    .required("Vui lòng nhập dung tích kho"),
});

function onReset(resetFormFn) {
  resetFormFn({ values: { ...initialValues } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    // chuẩn hóa payload
    const payload = {
      address: values.address?.trim(),
      capacity: Number(values.capacity),
    };

    await WarehouseService.create(payload);

    await Swal.fire("Thành công!", "Tạo kho thành công!", "success");

    resetForm({ values: { ...initialValues } });
    router.push({ name: "warehouses.list" });
  } catch (e) {
    const status = e?.response?.status;
    const data = e?.response?.data;

    // 422 từ FormRequest (bao gồm case unique sau này)
    if (status === 422 && data?.errors) {
      const mapped = {};
      Object.keys(data.errors).forEach((k) => {
        mapped[k] = Array.isArray(data.errors[k]) ? data.errors[k][0] : String(data.errors[k]);
      });
      setErrors(mapped);
      return;
    }

    const msg =
      data?.message ||
      data?.error ||
      "Tạo kho thất bại. Vui lòng thử lại.";
    await Swal.fire("Tạo kho thất bại", msg, "error");
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
