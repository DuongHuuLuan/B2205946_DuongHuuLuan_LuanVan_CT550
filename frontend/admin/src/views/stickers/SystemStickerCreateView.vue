<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Thêm sticker hệ thống</h4>
          <div class="small opacity-75">Nhập thông tin sticker dùng chung.</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'stickers.list' }">
          <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <Form :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, values, resetForm, setFieldValue, setFieldError }">
            <Field name="image_url" type="hidden" />
            <Field name="public_id" type="hidden" />

            <div class="row g-3">
              <div class="col-12 col-lg-7">
                <div class="mb-3">
                  <label class="form-label">Tên sticker</label>
                  <Field name="name" v-slot="{ field, meta }">
                    <input v-bind="field" type="text" class="form-control bg-transparent"
                      :class="{ 'is-invalid': meta.touched && !meta.valid }"
                      placeholder="Ví dụ: Royal stripe, logo cánh chim..." />
                  </Field>
                  <ErrorMessage name="name" class="invalid-feedback d-block" />
                </div>

                <div class="mb-3">
                  <label class="form-label">Ảnh sticker</label>
                  <input ref="fileInputRef" type="file" accept="image/*" class="form-control bg-transparent"
                    :disabled="imageUploading" @change="handleImageSelected($event, setFieldValue, setFieldError)" />
                  <div class="form-text">
                    Ảnh sẽ được upload lên Cloudinary và tự động gán vào sticker.
                  </div>
                  <div v-if="imageUploading" class="small text-warning mt-2">
                    <i class="fa-solid fa-spinner fa-spin me-1"></i>
                    Đang upload ảnh...
                  </div>
                  <div v-else-if="uploadSuccessMessage" class="small text-success mt-2">
                    <i class="fa-solid fa-circle-check me-1"></i>
                    {{ uploadSuccessMessage }}
                  </div>
                  <ErrorMessage name="image_url" class="invalid-feedback d-block" />
                </div>

                <div class="row g-3">
                  <div class="col-12 col-md-6">
                    <label class="form-label">Danh mục (Category)</label>
                    <Field name="category" v-slot="{ field, meta }">
                      <input v-bind="field" type="text" class="form-control bg-transparent"
                        :class="{ 'is-invalid': meta.touched && !meta.valid }" placeholder="General" />
                    </Field>
                    <ErrorMessage name="category" class="invalid-feedback d-block" />
                  </div>
                </div>

                <div class="row g-3 mt-1">
                  <div class="col-12 col-md-6">
                    <div class="form-check">
                      <Field name="has_transparent_background" type="checkbox" class="form-check-input" />
                      <label class="form-check-label">Có nền trong suốt</label>
                    </div>
                  </div>
                  <div class="col-12 col-md-6">
                    <div class="form-check">
                      <Field name="is_ai_generated" type="checkbox" class="form-check-input" />
                      <label class="form-check-label">Sticker AI</label>
                    </div>
                  </div>
                </div>
              </div>

              <div class="col-12 col-lg-5">
                <div class="preview-card">
                  <div class="preview-label">Xem trước</div>
                  <div class="preview-shell">
                    <img v-if="values.image_url" :src="values.image_url" alt="Sticker preview" />
                    <div v-else class="preview-empty">
                      <i class="fa-regular fa-image fs-2 mb-2"></i>
                      <div>Chọn ảnh để xem trước</div>
                    </div>
                  </div>
                  <button v-if="values.image_url" type="button" class="btn btn-outline-secondary btn-sm mt-3"
                    :disabled="imageUploading" @click="clearUploadedImage(setFieldValue)">
                    <i class="fa-solid fa-xmark me-1"></i> Bỏ ảnh đã chọn
                  </button>
                </div>
              </div>
            </div>

            <div class="d-flex gap-2 mt-4">
              <button class="btn btn-accent" type="submit" :disabled="isSubmitting || imageUploading">
                <i class="fa-solid fa-circle-plus me-1"></i>
                {{ isSubmitting ? "Đang tạo..." : "Tạo sticker" }}
              </button>

              <button class="btn btn-outline-secondary" type="button" :disabled="isSubmitting || imageUploading"
                @click="onReset(resetForm, setFieldValue)">
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
import { ref } from "vue";
import { Form, Field, ErrorMessage } from "vee-validate";
import * as yup from "yup";
import Swal from "sweetalert2";
import { useRouter } from "vue-router";

import ImageUploadService from "@/services/image-upload.service";
import StickerService from "@/services/sticker.service";

const router = useRouter();
const fileInputRef = ref(null);
const imageUploading = ref(false);
const uploadSuccessMessage = ref("");

const schema = yup.object({
  name: yup.string().trim().required("Vui lòng nhập tên sticker").max(255, "Tên quá dài"),
  image_url: yup.string().trim().required("Vui lòng upload ảnh sticker").url("Đường dẫn ảnh không hợp lệ"),
  category: yup.string().trim().required("Vui lòng nhập danh mục").max(100, "Tên danh mục quá dài"),
  public_id: yup.string().trim().max(255, "Public ID quá dài").nullable(),
  has_transparent_background: yup.boolean().default(false),
  is_ai_generated: yup.boolean().default(false),
});

function resetUploadUi() {
  uploadSuccessMessage.value = "";
  if (fileInputRef.value) {
    fileInputRef.value.value = "";
  }
}

function clearUploadedImage(setFieldValue) {
  setFieldValue("image_url", "");
  setFieldValue("public_id", "");
  resetUploadUi();
}

async function handleImageSelected(event, setFieldValue, setFieldError) {
  const file = event?.target?.files?.[0];
  if (!file) return;

  imageUploading.value = true;
  uploadSuccessMessage.value = "";
  setFieldError("image_url", undefined);

  try {
    const uploaded = await ImageUploadService.upload(file, "helmet_shop/stickers");
    setFieldValue("image_url", uploaded?.url || "");
    setFieldValue("public_id", uploaded?.public_id || "");
    uploadSuccessMessage.value = "Upload ảnh thành công.";
  } catch (error) {
    setFieldValue("image_url", "");
    setFieldValue("public_id", "");
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Upload ảnh thất bại.";
    setFieldError("image_url", message);
    await Swal.fire("Lỗi", message, "error");
  } finally {
    imageUploading.value = false;
  }
}

function onReset(resetForm, setFieldValue) {
  resetForm({
    values: {
      name: "",
      image_url: "",
      category: "General",
      public_id: "",
      has_transparent_background: false,
      is_ai_generated: false,
    },
  });
  clearUploadedImage(setFieldValue);
}

async function onSubmit(values, { setErrors, resetForm }) {
  try {
    await StickerService.create({
      ...values,
      public_id: String(values.public_id || "").trim() || null,
    });
    await Swal.fire("Thành công", "Đã tạo sticker hệ thống.", "success");
    resetForm();
    resetUploadUi();
    router.push({ name: "stickers.list" });
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Tạo sticker thất bại.";
    await Swal.fire("Lỗi", message, "error");

    const backendErrors = error?.response?.data?.errors || {};
    const mapped = {};
    Object.keys(backendErrors).forEach((key) => {
      mapped[key] = Array.isArray(backendErrors[key])
        ? backendErrors[key][0]
        : String(backendErrors[key]);
    });
    setErrors(mapped);
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

.preview-card {
  height: 100%;
}

.preview-label {
  font-weight: 600;
  margin-bottom: 0.75rem;
}

.preview-shell {
  min-height: 320px;
  border-radius: 1rem;
  border: 1px dashed var(--border-color);
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.preview-shell img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.preview-empty {
  opacity: 0.72;
  text-align: center;
}
</style>