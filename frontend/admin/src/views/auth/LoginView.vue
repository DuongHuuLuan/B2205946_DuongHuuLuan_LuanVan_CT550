<template>
  <div class="min-vh-100 d-flex align-items-center login-page">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-12 col-md-8 col-lg-5">
          <div class="card shadow-sm login-card">
            <div class="card-body p-4">
              <div class="text-center">
                <span class="login-header-badge"> Đăng nhập </span>
              </div>
              <p class="subtext mb-4 text-center">
                Hệ thống quản lý cửa hàng Royal Store
              </p>

              <Form :validation-schema="schema" @submit="onSubmit" v-slot="{ errors, isSubmitting }" novalidate>
                <!-- email -->
                <div class="mb-3">
                  <label class="form-label" for="email">Email</label>
                  <div class="input-group">
                    <span class="input-group-text">
                      <i class="fa-solid fa-user"></i>
                    </span>

                    <Field id="email" name="email" type="text" class="form-control"
                      :class="{ 'is-invalid': errors.email }" placeholder="Nhập email" autocomplete="email" />
                  </div>
                  <div v-if="errors.email" class="invalid-feedback d-block">
                    {{ errors.email }}
                  </div>
                </div>

                <!-- Password -->
                <div class="mb-3">
                  <label class="form-label" for="password">Mật khẩu</label>
                  <div class="input-group">
                    <span class="input-group-text">
                      <i class="fa-solid fa-lock"></i>
                    </span>

                    <Field id="password" name="password" :type="showPassword ? 'text' : 'password'" class="form-control"
                      :class="{ 'is-invalid': errors.password }" placeholder="Nhập mật khẩu"
                      autocomplete="current-password" />

                    <button type="button" class="btn btn-outline-secondary" @click="showPassword = !showPassword">
                      <i :class="showPassword
                        ? 'fa-solid fa-eye-slash'
                        : 'fa-solid fa-eye'
                        "></i>
                    </button>
                  </div>

                  <div v-if="errors.password" class="invalid-feedback d-block">
                    {{ errors.password }}
                  </div>
                </div>

                <button class="btn btn-main w-100" type="submit" :disabled="isSubmitting">
                  <i class="fa-solid fa-right-to-bracket me-2"></i>
                  {{ isSubmitting ? "Đang đăng nhập..." : "Đăng nhập" }}
                </button>
              </Form>
            </div>
          </div>

          <p class="text-center text-muted small mt-3 mb-0">
            © {{ new Date().getFullYear() }} Royal Store
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { Form, Field } from "vee-validate";
import * as yup from "yup";
import authService from "@/services/auth.service";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";

const router = useRouter();
const showPassword = ref(false);
const serverError = ref("");

const schema = yup.object({
  email: yup.string().required("Vui lòng nhập email").email("Email không hợp lệ"),
  password: yup.string().required("Vui lòng nhập mật khẩu"),
});

async function onSubmit(values, actions) {
  serverError.value = "";

  try {
    const res = await authService.login(values);

    if (res) {
      console.log("Đăng nhập thành công, chuẩn bị chuyển hướng...");

      await Swal.fire({
        icon: 'success',
        title: 'Thành công',
        text: 'Đang chuyển hướng đến trang chủ...',
        timer: 1500,
        showCancelButton: false
      });
    }
    await router.push("/");
    console.log("Đã gọi lệnh router.push");
    return res;
  } catch (e) {
    console.log(e);
    serverError.value =
      e?.response?.data?.message ||
      "Đăng nhập thất bại. Vui lòng kiểm tra lại.";
    if (e?.response?.status === 422 && e?.response?.data?.errors) {
      const errors = e.response.data.errors;
      const mapped = Object.fromEntries(
        Object.entries(errors).map(([field, messages]) => [
          field,
          Array.isArray(messages) ? messages[0] : String(messages),
        ])
      );
      actions.setErrors(mapped);
    }
    Swal.fire({
      icon: 'error',
      title: 'Thất bại',
      text: e.message || "Email hoặc mật khẩu không đúng",
    })
  }
}
</script>

<style scoped>
.login-page {
  background: var(--main-bg);
}

.login-card {
  border-radius: 18px;
  border: 1px solid var(--hover-border-color);
  background: var(--main-extra-bg);
}

.login-header-badge {
  display: inline-flex;
  align-items: center;
  font-weight: 800;
  font-size: 1.5rem;
}

.subtext {
  color: var(--font-extra-color) !important;
}

.link-main {
  color: var(--extra-color);
  font-weight: 700;
}

.btn-main {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
  font-weight: 800;
  border-radius: 14px;
  padding: 0.75rem 1rem;
}

.btn-main:hover {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}

.card-body :deep(.input-group-text) {
  background: var(--main-extra-bg);
  border-color: var(--border-color);
}

.card-body :deep(.form-control) {
  background: var(--main-extra-bg);
  border-color: var(--border-color);
  color: var(--font-color);
}

.card-body :deep(.form-control:focus) {
  box-shadow: 0 0 0 0.2rem rgba(242, 196, 149, 0.35);
  border-color: var(--hover-border-color);
}

.card-body :deep(.form-control.is-invalid),
.card-body :deep(.form-select.is-invalid),
.card-body :deep(.form-check-input.is-invalid) {
  border-color: var(--bs-danger) !important;
}

.card-body :deep(.form-control.is-invalid:focus),
.card-body :deep(.form-select.is-invalid:focus),
.card-body :deep(.form-check-input.is-invalid:focus) {
  box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
}

.card-body :deep(.input-group .form-control.is-invalid) {
  z-index: 3;
}
</style>
