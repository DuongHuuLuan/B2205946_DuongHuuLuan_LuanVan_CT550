import { createRouter, createWebHistory } from "vue-router";
import DashboardView from "../views/DashboardView.vue";
import ChatView from "../views/ChatView.vue";
import LoginView from "../views/auth/LoginView.vue";
import AppLayout from "../components/layout/AppLayout.vue";

import CategoryListView from "../views/categories/CategoryListView.vue";
import CategoryCreateView from "../views/categories/CategoryCreateView.vue";
import CategoryDetailView from "../views/categories/CategoryDetailView.vue";
import CategoryEditView from "../views/categories/CategoryEditView.vue";

import DistributorListView from "../views/distributors/DistributorListView.vue";
import DistributorCreateView from "../views/distributors/DistributorCreateView.vue";
import DistributorEditView from "../views/distributors/DistributorEditView.vue";
import DistributorDetailView from "../views/distributors/DistributorDetailView.vue";

import ProductListView from "../views/products/ProductListView.vue";
import ProductCreateView from "../views/products/ProductCreateView.vue";
import ProductEditView from "../views/products/ProductEditView.vue";
import ProductDetailView from "../views/products/ProductDetailView.vue";

import SizeListView from "../views/sizes/SizeListView.vue";
import SizeCreateView from "../views/sizes/SizeCreateView.vue";
import SizeEditView from "../views/sizes/SizeEditView.vue";
import SizeDetailView from "../views/sizes/SizeDetailView.vue";

import WarehouseListView from "../views/warehouses/WarehouseListView.vue";
import WarehouseCreateView from "../views/warehouses/WarehouseCreateView.vue";
import WarehouseEditView from "../views/warehouses/WarehouseEditView.vue";
import WarehouseDetailView from "../views/warehouses/WarehouseDetailView.vue";

import ReceiptListView from "../views/receipts/ReceiptListView.vue";
import ReceiptCreateView from "../views/receipts/ReceiptCreateView.vue";
import ReceiptDetailView from "../views/receipts/ReceiptDetailView.vue";

import OrderListView from "../views/orders/OrderListView.vue";
import OrderDetailView from "../views/orders/OrderDetailView.vue";
import OrderProductionView from "../views/orders/OrderProductionView.vue";

import SystemStickerListView from "../views/stickers/SystemStickerListView.vue";
import SystemStickerCreateView from "../views/stickers/SystemStickerCreateView.vue";
import SystemStickerEditView from "../views/stickers/SystemStickerEditView.vue";
import SystemStickerDetailView from "../views/stickers/SystemStickerDetailView.vue";

import PaymentListView from "../views/payments/PaymentListView.vue";
import PaymentCreateView from "../views/payments/PaymentCreateView.vue";
import PaymentEditView from "../views/payments/PaymentEditView.vue";
import PaymentDetailView from "../views/payments/PaymentDetailView.vue";

import DiscountListView from "../views/discounts/DiscountListView.vue";
import DiscountCreateView from "../views/discounts/DiscountCreateView.vue";
import DiscountEditView from "../views/discounts/DiscountEditView.vue";
import DiscountDetailView from "../views/discounts/DiscountDetailView.vue";

import UserListView from "../views/users/UserListView.vue";
import UserDetailView from "../views/users/UserDetailView.vue";

import AuthService from "@/services/auth.service";

