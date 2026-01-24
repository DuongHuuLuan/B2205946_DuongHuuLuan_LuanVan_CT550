<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa tài khoản</h4>
          <div class="small opacity-75">Cập nhật thông tin tài khoản</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'users.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải tài liệu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }">
            <div class="row g-3">
              <div class="col-12 col-md-6">
                <label class="form-label">Username</label>
                <Field name="username" v-slot="{ field, meta }">
                  <input v-bind="field" type="text" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="username" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Email</label>
                <Field name="email" v-slot="{ field, meta }">
                  <input v-bind="field" type="email" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="email" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label">Vai trò</label>
                <Field name="role" v-slot="{ field, meta }">
                  <select v-bind="field" class="form-select bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }">
                    <option value="admin">Admin</option>
                    <option value="user">User</option>
                  </select>
                </Field>
                <ErrorMessage name="role" class="invalid-feedback d-block" />
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ isSubmitting ? "Đang lưu..." : "Lưu thay đổi" }}
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
import { useRoute, useRouter } from "vue-router";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";

import UserService from "@/services/user.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const initialValues = ref({
  username: "",
  email: "",
  role: "user",
});
const originalValues = ref({ ...initialValues.value });

const schema = yup.object({
  username: yup
    .string()
    .trim()
    .required("Vui lòng nhập username")
    .min(2, "Username tối thiểu 2 ký tự")
    .max(255, "Username tối đa 255 ký tự"),
  email: yup
    .string()
    .trim()
    .email("Email không hợp lệ")
    .required("Vui lòng nhập email"),
  role: yup.string().required("Vui lòng chọn vai trò"),
});

async function fetchUser() {
  loading.value = true;
  try {
    const res = await UserService.get(id);
    const data = res?.data ?? res;

    const mapped = {
      username: data?.username ?? "",
      email: data?.email ?? "",
      role: data?.role ?? "user",
    };

    initialValues.value = mapped;
    originalValues.value = { ...mapped };
    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải tài khoản. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "users.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { ...originalValues.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await UserService.update(id, {
      username: values.username?.trim(),
      email: values.email?.trim(),
      role: values.role,
    });

    await Swal.fire("Thành công!", "Cập nhật tài khoản thành công!", "success");
    originalValues.value = { ...values };
    resetForm({ values: { ...values } });
    router.push({ name: "users.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật tài khoản thất bại. Vui lòng thử lại.";
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

onMounted(fetchUser);
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
