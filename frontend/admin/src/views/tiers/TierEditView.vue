<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Chỉnh sửa cấp</h4>
          <div class="small opacity-75">Cập nhật thông tin cấp</div>
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
            <div class="mb-3">
              <label class="form-label">Tên cấp tài khoản</label>

              <Field name="name" v-slot="{ field, meta }">
                <input
                  v-bind="field"
                  type="text"
                  class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
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
                  <option value="actived">Bật (actived)</option>
                  <option value="disabled">Tắt (disabled)</option>
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

              <label class="form-check-label" for="is_default">
                Đặt làm mặc định khi user tạo tài khoản
              </label>

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

import TierService from "../../services/tier.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const initialValues = ref({
  name: "",
  code: "",
  status: "actived",
  is_default: false,
});
const original = ref({
  name: "",
  code: "",
  status: "actived",
  is_default: false,
});

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
  status: yup.string().oneOf(["actived", "disabled"]).required(),
});

async function fetchTier() {
  loading.value = true;
  try {
    const res = await TierService.get(id);
    const data = res?.data ?? res;

    const values = {
      name: data?.name ?? "",
      code: data?.code ?? "",
      status: data?.status ?? "actived",
      is_default: !!data?.default,
    };

    original.value = { ...values };
    initialValues.value = { ...values };

    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải tier. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "tiers.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { ...original.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await TierService.update(id, {
      name: values.name,
      code: values.code,
      status: values.status,
      is_default: !!values.is_default,
    });

    await Swal.fire("Thành công!", "Cập nhật tier thành công!", "success");

    original.value = { ...values };
    resetForm({ values: { ...values } });

    router.push({ name: "tiers.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật tier thất bại. Vui lòng thử lại.";
    console.log(e)
    await Swal.fire("Cập nhật tier thất bại", msg, "error");

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

onMounted(fetchTier);
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
