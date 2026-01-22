<template>
  <div class="row g-3">
    <!-- Header -->
    <div class="col-12">
      <div
        class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row"
      >
        <div>
          <h4 class="mb-1">Phương thức thanh toán</h4>
          <div class="small opacity-75">Quản lý danh sách phương thức</div>
        </div>

        <RouterLink
          class="icon-btn icon-add"
          :to="{ name: 'payments.create' }"
          title="Thêm phương thức"
        >
          <i class="fa-solid fa-circle-plus"></i>
        </RouterLink>
      </div>
    </div>

    <!-- Toolbar -->
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
                  placeholder="Tìm theo tên phương thức..."
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

            <div
              class="col-12 col-md-6 col-lg-7 d-flex justify-content-md-end gap-2"
            >
              <span
                class="badge bg-secondary-subtle text-secondary align-self-center"
              >
                Tổng: {{ meta.total }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
              <thead>
                <tr>
                  <th class="ps-3" style="width: 180px">Mã phương thức</th>
                  <th>Tên phương thức</th>
                  <th class="text-end" style="width: 180px">Trạng thái</th>
                  <th class="text-end pe-3" style="width: 160px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="p in items" :key="p.id">
                  <td class="ps-3">
                    <span class="code-pill">PAY{{ p.id }}</span>
                  </td>

                  <td class="ps-3">
                    <RouterLink
                      class="name-link"
                      :to="{ name: 'payments.detail', params: { id: p.id } }"
                    >
                      <div class="fw-semibold">{{ p.name }}</div>
                    </RouterLink>
                  </td>

                  <td class="text-end">
                    <span class="badge" :class="statusBadgeClass(p.status)">
                      {{ statusLabel(p.status) }}
                    </span>
                  </td>

                  <td class="text-end pe-3">
                    <div class="d-flex justify-content-end gap-2">
                      <RouterLink
                        class="icon-btn icon-edit"
                        :to="{ name: 'payments.edit', params: { id: p.id } }"
                        title="Chỉnh sửa"
                      >
                        <i class="fa-solid fa-pen-to-square"></i>
                      </RouterLink>

                      <button
                        class="icon-btn icon-delete"
                        title="Xoá"
                        @click="onDeleteClick(p.id)"
                      >
                        <i class="fa-solid fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="4" class="text-center py-5">
                    <div class="opacity-75">
                      <i
                        class="fa-regular fa-folder-open fs-4 d-block mb-2"
                      ></i>
                      Không có phương thức phù hợp.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div
            class="d-flex justify-content-between align-items-center p-3 border-top"
            v-if="meta.total"
          >
            <div class="small opacity-75">
              Hiển thị
              {{ (meta.current_page - 1) * meta.per_page + 1 }}
              -
              {{ Math.min(meta.current_page * meta.per_page, meta.total) }}
              /
              {{ meta.total }}
            </div>

            <div class="btn-group">
              <button
                class="btn btn-outline-secondary btn-sm"
                :disabled="page === 1"
                @click="page--"
              >
                <i class="fa-solid fa-chevron-left"></i>
              </button>
              <button class="btn btn-outline-secondary btn-sm" disabled>
                Trang {{ page }}
              </button>
              <button
                class="btn btn-outline-secondary btn-sm"
                :disabled="meta.current_page >= meta.last_page"
                @click="page++"
              >
                <i class="fa-solid fa-chevron-right"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from "vue";
import Swal from "sweetalert2";
import PaymentService from "../../services/payment.service";

const keyword = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });
const loading = ref(false);

function statusLabel(status) {
  switch (status) {
    case "actived":
      return "Đang bật";
    case "disabled":
      return "Đang tắt";
    default:
      return "-";
  }
}

function statusBadgeClass(status) {
  switch (status) {
    case "actived":
      return "status-actived";
    case "disabled":
      return "status-disabled";
    default:
      return "bg-secondary-subtle text-secondary";
  }
}

async function fetchPayments() {
  loading.value = true;
  try {
    const res = await PaymentService.getAll({
      q: keyword.value.trim() || undefined,
      page: page.value,
      per_page: perPage,
    });

    const list = res?.data?.items ?? res?.data ?? res?.items ?? [];
    items.value = Array.isArray(list) ? list : [];

    meta.value = res?.data?.meta ?? {
      current_page: 1,
      per_page: perPage,
      total: 0,
      last_page: 1,
    };
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải phương thức. Vui lòng thử lại!";
    Swal.fire("Lỗi", msg, "error");
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await fetchPayments();
});

watch(keyword, async () => {
  page.value = 1;
  await fetchPayments();
});

watch(page, async () => {
  await fetchPayments();
});

async function onDeleteClick(id) {
  const result = await Swal.fire({
    title: "Xóa phương thức này?",
    text: "Không thể hoàn tác!",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Xóa",
    cancelButtonText: "Hủy",
  });

  if (result.isConfirmed) {
    try {
      await PaymentService.delete(id);
      await fetchPayments();
      Swal.fire({ title: "Xóa thành công", icon: "success" });
    } catch (err) {
      await Swal.fire({
        title: "Lỗi",
        text: err?.response?.data?.message || "Không thể xóa",
        icon: "error",
      });
    }
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

.name-link {
  text-decoration: none;
  color: inherit;
  display: inline-block;
}

/* Status badges */
.status-actived {
  background: color-mix(in srgb, #16a34a 18%, transparent);
  border: 1px solid color-mix(in srgb, #16a34a 45%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.status-disabled {
  background: color-mix(in srgb, #ef4444 18%, transparent);
  border: 1px solid color-mix(in srgb, #ef4444 45%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

/* Icon buttons */
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
