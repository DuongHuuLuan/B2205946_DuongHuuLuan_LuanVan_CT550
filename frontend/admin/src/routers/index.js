import { createRouter, createWebHistory } from "vue-router";
import DashboardView from "../views/DashboardView.vue";
import LoginView from "../views/auth/LoginView.vue";
import AppLayout from "../components/layout/AppLayout.vue";

// Category pages
import CategoryListView from "../views/categories/CategoryListView.vue";
import CategoryCreateView from "../views/categories/CategoryCreateView.vue";
import CategoryDetailView from "../views/categories/CategoryDetailView.vue";
import CategoryEditView from "../views/categories/CategoryEditView.vue";

// Supplier pages
import SupplierListView from "../views/suppliers/SupplierListView.vue";
import SupplierCreateView from "../views/suppliers/SupplierCreateView.vue";
import SupplierEditView from "../views/suppliers/SupplierEditView.vue";
import SupplierDetailView from "../views/suppliers/SupplierDetailView.vue";

// Tier pages
import TierListView from "../views/tiers/TierListView.vue";
import TierCreateView from "../views/tiers/TierCreateView.vue";
import TierEditView from "../views/tiers/TierEditView.vue";
import TierDetailView from "../views/tiers/TierDetailView.vue";

// Product pages
import ProductListView from "../views/products/ProductListView.vue";
import ProductCreateView from "../views/products/ProductCreateView.vue";
import ProductEditView from "../views/products/ProductEditView.vue";
import ProductDetailView from "../views/products/ProductDetailView.vue";

// Warehouse pages
import WarehouseListView from "../views/warehouses/WarehouseListView.vue";
import WarehouseCreateView from "../views/warehouses/WarehouseCreateView.vue";
import WarehouseEditView from "../views/warehouses/WarehouseEditView.vue";
import WarehouseDetailView from "../views/warehouses/WarehouseDetailView.vue";

// Receipt pages
import ReceiptListView from "../views/receipts/ReceiptListView.vue";
import ReceiptCreateView from "../views/receipts/ReceiptCreateView.vue";
import ReceiptEditView from "../views/receipts/ReceiptEditView.vue";
import ReceiptDetailView from "../views/receipts/ReceiptDetailView.vue";

// Payment pages
import PaymentListView from "../views/payments/PaymentListView.vue";
import PaymentCreateView from "../views/payments/PaymentCreateView.vue";
import PaymentEditView from "../views/payments/PaymentEditView.vue";
import PaymentDetailView from "../views/payments/PaymentDetailView.vue";

// Discount pages
import DiscountListView from "../views/discounts/DiscountListView.vue";
import DiscountCreateView from "../views/discounts/DiscountCreateView.vue";
import DiscountEditView from "../views/discounts/DiscountEditView.vue";
import DiscountDetailView from "../views/discounts/DiscountDetailView.vue";

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

      // Categories
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

      //   Suppliers
      {
        path: "/suppliers",
        name: "suppliers.list",
        component: SupplierListView,
        meta: {
          title: "Nhà cung cấp",
        },
      },
      {
        path: "/suppliers/create",
        name: "suppliers.create",
        component: SupplierCreateView,
        meta: {
          title: "Tạo nhà cung cấp",
        },
      },
      {
        path: "/suppliers/:id/edit",
        name: "suppliers.edit",
        component: SupplierEditView,
        meta: {
          title: "Chỉnh sửa nhà cung cấp",
        },
        props: true,
      },
      {
        path: "/suppliers/:id",
        name: "suppliers.detail",
        component: SupplierDetailView,
        meta: {
          title: "Chi tiết nhà cung cấp",
        },
        props: true,
      },

      //   Tiers
      {
        path: "/tiers",
        name: "tiers.list",
        component: TierListView,
        meta: { title: "Cấp tài khoản" },
      },
      {
        path: "/tiers/create",
        name: "tiers.create",
        component: TierCreateView,
        meta: { title: "Tạo cấp tài khoản" },
      },
      {
        path: "/tiers/:id/edit",
        name: "tiers.edit",
        component: TierEditView,
        meta: { title: "Chỉnh sửa cấp tài khoản" },
        props: true,
      },
      {
        path: "/tiers/:id",
        name: "tiers.detail",
        component: TierDetailView,
        meta: { title: "Chi tiết cấp tài khoản" },
        props: true,
      },

      // Products
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

      // Warehouses
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

      // Receipts
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
        path: "/receipts/:id/edit",
        name: "receipts.edit",
        component: ReceiptEditView,
        meta: { title: "Chỉnh sửa phiếu nhập" },
      },
      {
        path: "/receipts/:id",
        name: "receipts.detail",
        component: ReceiptDetailView,
        meta: { title: "Chi tiết phiếu nhập" },
        props: true,
      },

      // Payments
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

      // Discounts
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
  document.title = to.meta.title || "Quản lý hệ thống văn phòng phẩm";
});
export default router;