<template>
  <div class="row g-3">
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Kich thuoc</h4>
          <div class="small opacity-75">Quan ly danh sach kich thuoc</div>
        </div>

        <RouterLink
          class="icon-btn icon-add"
          :to="{ name: 'sizes.create' }"
          title="Them kich thuoc"
        >
          <i class="fa-solid fa-circle-plus"></i>
        </RouterLink>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md-6 col-lg-5">
              <div class="input-group">
                <span class="input-group-text bg-transparent">
                  <i class="fa-solid fa-magnifying-glass"></i>
                </span>
                <input
                  v-model="keyword"
                  type="text"
                  class="form-control bg-transparent"
                  placeholder="Tim theo kich thuoc..."
                />
                <button
                  class="btn btn-outline-secondary"
                  @click="keyword = ''"
                  v-if="keyword"
                  title="Clear"
                >
                  <i class="fa-solid fa-xmark"></i>
                </button>
              </div>
            </div>

            <div class="col-12 col-md-6 col-lg-7 d-flex justify-content-md-end gap-2">
              <span class="badge bg-secondary-subtle text-secondary align-self-center">
                Tong: {{ filteredItems.length }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th class="ps-3" style="width: 140px">Ma size</th>
                  <th>Gia tri</th>
                  <th class="text-end pe-3" style="width: 160px">Thao tac</th>
                </tr>
              </thead>

              <tbody v-if="filteredItems.length">
                <tr v-for="s in filteredItems" :key="s.id">
                  <td class="ps-3">
                    <span class="code-pill">S{{ s.id }}</span>
                  </td>
                  <td class="ps-3">
                    <RouterLink
                      class="name-link"
                      :to="{ name: 'sizes.detail', params: { id: s.id } }"
                    >
                      <div class="fw-semibold">{{ s.size }}</div>
                    </RouterLink>
                  </td>
                  <td class="text-end pe-3">
                    <div class="d-flex justify-content-end gap-2">
                      <RouterLink
                        class="icon-btn icon-edit"
                        :to="{ name: 'sizes.edit', params: { id: s.id } }"
                        title="Chinh sua"
                      >
                        <i class="fa-solid fa-pen-to-square"></i>
                      </RouterLink>

                      <button
                        class="icon-btn icon-delete"
                        title="Xoa"
                        @click="onDeleteClick(s.id)"
                      >
                        <i class="fa-solid fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="3" class="text-center py-5">
                    <div class="opacity-75">
                      <i class="fa-regular fa-folder-open fs-4 d-block mb-2"></i>
                      Khong co kich thuoc phu hop.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import Swal from "sweetalert2";
import SizeService from "@/services/size.service";

const keyword = ref("");
const items = ref([]);
const loading = ref(false);

const filteredItems = computed(() => {
  const kw = keyword.value.trim().toLowerCase();
  if (!kw) return items.value;
  return (items.value || []).filter((s) =>
    (s.size || "").toLowerCase().includes(kw)
  );
});

async function fetchSizes() {
  loading.value = true;
  try {
    const res = await SizeService.getAll();
    items.value = Array.isArray(res) ? res : res?.data ?? [];
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Khong the tai kich thuoc.";
    Swal.fire("Loi", msg, "error");
  } finally {
    loading.value = false;
  }
}

async function onDeleteClick(sizeId) {
  const result = await Swal.fire({
    title: "Xoa kich thuoc nay?",
    text: "Khong the hoan tac!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xoa",
    cancelButtonText: "Huy",
  });

  if (result.isConfirmed) {
    try {
      await SizeService.delete(sizeId);
      await fetchSizes();
      Swal.fire({ title: "Xoa thanh cong", icon: "success" });
    } catch (err) {
      await Swal.fire({
        title: "Loi",
        text: err?.response?.data?.message || "Khong the xoa",
        icon: "error",
      });
    }
  }
}

onMounted(fetchSizes);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.name-link {
  text-decoration: none;
  color: inherit;
  display: inline-block;
}

.icon-btn {
  width: 36px;
  height: 36px;
  border-radius: 0.75rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-color);
  background: transparent;
  text-decoration: none;
  transition: 0.12s ease;
}

.icon-btn:hover {
  background: var(--hover-background-color);
  border-color: var(--hover-border-color);
}

.icon-add {
  color: #16a34a;
}

.icon-edit {
  color: #f59e0b;
}

.icon-delete {
  color: #ef4444;
}

.icon-add {
  width: 42px;
  height: 42px;
  border-radius: 1rem;
}
</style>
