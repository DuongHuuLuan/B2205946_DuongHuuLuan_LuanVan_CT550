<template>
  <section class="dashboard">
    <header class="hero">
      <div class="hero-copy">
        <div class="eyebrow">Bảng điều khiển</div>
        <h1>Toàn cảnh vận hành hôm nay</h1>
        <p class="sub">
          Theo dõi nhanh đơn hàng, doanh thu, hàng hóa và các điểm cần xử lý.
        </p>
        <div class="hero-actions">
          <button class="btn-refresh" @click="load" :disabled="loading">
            <i class="bi bi-arrow-clockwise"></i>
            Làm mới
          </button>
          <div class="sync">Cập nhật lúc: {{ lastSync }}</div>
        </div>
      </div>
      <div class="hero-figure">
        <div class="figure-card">
          <div class="figure-label">Doanh thu hôm nay</div>
          <div class="figure-value">
            {{ loading ? "..." : money(summary.revenue_today) }}
          </div>
          <div class="figure-meta">
            Đơn hôm nay: {{ loading ? "..." : summary.orders_today }}
          </div>
        </div>
        <div class="signal">
          <span class="dot"></span>
          <span class="dot"></span>
          <span class="dot"></span>
        </div>
      </div>
    </header>

    <section class="metrics">
      <div class="metric-card" v-for="(c, idx) in cards" :key="c.label" :style="{ '--i': idx }">
        <div class="metric-top">
          <span class="metric-icon"><i :class="c.icon"></i></span>
          <span class="metric-label">{{ c.label }}</span>
        </div>
        <div class="metric-value">{{ loading ? "..." : c.value }}</div>
        <div class="metric-foot">{{ c.caption }}</div>
      </div>
    </section>

    <section class="grid">
      <div class="panel actions">
        <div class="panel-head">
          <div>
            <h3>Luồng xử lý nhanh</h3>
            <p>Truy cập nhanh các khu vực quan trọng.</p>
          </div>
          <span class="panel-tag">Phím tắt</span>
        </div>
        <div class="action-grid">
          <RouterLink v-for="(a, idx) in actions" :key="a.title" :to="a.to" class="action-tile" :style="{ '--i': idx }">
            <div class="action-icon"><i :class="a.icon"></i></div>
            <div class="action-text">
              <div class="action-title">{{ a.title }}</div>
              <div class="action-desc">{{ a.desc }}</div>
            </div>
            <span class="action-arrow"><i class="bi bi-arrow-right"></i></span>
          </RouterLink>
        </div>
      </div>

      <div class="panel activity">
        <div class="panel-head">
          <div>
            <h3>Hoạt động gần đây</h3>
            <p>Thông tin tổng hợp để ưu tiên xử lý.</p>
          </div>
          <span class="panel-tag">Nội bộ</span>
        </div>

        <ul class="activity-list" v-if="activity.length">
          <li v-for="item in activity" :key="item.title" :class="item.tone">
            <div class="activity-main">
              <span class="status"></span>
              <div>
                <div class="activity-title">{{ item.title }}</div>
                <div class="activity-meta">{{ item.meta }}</div>
              </div>
            </div>
            <span class="activity-tag">{{ item.tag }}</span>
          </li>
        </ul>
        <div class="activity-empty" v-else>
          Chưa có hoạt động mới.
        </div>
      </div>
    </section>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import dashboardService from "@/services/dashboard.service";

const loading = ref(false);
const lastSync = ref("--");

const summary = ref({
  orders_today: 0,
  revenue_today: 0,
  total_users: 0,
  total_products: 0,
  low_stock: 0,
});

const actions = [
  {
    title: "Sản phẩm",
    desc: "Thêm/sửa/xóa và quản lý ảnh",
    icon: "bi bi-box-seam",
    to: "/products",
  },
  {
    title: "Phiếu nhập",
    desc: "Nhập kho từ nhà cung cấp",
    icon: "bi bi-truck",
    to: "/receipts",
  },
  {
    title: "Đơn hàng",
    desc: "Cập nhật trạng thái giao",
    icon: "bi bi-receipt",
    to: "/orders",
  },
  {
    title: "Khuyến mãi",
    desc: "Chương trình giảm giá",
    icon: "bi bi-percent",
    to: "/discounts",
  },
  {
    title: "Nhà cung cấp",
    desc: "Danh sách và chỉnh sửa",
    icon: "bi bi-people",
    to: "/distributors",
  },
  {
    title: "Tài khoản",
    desc: "Quản lý người dùng",
    icon: "bi bi-person-badge",
    to: "/users",
  },
];

