<template>
  <div class="row g-3">
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Chinh sua kich thuoc</h4>
          <div class="small opacity-75">Cap nhat kich thuoc</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'sizes.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lai
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Dang tai du lieu...
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
              <label class="form-label">Kich thuoc</label>
              <Field name="size" v-slot="{ field, meta }">
                <input
                  v-bind="field"
                  type="text"
                  class="form-control bg-transparent"
                  :class="{ 'is-invalid': meta.touched && !meta.valid }"
                  placeholder="Vi du: S, M, L, XL"
                />
              </Field>
              <ErrorMessage name="size" class="invalid-feedback d-block" />
            </div>

            <div class="d-flex gap-2">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting">
                <i class="fa-solid fa-floppy-disk me-1"></i>
                {{ isSubmitting ? "Dang luu..." : "Luu thay doi" }}
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

import SizeService from "@/services/size.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);
const initialValues = ref({ size: "" });
const originalSize = ref("");

const schema = yup.object({
  size: yup.string().trim().required("Vui long nhap kich thuoc").max(20, "Toi da 20 ky tu"),
});

async function fetchSize() {
  loading.value = true;
  try {
    const res = await SizeService.get(id);
    const data = res?.data ?? res;
    const size = data?.size ?? "";

    originalSize.value = size;
    initialValues.value = { size };
    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Khong the tai kich thuoc.";
    await Swal.fire("Loi", msg, "error");
    router.push({ name: "sizes.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { size: originalSize.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await SizeService.update(id, { size: values.size });
    await Swal.fire("Thanh cong!", "Cap nhat kich thuoc thanh cong!", "success");
    originalSize.value = values.size;
    resetForm({ values: { size: values.size } });
    router.push({ name: "sizes.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cap nhat kich thuoc that bai. Vui long thu lai.";
    await Swal.fire("Cap nhat kich thuoc that bai", msg, "error");
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

onMounted(fetchSize);
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
