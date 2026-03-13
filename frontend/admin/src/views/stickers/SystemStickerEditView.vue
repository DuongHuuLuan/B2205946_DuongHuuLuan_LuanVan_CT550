<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chỉnh sửa sticker hệ thống</h4>
          <div class="small opacity-75">Cập nhật tên, ảnh và thông tin kỹ thuật của sticker.</div>
        </div>

        <RouterLink class="btn btn-outline-secondary" :to="{ name: 'stickers.detail', params: { id } }">
          <i class="fa-solid fa-arrow-left me-1"></i> Về chi tiết
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải dữ liệu...
          </div>

          <Form v-else :key="formKey" :initial-values="initialValues" :validation-schema="schema" @submit="onSubmit"
            v-slot="{ isSubmitting, values, resetForm, setFieldValue, setFieldError }">
            <Field name="image_url" type="hidden" />

            <div class="row g-3">
              <div class="col-12 col-lg-7">
                <div class="mb-3">
                  <label class="form-label">Tên sticker</label>
                  <Field name="name" v-slot="{ field, meta }">
                    <input v-bind="field" type="text" class="form-control bg-transparent"
                      :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                  </Field>
                  <ErrorMessage name="name" class="invalid-feedback d-block" />
                </div>

                <div class="mb-3">
                  <label class="form-label">Ảnh sticker</label>
                  <input ref="fileInputRef" type="file" accept="image/*" class="form-control bg-transparent"
                    :disabled="imageUploading" @change="handleImageSelected($event, setFieldValue, setFieldError)" />
                  <div class="form-text">
                    Chọn ảnh mới nếu cần thay thế ảnh sticker hiện tại trên Cloudinary.
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
                        :class="{ 'is-invalid': meta.touched && !meta.valid }" />
                    </Field>
                    <ErrorMessage name="category" class="invalid-feedback d-block" />
                  </div>

                  <div class="col-12 col-md-6">
                    <label class="form-label">Public ID (Cloudinary)</label>
                    <Field name="public_id" v-slot="{ field }">
                      <input v-bind="field" type="text" class="form-control bg-transparent" />
                    </Field>
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

                <div class="d-flex gap-2 mt-4">
                  <button class="btn btn-accent" type="submit" :disabled="isSubmitting || imageUploading">
                    <i class="fa-solid fa-floppy-disk me-1"></i>
                    {{ isSubmitting ? "Đang lưu..." : "Lưu thay đổi" }}
                  </button>

                  <button class="btn btn-outline-secondary" type="button" :disabled="isSubmitting || imageUploading"
                    @click="onReset(resetForm, setFieldValue)">
                    <i class="fa-solid fa-rotate-left me-1"></i> Làm mới
                  </button>
                </div>
              </div>

              <div class="col-12 col-lg-5">
                <div class="preview-card">
                  <div class="preview-label">Xem trước</div>
                  <div class="preview-shell">
                    <img v-if="values.image_url" :src="values.image_url" alt="Sticker preview" />
                    <div v-else class="preview-empty">
                      <i class="fa-regular fa-image fs-2 mb-2"></i>
                      <div>Không có ảnh sticker</div>
                    </div>
                  </div>
                  <button v-if="values.image_url" type="button" class="btn btn-outline-secondary btn-sm mt-3"
                    :disabled="imageUploading" @click="clearUploadedImage(setFieldValue)">
                    <i class="fa-solid fa-xmark me-1"></i> Bỏ ảnh hiện tại
                  </button>
                </div>
              </div>
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

import ImageUploadService from "@/services/image-upload.service";
import StickerService from "@/services/sticker.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const formKey = ref(0);
const fileInputRef = ref(null);
const imageUploading = ref(false);
const uploadSuccessMessage = ref("");
const originalValues = ref(null);
const initialValues = ref({
  name: "",
  image_url: "",
  category: "General",
  public_id: "",
  has_transparent_background: false,
  is_ai_generated: false,
});

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

async function fetchSticker() {
  loading.value = true;
  try {
    const sticker = await StickerService.get(id);
    originalValues.value = {
      name: sticker?.name || "",
      image_url: sticker?.image_url || "",
      category: sticker?.category || "General",
      public_id: sticker?.public_id || "",
      has_transparent_background: Boolean(sticker?.has_transparent_background),
      is_ai_generated: Boolean(sticker?.is_ai_generated),
    };
    initialValues.value = { ...originalValues.value };
    formKey.value += 1;
    resetUploadUi();
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Không thể tải dữ liệu sticker.";
    await Swal.fire("Lỗi", message, "error");
    router.push({ name: "stickers.list" });
  } finally {
    loading.value = false;
  }
}

function onReset(resetForm, setFieldValue) {
  const nextValues = { ...originalValues.value };
  resetForm({ values: nextValues });
  setFieldValue("image_url", nextValues.image_url || "");
  resetUploadUi();
}

async function onSubmit(values, { setErrors, resetForm }) {
  try {
    await StickerService.update(id, {
      ...values,
      public_id: String(values.public_id || "").trim() || null,
    });
    originalValues.value = { ...values };
    resetForm({ values: { ...values } });
    resetUploadUi();
    await Swal.fire("Thành công", "Đã cập nhật thông tin sticker.", "success");
    router.push({ name: "stickers.detail", params: { id } });
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      "Cập nhật sticker thất bại.";
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

onMounted(fetchSticker);
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