const activity = ref([]);

const cards = computed(() => [
  {
    label: "Đơn hôm nay",
    value: summary.value.orders_today,
    caption: "Cần xử lý trong ngày",
    icon: "bi bi-receipt",
  },
  {
    label: "Doanh thu",
    value: money(summary.value.revenue_today),
    caption: "Doanh thu tạm tính",
    icon: "bi bi-cash-stack",
  },
  {
    label: "Tài khoản",
    value: summary.value.total_users,
    caption: "Người dùng hệ thống",
    icon: "bi bi-people",
  },
  {
    label: "Sản phẩm",
    value: summary.value.total_products,
    caption: "Tổng sản phẩm đang bán",
    icon: "bi bi-boxes",
  },
]);

const currency = new Intl.NumberFormat("vi-VN");

function money(v) {
  return `${currency.format(Number(v || 0))} ₫`;
}

function updateSync() {
  lastSync.value = new Date().toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

async function load() {
  loading.value = true;
  try {
    const [summaryData, activityData] = await Promise.all([
      dashboardService.summary(),
      dashboardService.activity(),
    ]);
    summary.value = { ...summary.value, ...summaryData };
    activity.value = Array.isArray(activityData)
      ? activityData : [];
    // : activityData?.items || [];
    updateSync();
  } catch (error) {
    console.error("Không thể tải dữ liệu dashboard", error);
  } finally {
    loading.value = false;
  }
}

onMounted(load);
</script>

<style scoped>
@import url("https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&display=swap");

.dashboard {
  position: relative;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  min-height: 100vh;
  color: #2d2a24;
  font-family: "Space Grotesk", "Montserrat", sans-serif;
  background: radial-gradient(circle at 10% 10%, #fff2df 0%, transparent 45%),
    radial-gradient(circle at 90% 20%, #e6f4f3 0%, transparent 40%),
    linear-gradient(180deg, #fff9f1 0%, #f4f2ea 55%, #eef2e7 100%);
}

.dashboard::before {
  content: "";
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 40% 80%, rgba(233, 122, 43, 0.12), transparent 50%);
  pointer-events: none;
}

.hero {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  gap: 1.5rem;
  padding: 1.75rem;
  border-radius: 1.75rem;
  border: 1px solid rgba(224, 206, 182, 0.8);
  background: linear-gradient(135deg, #fff1dc 0%, #f7f5ef 55%, #e6f3ee 100%);
  box-shadow: 0 20px 50px rgba(60, 47, 28, 0.12);
  overflow: hidden;
}

.hero::after {
  content: "";
  position: absolute;
  width: 240px;
  height: 240px;
  border-radius: 999px;
  background: radial-gradient(circle, rgba(22, 124, 128, 0.25) 0%, transparent 70%);
  top: -120px;
  right: -100px;
  animation: float 6s ease-in-out infinite;
}

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  font-weight: 600;
  color: #8b6e4a;
}

.hero h1 {
  margin: 0.4rem 0 0.6rem;
  font-size: clamp(1.7rem, 2.6vw, 2.5rem);
  line-height: 1.15;
}

.sub {
  margin: 0;
  max-width: 520px;
  color: #5d574c;
}

.hero-actions {
  margin-top: 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.btn-refresh {
  border: none;
  background: #167c80;
  color: #fff;
  padding: 0.6rem 1.2rem;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  box-shadow: 0 10px 24px rgba(22, 124, 128, 0.25);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-refresh:not(:disabled):hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 30px rgba(22, 124, 128, 0.32);
}

.sync {
  font-size: 0.9rem;
  color: #6b6458;
}

.hero-figure {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  align-items: flex-end;
  justify-content: center;
}

.figure-card {
  background: #fff;
  padding: 1rem 1.2rem;
  border-radius: 1.25rem;
  border: 1px solid rgba(225, 214, 200, 0.9);
  width: 100%;
  max-width: 260px;
  box-shadow: 0 12px 28px rgba(68, 53, 31, 0.1);
}

.figure-label {
  font-size: 0.85rem;
  color: #7a6a56;
}

.figure-value {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0.4rem 0 0.3rem;
  color: #2e2a22;
}

.figure-meta {
  font-size: 0.85rem;
  color: #5f5a4f;
}

.signal {
  display: flex;
  gap: 0.4rem;
  align-items: center;
}

.signal .dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--status-warning);
  animation: pulse 1.6s ease-in-out infinite;
}

.signal .dot:nth-child(2) {
  animation-delay: 0.2s;
  background: var(--status-info);
}

.signal .dot:nth-child(3) {
  animation-delay: 0.4s;
  background: var(--status-muted);
}

.metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.metric-card {
  background: #fff;
  padding: 1.1rem 1.2rem;
  border-radius: 1.2rem;
  border: 1px solid rgba(226, 214, 199, 0.8);
  box-shadow: 0 10px 24px rgba(72, 54, 32, 0.08);
  display: grid;
  gap: 0.6rem;
  animation: fadeUp 0.5s ease both;
  animation-delay: calc(var(--i) * 0.06s);
}

.metric-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #6c5f4e;
}

.metric-icon {
  width: 40px;
  height: 40px;
  display: grid;
  place-items: center;
  border-radius: 12px;
  background: rgba(233, 122, 43, 0.15);
  color: #b85f26;
}

.metric-value {
  font-size: 1.45rem;
  font-weight: 700;
  color: #2d2a24;
}

.metric-foot {
  font-size: 0.85rem;
  color: #7b7264;
}

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
  gap: 1.5rem;
}

