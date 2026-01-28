<template>
  <aside class="sidebar p-3" :style="{ width: collapsed ? '84px' : '280px' }">
    <div class="d-flex align-items-center justify-content-between mb-3">
      <div class="d-flex align-items-center gap-2 overflow-hidden">
        <div class="logo-wrapper flex-shrink-0">
          <img src="@/assets/logo1.jpeg" alt="Logo" class="brand-logo" />
        </div>
        <span v-if="!collapsed" class="fw-bold text-nowrap brand-name">
          RoyalStore
        </span>
      </div>

      <button class="btn btn-sm btn-toggle-sidebar" @click="$emit('toggle')">
        <i class="fa-solid" :class="collapsed ? 'fa-arrow-right' : 'fa-arrow-left'"></i>
      </button>
    </div>

    <div class="small text-uppercase opacity-75 mb-2" v-if="!collapsed">
      Menu
    </div>

    <nav class="nav flex-column gap-1">
      <RouterLink class="nav-link" :class="{ active: route.name === 'dashboard' }" to="/">
        <i class="fa-solid fa-gauge-high me-2"></i>
        <span v-if="!collapsed">Trang chủ</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('products.') }" to="/products">
        <i class="fa-solid fa-boxes-stacked me-2"></i>
        <span v-if="!collapsed">Sản phẩm</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('warehouses.') }"
        to="/warehouses">
        <i class="fa-solid fa-warehouse me-2"></i>
        <span v-if="!collapsed">Kho</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('receipts.') }" to="/receipts">
        <i class="fa-solid fa-file-invoice me-2"></i>
        <span v-if="!collapsed">Phiếu nhập</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('categories.') }"
        to="/categories">
        <i class="fa-solid fa-folder-tree me-2"></i>
        <span v-if="!collapsed">Danh mục</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('distributors.') }"
        to="/distributors">
        <i class="fa-solid fa-truck me-2"></i>
        <span v-if="!collapsed">Nhà cung cấp</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('promotions.') }"
        to="/discounts">
        <i class="fa-solid fa-percent me-2"></i>
        <span v-if="!collapsed">Khuyến mãi</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{
        active: route.name?.toString().startsWith('payment-methods.'),
      }" to="/payments">
        <i class="fa-solid fa-credit-card me-2"></i>
        <span v-if="!collapsed">Phương thức thanh toán</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('users.') }" to="/users">
        <i class="fa-solid fa-users me-2"></i>
        <span v-if="!collapsed">Tài khoản</span>
      </RouterLink>

      <RouterLink class="nav-link" :class="{ active: route.name?.toString().startsWith('orders.') }" to="/orders">
        <i class="fa-solid fa-receipt me-2"></i>
        <span v-if="!collapsed">Đơn hàng</span>
      </RouterLink>

      <div class="nav-link" role="button" @click="onLogout()">
        <i class="fa-solid fa-arrow-right-from-bracket me-2"></i>
        <span v-if="!collapsed">Đăng xuất</span>
      </div>
    </nav>

    <div class="mt-auto pt-3 border-top border-opacity-25 small" v-if="!collapsed">
      <div class="opacity-75">Logged in</div>
      <div class="fw-semibold">Admin</div>
    </div>
  </aside>
</template>

<script setup>
import router from "@/routers";
import authService from "@/services/auth.service";
import Swal from "sweetalert2";
import { useRoute } from "vue-router";
defineProps({ collapsed: { type: Boolean, default: false } });
const route = useRoute();

const onLogout = async () => {
  const confirm = await Swal.fire({
    title: "Bạn có chắc chắn muốn đăng xuất?",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Đăng xuất",
    cancelButtonText: "Hủy",
  });
  if (confirm.isConfirmed) {
    try {
      await authService.logout();
      router.push("/login");
    } catch (e) {
      await Swal.fire("Lỗi!", "Đăng xuất không thành công!", "error");
      router.push("/login");
      console.error("Logout error:", e);
    }
  }
};
</script>

<style scoped>
.sidebar {
  transition: width 0.2s ease;
  background: #4a566d;
  border-right: 1px solid #3d475a;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  color: #e2e7ef;
}

.brand-badge {
  background: var(--main-color);
  color: var(--dark);
}

.nav-link {
  border-radius: 0.65rem;
  padding: 0.55rem 0.75rem;
  color: #e2e7ef;
  border: 1px solid transparent;
}

.nav-link:hover {
  background: #556279;
  border-color: #3d475a;
}

.nav-link.active {
  background: #3e4a60;
  border-color: #394356;
  color: #ffffff;
}

.logo-wrapper {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3e4a60;
  /* Màu nền tối giống logo của bạn */
  border-radius: 50%;
  padding: 2px;
  border: 1px solid #5b687f;
}

.brand-logo {
  width: 100%;
  height: 100%;
  object-fit: contain;
  border-radius: 50%;
}

.brand-name {
  color: #f5f7fb;
  font-size: 1.15rem;
  letter-spacing: -0.5px;
}

/* Tùy chỉnh nút toggle cho đẹp hơn */
.btn-toggle-sidebar {
  border: 1px solid #5b687f;
  color: #d3d9e4;
  border-radius: 8px;
  padding: 4px 8px;
}

.btn-toggle-sidebar:hover {
  background: #556279;
  color: #ffffff;
}

.sidebar .small,
.sidebar .opacity-75 {
  color: #c3cbd7 !important;
}
</style>
