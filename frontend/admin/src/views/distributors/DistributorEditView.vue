<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa nhà cung cấp</h4>
          <div class="small opacity-75">Cập nhật thông tin nhà cung cấp</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'distributors.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <!-- Form -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }">
            <div class="mb-3">
              <label class="form-label">Tên nhà cung cấp</label>

              <Field name="name" v-slot="{ field, meta }">
                <input v-bind="field" type="text" class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }" placeholder="Ví dụ: Công ty A..." />
              </Field>

              <ErrorMessage name="name" class="invalid-feedback d-block" />
            </div>

            <div class="mb-3">
              <label class="form-label">Địa chỉ nhà cung cấp</label>

              <Field name="address" v-slot="{ field, meta }">
                <input v-bind="field" type="text" class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Ví dụ: 123 Lê Lợi, Q1, TP.HCM..." />
              </Field>

              <ErrorMessage name="address" class="invalid-feedback d-block" />
            </div>

            <div class="mb-3">
              <label class="form-label">Email nhà cung cấp</label>

              <Field name="email" v-slot="{ field, meta }">
                <input v-bind="field" type="text" class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }" placeholder="Ví dụ: ncc@gmail.com" />
              </Field>

              <ErrorMessage name="email" class="invalid-feedback d-block" />
            </div>

            <div class="d-flex gap-2">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ isSubmitting ? "Đang lưu..." : "Lưu thay đổi" }}
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
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import DistributorService from "../../services/distributor.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const initialValues = ref({ name: "", address: "", email: "" });
const original = ref({ name: "", address: "", email: "" });

const schema = yup.object({
  name: yup
    .string()
    .trim()
    .required("Vui lòng nhập tên nhà cung cấp")
    .min(2, "Tên nhà cung cấp tối thiểu 2 ký tự")
    .max(100, "Tên nhà cung cấp tối đa 100 ký tự"),
  address: yup
    .string()
    .trim()
    .required("Vui lòng nhập địa chỉ nhà cung cấp")
    .min(5, "Địa chỉ tối thiểu 5 ký tự")
    .max(255, "Địa chỉ tối đa 255 ký tự"),
  email: yup
    .string()
    .trim()
    .required("Vui lòng nhập số điện thoại liên lạc")
    .email("Email không hợp lệ"),
});

async function fetchDistributor() {
  loading.value = true;
  try {
    const res = await DistributorService.get(id);
    const data = res;

    const values = {
      name: data.name ?? "",
      address: data.address ?? "",
      email: data.email ?? "",
    };

    original.value = { ...values };
    initialValues.value = { ...values };

    // remount form để nhận initial-values mới
    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải nhà cung cấp. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "distributors.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { ...original.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await DistributorService.update(id, {
      name: values.name,
      address: values.address,
      email: values.email,
    });

    await Swal.fire(
      "Thành công!",
      "Cập nhật nhà cung cấp thành công!",
      "success"
    );

    original.value = { ...values };
    resetForm({ values: { ...values } });

    router.push({ name: "distributors.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật nhà cung cấp thất bại. Vui lòng thử lại.";
    await Swal.fire("Cập nhật nhà cung cấp thất bại", msg, "error");

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

onMounted(fetchDistributor);
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
