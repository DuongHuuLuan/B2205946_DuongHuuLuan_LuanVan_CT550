<template>
  <div class="row g-3 g-lg-4">
    <div class="col-12 d-flex align-items-center justify-content-between">
      <div>
        <h4 class="mb-1">Dashboard</h4>
        <div class="small opacity-75">Tổng quan hệ thống</div>
      </div>

      <button class="btn btn-outline-secondary" @click="load" :disabled="loading">
        <i class="bi bi-arrow-clockwise me-1"></i> Refresh
      </button>
    </div>

    <div class="col-12 col-md-6 col-xl-3" v-for="c in cards" :key="c.label">
      <StatCard :label="c.label" :value="loading ? '...' : c.value" :icon="c.icon" />
    </div>

    <div class="col-12 col-xl-7">
      <div class="card card-soft">
        <div class="card-body">
          <div class="d-flex align-items-center justify-content-between mb-2">
            <div class="fw-semibold">Lối tắt quản lý</div>
            <span class="badge bg-secondary-subtle text-secondary">Thêm sau</span>
          </div>

          <div class="row g-2">
            <div class="col-12 col-md-6" v-for="s in shortcuts" :key="s.title">
              <QuickTile :title="s.title" :desc="s.desc" :icon="s.icon" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-12 col-xl-5">
      <div class="card card-soft">
        <div class="card-body">
          <div class="fw-semibold mb-2">Hoạt động gần đây</div>
          <div class="small opacity-75">
            Placeholder để sau đổ data (đơn mới, nhập kho, dealer...)
          </div>

          <hr />
          <ul class="list-unstyled mb-0 small">
            <li class="d-flex justify-content-between py-2">
              <span><i class="bi bi-dot"></i> Placeholder #1</span><span class="opacity-75">--</span>
            </li>
            <li class="d-flex justify-content-between py-2">
              <span><i class="bi bi-dot"></i> Placeholder #2</span><span class="opacity-75">--</span>
            </li>
            <li class="d-flex justify-content-between py-2">
              <span><i class="bi bi-dot"></i> Placeholder #3</span><span class="opacity-75">--</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import StatCard from "../components/dashboard/StatCard.vue";
import QuickTile from "../components/dashboard/QuickTile.vue";

const loading = ref(false);
const summary = ref({
  orders_today: 0,
  revenue_today: 0,
  total_users: 0,
  total_products: 0,
});

const shortcuts = [
  {
    title: "Quản lý sản phẩm",
    desc: "Thêm/sửa/xoá sản phẩm",
    icon: "fa-solid fa-box",
  },
  {
    title: "Quản lý đơn hàng",
    desc: "Xử lý đơn & trạng thái",
    icon: "fa-solid fa-receipt",
  },
  {
    title: "Bảng giá / Tier",
    desc: "Min_qty & effective date",
    icon: "fa-solid fa-tags",
  },
  {
    title: "Dealer",
    desc: "Duyệt dealer & gán tier",
    icon: "fa-solid fa-users",
  },
];
const cards = computed(() => [
  {
    label: "Đơn hôm nay",
    value: summary.value.orders_today,
    icon: "fa-solid fa-receipt",
  },
  {
    label: "Doanh thu hôm nay",
    value: money(summary.value.revenue_today),
    icon: "fa-solid fa-sack-dollar",
  },
  {
    label: "Tổng users",
    value: summary.value.total_users,
    icon: "fa-solid fa-users",
  },
  {
    label: "Tổng sản phẩm",
    value: summary.value.total_products,
    icon: "fa-solid fa-boxes-stacked",
  },
]);

function money(v) {
  return Number(v || 0).toLocaleString("vi-VN") + " ₫";
}

async function load() {
  loading.value = true;
  try {
    // MOCK để UI chạy ngay (bạn thay bằng API sau)
    summary.value = {
      orders_today: 12,
      revenue_today: 1500000,
      total_users: 230,
      total_products: 540,
    };

    // ✅ Khi nối API, bạn thay bằng:
    // const res = await dashboardService.summary();
    // summary.value = { ...summary.value, ...(res.data ?? res) };
  } finally {
    loading.value = false;
  }
}

onMounted(load);
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}
</style>
