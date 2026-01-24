<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
        <div>
          <h4 class="mb-1">Chi tiết tài khoản</h4>
          <div class="small opacity-75">ID: {{ id }}</div>
        </div>

        <div class="d-flex gap-2">
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'users.list' }">
            <i class="fa-solid fa-arrow-left me-1"></i> Quay lại
          </RouterLink>
          <RouterLink class="btn btn-outline-secondary" :to="{ name: 'users.edit', params: { id } }">
            <i class="fa-solid fa-pen-to-square me-1"></i> Chỉnh sửa
          </RouterLink>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft">
        <div class="card-body">
          <div v-if="loading" class="py-4 text-center opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i> Đang tải tài liệu...
          </div>

          <div v-else-if="!user" class="py-4 text-center opacity-75">
            Không tìm thấy tài khoản.
          </div>

          <div v-else>
            <div class="mb-2">
              <span class="label">Username:</span> {{ user.username || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Email:</span> {{ user.email || "-" }}
            </div>
            <div class="mb-2">
              <span class="label">Vai trò:</span> {{ roleLabel(user.role) }}
            </div>
            <div class="mb-2">
              <span class="label">Ngày tạo:</span> {{ formatDate(user.created_at) }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import Swal from "sweetalert2";
import UserService from "@/services/user.service";

const props = defineProps({ id: String });
const router = useRouter();

const loading = ref(true);
const user = ref(null);

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

function formatDate(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN");
}

async function fetchUser() {
  loading.value = true;
  try {
    const res = await UserService.get(props.id);
    user.value = res?.data ?? res;
  } catch (e) {
    const msg =
      e?.response?.data?.message ||
      e?.response?.data?.error ||
      "Không thể tải tài khoản.";
    await Swal.fire("Lỗi", msg, "error");
    router.push({ name: "users.list" });
  } finally {
    loading.value = false;
  }
}

onMounted(fetchUser);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.label {
  font-weight: 600;
}
</style>
