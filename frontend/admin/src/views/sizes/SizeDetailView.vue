<template>
  <div class="card card-soft">
    <div class="card-body">
      <div v-if="loading" class="py-4 text-center opacity-75">
        <i class="fa-solid fa-spinner fa-spin me-2"></i> Dang tai du lieu...
      </div>

      <div v-else>
        <h4 class="mb-1">Chi tiet kich thuoc</h4>
        <div class="small opacity-75">ID: {{ id }}</div>
        <div class="mt-2">
          <span class="fw-semibold">Gia tri:</span> {{ sizeValue || "-" }}
        </div>

        <hr />
        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'sizes.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lai
          </RouterLink>

          <RouterLink
            class="btn btn-outline-secondary"
            :to="{ name: 'sizes.edit', params: { id } }"
          >
            <i class="fa-solid fa-pen-to-square me-1"></i> Chinh sua
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import Swal from "sweetalert2";
import SizeService from "@/services/size.service";

const route = useRoute();
const router = useRouter();
const id = route.params.id;

const loading = ref(true);
const sizeValue = ref("");

async function fetchSize() {
  loading.value = true;
  try {
    const res = await SizeService.get(id);
    const data = res?.data ?? res;
    sizeValue.value = data?.size ?? "";
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

onMounted(fetchSize);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}
</style>
