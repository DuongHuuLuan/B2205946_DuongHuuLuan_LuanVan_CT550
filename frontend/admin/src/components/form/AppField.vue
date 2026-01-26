<template>
  <div class="mb-3">
    <label v-if="label" class="form-label" :for="name">{{ label }}</label>

    <Field :name="name" v-slot="{ field, errorMessage, meta }">
      <div v-if="inputGroup" class="input-group">
        <span class="input-group-text">
          <i :class="icon"></i>
        </span>

        <input
          v-bind="field"
          :id="name"
          :type="type"
          class="form-control"
          :class="{ 'is-invalid': shouldShowError(meta, errorMessage) }"
          :placeholder="placeholder"
          :autocomplete="autocomplete"
        />
      </div>

      <input
        v-else
        v-bind="field"
        :id="name"
        :type="type"
        class="form-control"
        :class="{ 'is-invalid': shouldShowError(meta, errorMessage) }"
        :placeholder="placeholder"
        :autocomplete="autocomplete"
      />

      <div
        v-if="shouldShowError(meta, errorMessage)"
        class="invalid-feedback d-block"
      >
        {{ errorMessage }}
      </div>
      <div v-else-if="hint" class="form-text">{{ hint }}</div>
    </Field>
  </div>
</template>

<script setup>
import { Field } from "vee-validate";

const props = defineProps({
  name: { type: String, required: true },
  label: { type: String, default: "" },
  type: { type: String, default: "text" },
  placeholder: { type: String, default: "" },
  hint: { type: String, default: "" },
  autocomplete: { type: String, default: "" },
  inputGroup: { type: Boolean, default: true },
  icon: { type: String, default: "fa-solid fa-pen" },
});

// Hiện lỗi khi người dùng đã chạm field (touched) hoặc sau khi submit fail (submitCount > 0)
function shouldShowError(meta, errorMessage) {
  return !!errorMessage && (meta.touched || meta.submitCount > 0);
}
</script>
