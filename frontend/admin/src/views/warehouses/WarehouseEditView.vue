<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Chỉnh sửa kho</h4>
          <div class="small opacity-75">Cập nhật địa chỉ và dung tích kho</div>
        </div>

        <RouterLink
          class="btn btn-outline-secondary"
          :to="{ name: 'warehouses.list' }"
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

          <Form
            v-else
            :key="formKey"
            :initial-values="initialValues"
            :validation-schema="schema"
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
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
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
                    :class="{
                      'is-invalid':
                        (meta.touched && !meta.valid) || errors.length,
                    }"
                    placeholder="Ví dụ: 1000"
                  />
                </Field>

                <ErrorMessage
                  name="capacity"
                  class="invalid-feedback d-block"
                />
                <div class="small opacity-75 mt-1">
                  Phải là số nguyên lớn hơn 0.
                </div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
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

import WarehouseService from "@/services/warehouse.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);

const initialValues = ref({ address: "", capacity: 1 });
const originalValues = ref({ address: "", capacity: 1 });

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

async function fetchWarehouse() {
  loading.value = true;
  try {
    const res = await WarehouseService.get(id);
    const data = res?.data ?? res;

    const address = data?.address ?? "";
    const capacity = data?.capacity ?? 1;

    originalValues.value = { address, capacity };
    initialValues.value = { address, capacity };

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
      capacity: Number(values.capacity),
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