.panel {
  background: #fff;
  border-radius: 1.5rem;
  border: 1px solid rgba(226, 214, 199, 0.9);
  padding: 1.4rem;
  box-shadow: 0 16px 40px rgba(60, 47, 28, 0.08);
}

.panel-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.25rem;
}

.panel-head h3 {
  margin: 0;
  font-size: 1.2rem;
}

.panel-head p {
  margin: 0.35rem 0 0;
  color: #6c6356;
  font-size: 0.9rem;
}

.panel-tag {
  background: rgba(22, 124, 128, 0.12);
  color: #0c4d50;
  padding: 0.35rem 0.7rem;
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.8rem;
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 0.8rem;
}

.action-tile {
  display: flex;
  align-items: center;
  gap: 0.9rem;
  padding: 0.9rem 1rem;
  border-radius: 1rem;
  background: linear-gradient(135deg, rgba(233, 122, 43, 0.1), rgba(22, 124, 128, 0.08));
  border: 1px solid rgba(230, 216, 198, 0.8);
  color: inherit;
  text-decoration: none;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  animation: fadeUp 0.5s ease both;
  animation-delay: calc(var(--i) * 0.05s);
}

.action-tile:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 28px rgba(70, 52, 30, 0.12);
}

.action-icon {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  background: #fff;
  border: 1px solid rgba(224, 206, 182, 0.8);
  color: #167c80;
}

.action-title {
  font-weight: 600;
}

.action-desc {
  font-size: 0.85rem;
  color: #6d6256;
}

.action-arrow {
  margin-left: auto;
  color: #9a8974;
}

.activity-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 0.75rem;
}

.activity-list li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.75rem 0.9rem;
  border-radius: 1rem;
  border: 1px solid rgba(230, 216, 198, 0.7);
  background: #fdfbf7;
}

.activity-main {
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.activity-title {
  font-weight: 600;
}

.activity-meta {
  font-size: 0.82rem;
  color: #6d6256;
}

.activity-tag {
  font-size: 0.75rem;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  background: rgba(233, 122, 43, 0.15);
  color: #9a4f1e;
  font-weight: 600;
}

.activity-list li.good .status {
  background: var(--status-success);
}

.activity-list li.warn .status {
  background: var(--status-warning);
}

.activity-list li.alert .status {
  background: var(--status-danger);
}

.status {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--status-muted);
}

.activity-empty {
  padding: 1.5rem;
  border-radius: 1rem;
  background: #fdfbf7;
  border: 1px dashed rgba(230, 216, 198, 0.8);
  color: #7a6f61;
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(12px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes float {
  0% {
    transform: translateY(0px);
  }

  50% {
    transform: translateY(10px);
  }

  100% {
    transform: translateY(0px);
  }
}

@keyframes pulse {

  0%,
  100% {
    transform: scale(1);
    opacity: 0.7;
  }

  50% {
    transform: scale(1.2);
    opacity: 1;
  }
}

@media (max-width: 992px) {
  .hero {
    grid-template-columns: 1fr;
  }

  .hero-figure {
    align-items: flex-start;
  }

  .grid {
    grid-template-columns: 1fr;
  }
}

@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}
</style>