const routes = [
  { path: "/login", name: "login", component: LoginView },

  {
    path: "/",
    component: AppLayout,
    meta: { requeresAuth: true },
    children: [
      {
        path: "/",
        name: "dashboard",
        component: DashboardView,
        // beforeEnter: requireAuth,
      },
      {
        path: "/statistics",
        alias: "/staticstics",
        name: "statistics",
        component: () => import("../views/StatisticsView.vue"),
        meta: { title: "Thống kê" },
      },

      {
        path: "/categories",
        name: "categories.list",
        component: CategoryListView,
        meta: {
          title: "Danh mục",
        },
      },
      {
        path: "/categories/create",
        name: "categories.create",
        component: CategoryCreateView,
        meta: {
          title: "Tạo danh mục",
        },
      },
      {
        path: "/categories/:id",
        name: "categories.detail",
        component: CategoryDetailView,
        meta: {
          title: "Chi tiết danh mục",
        },
        props: true,
      },
      {
        path: "/categories/:id/edit",
        name: "categories.edit",
        component: CategoryEditView,
        meta: {
          title: "Chỉnh sửa danh mục",
        },
        props: true,
      },

      {
        path: "/distributors",
        name: "distributors.list",
        component: DistributorListView,
        meta: {
          title: "Nhà cung cấp",
        },
      },
      {
        path: "/distributors/create",
        name: "distributors.create",
        component: DistributorCreateView,
        meta: {
          title: "Tạo nhà cung cấp",
        },
      },
      {
        path: "/distributors/:id/edit",
        name: "distributors.edit",
        component: DistributorEditView,
        meta: {
          title: "Chỉnh sửa nhà cung cấp",
        },
        props: true,
      },
      {
        path: "/distributors/:id",
        name: "distributors.detail",
        component: DistributorDetailView,
        meta: {
          title: "Chi tiết nhà cung cấp",
        },
        props: true,
      },
      {
        path: "/products",
        name: "products.list",
        component: ProductListView,
        meta: { title: "Sản phẩm" },
      },
      {
        path: "/products/create",
        name: "products.create",
        component: ProductCreateView,
        meta: { title: "Tạo sản phẩm" },
      },
      {
        path: "/products/:id/edit",
        name: "products.edit",
        component: ProductEditView,
        meta: { title: "Chỉnh sửa sản phẩm" },
      },
      {
        path: "/products/:id",
        name: "products.detail",
        component: ProductDetailView,
        meta: { title: "Chi tiết sản phẩm" },
        props: true,
      },

      {
        path: "/sizes",
        name: "sizes.list",
        component: SizeListView,
        meta: { title: "Kích thước" },
      },
      {
        path: "/sizes/create",
        name: "sizes.create",
        component: SizeCreateView,
        meta: { title: "Tạo kích thước" },
      },
      {
        path: "/sizes/:id/edit",
        name: "sizes.edit",
        component: SizeEditView,
        meta: { title: "Chỉnh sửa kích thước" },
      },
      {
        path: "/sizes/:id",
        name: "sizes.detail",
        component: SizeDetailView,
        meta: { title: "Chi tiết kích thước" },
        props: true,
      },

      {
        path: "/warehouses",
        name: "warehouses.list",
        component: WarehouseListView,
        meta: { title: "Kho" },
      },
      {
        path: "/warehouses/create",
        name: "warehouses.create",
        component: WarehouseCreateView,
        meta: { title: "Tạo kho" },
      },
      {
        path: "/warehouses/:id/edit",
        name: "warehouses.edit",
        component: WarehouseEditView,
        meta: { title: "Chỉnh sửa kho" },
      },
      {
        path: "/warehouses/:id",
        name: "warehouses.detail",
        component: WarehouseDetailView,
        meta: { title: "Chi tiết kho" },
        props: true,
      },

      {
        path: "/receipts",
        name: "receipts.list",
        component: ReceiptListView,
        meta: { title: "Phiếu nhập" },
      },
      {
        path: "/receipts/create",
        name: "receipts.create",
        component: ReceiptCreateView,
        meta: { title: "Tạo phiếu nhập" },
      },
      {
        path: "/receipts/:id",
        name: "receipts.detail",
        component: ReceiptDetailView,
        meta: { title: "Chi tiết phiếu nhập" },
        props: true,
      },

      {
        path: "/payments",
        name: "payments.list",
        component: PaymentListView,
        meta: { title: "Phương thức thanh toán" },
      },
      {
        path: "/payments/create",
        name: "payments.create",
        component: PaymentCreateView,
        meta: { title: "Tạo phương thức thanh toán" },
      },
      {
        path: "/payments/:id/edit",
        name: "payments.edit",
        component: PaymentEditView,
        meta: { title: "Chỉnh sửa phương thức thanh toán" },
      },
      {
        path: "/payments/:id",
        name: "payments.detail",
        component: PaymentDetailView,
        meta: { title: "Chi tiết phương thức thanh toán" },
        props: true,
      },

      {
        path: "/discounts",
        name: "discounts.list",
        component: DiscountListView,
        meta: { title: "Khuyến mãi" },
      },
      {
        path: "/discounts/create",
        name: "discounts.create",
        component: DiscountCreateView,
        meta: { title: "Tạo khuyến mãi" },
      },
      {
        path: "/discounts/:id/edit",
        name: "discounts.edit",
        component: DiscountEditView,
        meta: { title: "Chỉnh sửa khuyến mãi" },
      },
      {
        path: "/discounts/:id",
        name: "discounts.detail",
        component: DiscountDetailView,
        meta: { title: "Chi tiết khuyến mãi" },
        props: true,
      },

      {
        path: "/users",
        name: "users.list",
        component: UserListView,
        meta: { title: "Tài khoản" },
      },
      {
        path: "/users/:id",
        name: "users.detail",
        component: UserDetailView,
        meta: { title: "Chi tiết tài khoản" },
        props: true,
      },

      {
        path: "/chat",
        name: "chat",
        component: ChatView,
        meta: { title: "Hỗ trợ" },
      },

      {
        path: "/orders",
        name: "orders.list",
        component: OrderListView,
        meta: { title: "Đơn hàng" },
      },
      {
        path: "/orders/:id",
        name: "orders.detail",
        component: OrderDetailView,
        meta: { title: "Chi tiết đơn hàng" },
        props: true,
      },
      {
        path: "/orders/:id/production",
        name: "orders.production",
        component: OrderProductionView,
        meta: { title: "Chế độ xem sản xuất" },
        props: true,
      },
      {
        path: "/stickers",
        name: "stickers.list",
        component: SystemStickerListView,
        meta: { title: "Quản lý sticker" },
      },
      {
        path: "/stickers/create",
        name: "stickers.create",
        component: SystemStickerCreateView,
        meta: { title: "Thêm sticker hệ thống" },
      },
      {
        path: "/stickers/:id",
        name: "stickers.detail",
        component: SystemStickerDetailView,
        meta: { title: "Chi tiết sticker" },
        props: true,
      },
      {
        path: "/stickers/:id/edit",
        name: "stickers.edit",
        component: SystemStickerEditView,
        meta: { title: "Chỉnh sửa sticker hệ thống" },
        props: true,
      },

      {
        path: "/evaluates",
        name: "evaluates.list",
        component: () =>
          import("../views/evaluates/EvaluatePendingListView.vue"),
        meta: { title: "Đánh giá" },
      },
    ],
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to, from, next) => {
  const isLoggin = AuthService.isLoggin();

  if (isLoggin && to.name === "login") return next({ name: "dashboard" });

  if (!isLoggin && to.name !== "login") return next({ name: "login" });

  if (to.meta.requeresAuth && !isLoggin) {
    return next({ name: "login" });
  }

  next();
});

router.afterEach((to) => {
  document.title = to.meta.title || "Quản lý cửa hàng Nón Bảo Hiểm";
});
export default router;
