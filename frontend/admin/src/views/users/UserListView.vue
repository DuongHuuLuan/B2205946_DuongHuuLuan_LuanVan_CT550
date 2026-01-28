<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Tài Khoản</h4>
          <div class="small opacity-75">Quản lý danh sách tài khoản</div>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div class="row g-2 align-items-center">
            <div class="col-12 col-md-6 col-lg-5">
              <SearchToggle v-model="keyword" placeholder="Tìm theo email hoặc username..." />
            </div>

            <div class="col-12 col-md-6 col-lg-3">
              <select v-model="role" class="form-select bg-transparent">
                <option value="">Tất cả vai trò</option>
                <option value="admin">Admin</option>
                <option value="user">User</option>
              </select>
            </div>

            <div class="col-12 col-lg-4 d-flex justify-content-md-end gap-2">
              <span class="badge bg-secondary-subtle text-secondary align-self-center">
                Tổng: {{ meta.total }}
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
                  <th class="ps-3" style="width: 140px">Mã TK</th>
                  <th>Username</th>
                  <th>Email</th>
                  <th style="width: 140px">Vai trò</th>
                  <th class="text-end" style="width: 160px">Ngày tạo</th>
                  <th class="text-end pe-3" style="width: 140px">Thao tác</th>
                </tr>
              </thead>

              <tbody v-if="items.length">
                <tr v-for="u in items" :key="u.id">
                  <td class="ps-3">
                    <span class="code-pill">U{{ u.id }}</span>
                  </td>

                  <td>
                    <RouterLink class="name-link" :to="{ name: 'users.detail', params: { id: u.id } }">
                      <div class="fw-semibold">{{ u.username || "-" }}</div>
                    </RouterLink>
                  </td>

                  <td>
                    <span class="opacity-75">{{ u.email || "-" }}</span>
                  </td>

                  <td>
                    <span class="badge" :class="roleBadgeClass(u.role)">
                      {{ roleLabel(u.role) }}
                    </span>
                  </td>

                  <td class="text-end">
                    <span class="small opacity-75">{{ formatDate(u.created_at) }}</span>
                  </td>

                  <td class="text-end pe-4">
                    <div class="d-flex justify-content-end gap-2">
                      <RouterLink class="icon-btn icon-edit" :to="{ name: 'users.edit', params: { id: u.id } }"
                        title="Chỉnh sửa">
                        <i class="fa-solid fa-pen-to-square"></i>
                      </RouterLink>
                    </div>
                  </td>
                </tr>
              </tbody>

              <tbody v-else>
                <tr>
                  <td colspan="6" class="text-center py-5">
                    <div class="opacity-75">
                      <i class="fa-regular fa-folder-open fs-4 d-block mb-2"></i>
                      Không có tài khoản phù hợp.
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="d-flex justify-content-between align-items-center p-3 border-top" v-if="meta.total">
            <div class="small opacity-75">
              Hiển thị {{ (meta.current_page - 1) * meta.per_page + 1 }}
              -
              {{ Math.min(meta.current_page * meta.per_page, meta.total) }}
              /
              {{ meta.total }}
            </div>

            <div class="btn-group">
              <button class="btn btn-outline-secondary btn-sm" :disabled="page === 1" @click="page--">
                <i class="fa-solid fa-chevron-left"></i>
              </button>
              <button class="btn btn-outline-secondary btn-sm" disabled>
                Trang {{ page }}
              </button>
              <button class="btn btn-outline-secondary btn-sm" :disabled="meta.current_page >= meta.last_page"
                @click="page++">
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
import SearchToggle from '@/components/common/SearchToggle.vue';
import Swal from "sweetalert2";
import UserService from "@/services/user.service";

const keyword = ref("");
const role = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });
const loading = ref(false);

function roleLabel(value) {
  switch (value) {
    case "admin":
      return "Admin";
    case "user":
      return "User";
    default:
      return "-";
  }
}

function roleBadgeClass(value) {
  switch (value) {
    case "admin":
      return "role-admin";
    case "user":
      return "role-user";
    default:
      return "bg-secondary-subtle text-secondary";
  }
}

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleDateString("vi-VN");
}

async function fetchUsers() {
  loading.value = true;
  try {
    const res = await UserService.getAll({
      q: keyword.value.trim() || undefined,
      role: role.value || undefined,
      page: page.value,
      per_page: perPage,
    });

    const list = res.items ?? [];
    items.value = Array.isArray(list) ? list : [];

    meta.value = res?.meta ?? {
      current_page: 1,
      per_page: perPage,
      total: 0,
      last_page: 1,
    };
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải tài khoản. Vui lòng thử lại!";
    Swal.fire("Lỗi", msg, "error");
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await fetchUsers();
});

watch([keyword, role], async () => {
  page.value = 1;
  await fetchUsers();
});

watch(page, async () => {
  await fetchUsers();
});
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

.code-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.3rem 0.6rem;
  border-radius: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.2px;
  background: color-mix(in srgb, var(--main-color) 14%, transparent);
  border: 1px solid var(--hover-border-color);
  color: var(--font-color);
}

.role-admin {
  background: color-mix(in srgb, #16a34a 18%, transparent);
  border: 1px solid color-mix(in srgb, #16a34a 45%, transparent);
  color: var(--font-color);
  font-weight: 700;
}

.role-user {
  background: color-mix(in srgb, #0ea5e9 18%, transparent);
  border: 1px solid color-mix(in srgb, #0ea5e9 45%, transparent);
  color: var(--font-color);
  font-weight: 700;
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

.icon-edit {
  color: #f59e0b;
}
</style>


