<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa kho</h4>
          <div class="small opacity-75">Cập nhật địa chỉ kho</div>
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
          <!-- Loading -->
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }">
            <div class="row g-3">
              <!-- address -->
              <div class="col-12">
                <label class="form-label">Địa chỉ kho</label>

                <Field name="address" v-slot="{ field, meta, errors }">
                  <input v-bind="field" type="text" class="form-control bg-transparent" :class="{
                    'is-invalid':
                      (meta.touched && !meta.valid) || errors.length,
                  }" placeholder="Ví dụ: Số 180 khu 2, Ấp 3, Phong Thạnh, Huyện Cầu kè, Tỉnh Trà Vinh..." />
                </Field>

                <ErrorMessage name="address" class="invalid-feedback d-block" />
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

import WarehouseService from "@/services/warehouse.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const initialValues = ref({ address: "" });
const originalValues = ref({ address: "" });

const schema = yup.object({
  address: yup
    .string()
    .trim()
    .required("Vui lòng nhập địa chỉ kho")
    .max(255, "Địa chỉ tối đa 255 ký tự"),
});

async function fetchWarehouse() {
  loading.value = true;
  try {
    const res = await WarehouseService.get(id);
    const data = res?.data ?? res;

    const address = data?.address ?? "";

    originalValues.value = { address };
    initialValues.value = { address };

    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải kho. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "warehouses.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { ...originalValues.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    const payload = {
      address: values.address?.trim(),
    };

    await WarehouseService.update(id, payload);

    await Swal.fire("Thành công!", "Cập nhật kho thành công!", "success");

    // update lại giá trị gốc để reset dùng mới
    originalValues.value = { ...payload };

    resetForm({ values: { ...payload } });
    router.push({ name: "warehouses.list" });
  } catch (e) {
    const status = e?.response?.status;
    const data = e?.response?.data;

    // map lỗi 422 từ server (vd unique address)
    if (status === 422 && data?.errors) {
      const mapped = {};
      Object.keys(data.errors).forEach((k) => {
        mapped[k] = Array.isArray(data.errors[k])
          ? data.errors[k][0]
          : String(data.errors[k]);
      });
      setErrors(mapped);
      return;
    }

    const msg =
      data?.message ||
      data?.error ||
      "Cập nhật kho thất bại. Vui lòng thử lại.";
    await Swal.fire("Cập nhật kho thất bại", msg, "error");
  }
}

onMounted(fetchWarehouse);
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
