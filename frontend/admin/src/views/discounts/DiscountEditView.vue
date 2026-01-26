<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa mã khuyến mãi</h4>
          <div class="small opacity-75">Cập nhật thông tin khuyến mãi</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'discounts.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Dang tai du lieu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, resetForm }">
            <div class="row g-3">
              <div class="col-12 col-lg-6">
                <label class="form-label">Mã/tên khuyến mãi</label>
                <Field name="name" v-slot="{ field, meta }">
                  <input v-bind="field" type="text" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="name" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-lg-6">
                <label class="form-label">Danh mục áp dụng</label>
                <Field name="category_id" v-slot="{ field, meta }">
                  <select v-bind="field" class="form-select bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }">
                    <option value="">Chọn danh mục</option>
                    <option v-for="c in categories" :key="c.id" :value="String(c.id)">
                      {{ c.name }}
                    </option>
                  </select>
                </Field>
                <ErrorMessage name="category_id" class="invalid-feedback d-block" />
              </div>

              <div class="col-12">
                <label class="form-label">Mô tả</label>
                <Field name="description" v-slot="{ field, meta }">
                  <textarea v-bind="field" rows="3" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }"></textarea>
                </Field>
                <ErrorMessage name="description" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Phần trăm</label>
                <Field name="percent" v-slot="{ field, meta }">
                  <input v-bind="field" type="number" min="0" max="100" step="0.01" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="percent" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Trạng thái</label>
                <Field name="status" v-slot="{ field, meta }">
                  <select v-bind="field" class="form-select bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }">
                    <option value="active">Đang bật</option>
                    <option value="disabled">Đang tắt</option>
                    <option value="expired">Hết hạn</option>
                  </select>
                </Field>
                <ErrorMessage name="status" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Bắt đầu</label>
                <Field name="start_at" v-slot="{ field, meta }">
                  <input v-bind="field" type="datetime-local" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="start_at" class="invalid-feedback d-block" />
              </div>

              <div class="col-12 col-md-3">
                <label class="form-label">Kết thúc</label>
                <Field name="end_at" v-slot="{ field, meta }">
                  <input v-bind="field" type="datetime-local" class="form-control bg-transparent"
                    :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                </Field>
                <ErrorMessage name="end_at" class="invalid-feedback d-block" />
              </div>
            </div>

            <div class="d-flex gap-2 mt-3">
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

import DiscountService from "@/services/discount.service";
import CategoryService from "@/services/category.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);
const categories = ref([]);

const initialValues = ref({
  name: "",
  description: "",
  category_id: "",
  percent: "",
  start_at: "",
  end_at: "",
  status: "active",
});
const originalValues = ref({ ...initialValues.value });

const schema = yup.object({
  name: yup.string().trim().required("Vui lòng nhập mã/tên khuyến mãi"),
  description: yup.string().trim().nullable(),
  category_id: yup.string().required("Vui lòng chọn danh mục"),
  percent: yup
    .number()
    .typeError("Phần trăm không hợp lệ")
    .min(0, "Phần trăm tối thiểu 0")
    .max(100, "Phần trăm tối đa 100")
    .required("Vui lòng nhập phần trăm"),
  start_at: yup.string().required("Vui lòng chọn ngày bắt đầu"),
  end_at: yup
    .string()
    .required("Vui lòng chọn ngày kết thúc")
    .test("end_after", "Ngày kết thúc phải sau ngày bắt đầu", function (value) {
      const { start_at } = this.parent;
      if (!value || !start_at) return true;
      return new Date(value) >= new Date(start_at);
    }),
  status: yup.string().required("Vui lòng chọn trạng thái"),
});

function toInputDateTime(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (num) => String(num).padStart(2, "0");
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}`
  );
}

async function fetchData() {
  loading.value = true;
  try {
    const [discountRes, categoriesRes] = await Promise.all([
      DiscountService.get(id),
      CategoryService.getAll({ per_page: 200 }),
    ]);

    const data = discountRes;
    categories.value = categoriesRes.items ?? [];

    const mapped = {
      name: data?.name ?? "",
      description: data?.description ?? "",
      category_id: data?.category_id ? String(data.category_id) : "",
      percent: data?.percent ?? "",
      start_at: toInputDateTime(data?.start_at),
      end_at: toInputDateTime(data?.end_at),
      status: data?.status ?? "active",
    };

    initialValues.value = mapped;
    originalValues.value = { ...mapped };
    formKey.value += 1;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải khuyến mãi. Vui lòng thử lại.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "discounts.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetFormFn) {
  resetFormFn({ values: { ...originalValues.value } });
}

async function onSubmit(values, { resetForm, setErrors }) {
  try {
    await DiscountService.update(id, {
      name: values.name?.trim(),
      description: values.description?.trim() || null,
      category_id: Number(values.category_id),
      percent: Number(values.percent),
      start_at: values.start_at,
      end_at: values.end_at,
      status: values.status,
    });

    await Swal.fire("Thành công!", "Cập nhật khuyến mãi thành công!", "success");
    originalValues.value = { ...values };
    resetForm({ values: { ...values } });
    router.push({ name: "discounts.list" });
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Cập nhật khuyến mãi thất bại. Vui lòng thử lại.";
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

onMounted(fetchData);
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
