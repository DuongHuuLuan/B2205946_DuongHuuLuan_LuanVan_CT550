<template>
  <section class="statistics-page">
    <header class="hero-card">
      <div class="hero-copy">
        <div class="eyebrow">Thống kê</div>
        <h1>Khung phần tích cho quản trị viên</h1>
        <p class="hero-text">
          <!-- Trang nay nen la noi xem doanh thu, don hang, san pham, danh gia va cac canh bao van hanh
          theo tung khoang thoi gian. -->
        </p>

        <div class="hero-actions">
          <button type="button" class="btn-refresh" @click="loadStatistics" :disabled="loading">
            <i class="fa-solid fa-rotate-right"></i>
            {{ loading ? "Đang tải..." : "Làm mới dữ liệu" }}
          </button>

          <button type="button" class="btn-link" @click="handleExportExcel" :disabled="loading">
            <i class="fa-solid fa-file-excel"></i>
            Export Excel
          </button>

          <button type="button" class="btn-link" @click="handleExportPdf" :disabled="loading || exportingPdf">
            <i class="fa-solid fa-file-pdf"></i>
            {{ exportingPdf ? "Đang tạo PDF..." : "Export PDF" }}
          </button>

          <RouterLink class="btn-link" to="/">
            <i class="fa-solid fa-gauge-high"></i>
            Về dashboard
          </RouterLink>
        </div>
      </div>

      <div class="hero-side">
        <div class="hero-side-card">
          <div class="hero-side-label">Bộ lọc đang chọn</div>
          <div class="hero-side-value">{{ selectedRangeLabel }}</div>
          <div class="hero-side-meta">{{ filterSummary }}</div>
        </div>

        <ul class="hero-highlights">
          <li>
            <span class="highlight-key">Lần đồng bộ</span>
            <span class="highlight-value">{{ lastSync }}</span>
          </li>
          <li>
            <span class="highlight-key">Ngày doanh thu cao nhất</span>
            <span class="highlight-value">{{ peakRevenuePoint.label }}</span>
          </li>
          <li>
            <span class="highlight-key">Điểm cần xử lý</span>
            <span class="highlight-value">{{ alerts.length }} mục</span>
          </li>
        </ul>
      </div>
    </header>

    <section class="toolbar-card">
      <div class="toolbar-head">
        <div>
          <h2>Bộ lọc báo cáo</h2>
          <p>{{ scopeDescription }}</p>
        </div>
        <span class="toolbar-chip">{{ scopeChip }}</span>
      </div>

      <div class="filter-grid">
        <label class="filter-field">
          <span>Khoảng thời gian</span>
          <select v-model="filters.range">
            <option v-for="option in rangeOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>

        <label class="filter-field">
          <span>Trạng thái đơn</span>
          <select v-model="filters.orderStatus">
            <option v-for="option in orderStatusOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>

        <label class="filter-field">
          <span>Nhóm báo cáo</span>
          <select v-model="filters.scope">
            <option v-for="option in scopeOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>

      <!-- <div class="toolbar-note">
        <i class="fa-solid fa-circle-info"></i>
        <span>{{ dataModeMessage }}</span>
      </div> -->
    </section>

    <section class="metrics-grid">
      <StatCard v-for="card in statCards" :key="card.label" :label="card.label" :value="card.value" :icon="card.icon" />
    </section>

    <section v-if="showSalesView" class="analysis-grid">
      <article class="panel-card revenue-panel">
        <div class="panel-head">
          <div>
            <h3>Xu hướng doanh thu</h3>
          </div>
          <span class="panel-tag">7 mốc gần nhất</span>
        </div>

        <div v-if="revenueSeries.length" class="chart-shell">
          <div v-for="point in revenueSeries" :key="point.label" class="chart-col">
            <div class="chart-value">{{ compactMoney(point.value) }}</div>
            <div class="chart-track">
              <div class="chart-fill" :style="{ height: `${Math.max((point.value / maxRevenue) * 100, 8)}%` }"></div>
            </div>
            <div class="chart-label">{{ point.label }}</div>
          </div>
        </div>
        <div v-else class="empty-state">Chưa có dữ liệu doanh thu trong kỳ.</div>

        <div class="panel-footnote">
          Định kỳ hiện tại nằm ở <strong>{{ peakRevenuePoint.label }}</strong> với
          <strong>{{ money(peakRevenuePoint.value) }}</strong>.
        </div>
      </article>

      <article class="panel-card">
        <div class="panel-head">
          <div>
            <h3>Cơ cấu đơn hàng</h3>
          </div>
          <span class="panel-tag">Theo trạng thái</span>
        </div>

        <div v-if="orderMix.length" class="mix-list">
          <div v-for="item in orderMix" :key="item.label" class="mix-item">
            <div class="mix-top">
              <div class="mix-title-wrap">
                <span class="mix-dot" :class="`tone-${item.tone}`"></span>
                <span class="mix-title">{{ item.label }}</span>
              </div>
              <div class="mix-values">
                <strong>{{ item.count }}</strong>
                <span>{{ item.share }}%</span>
              </div>
            </div>

            <div class="mix-track">
              <div class="mix-fill" :class="`tone-${item.tone}`" :style="{ width: `${item.share}%` }"></div>
            </div>
          </div>
        </div>
        <div v-else class="empty-state">Chưa có dữ liệu cơ cấu đơn hàng.</div>

        <div class="quick-links">
          <RouterLink class="quick-link" to="/orders">
            <i class="fa-solid fa-receipt"></i>
            Mở danh sách đơn
          </RouterLink>
          <RouterLink class="quick-link" to="/evaluates">
            <i class="fa-solid fa-star-half-stroke"></i>
            Xem đánh giá chờ phản hồi
          </RouterLink>
          <RouterLink class="quick-link" to="/products">
            <i class="fa-solid fa-boxes-stacked"></i>
            Mở danh sách sản phẩm
          </RouterLink>
        </div>
      </article>
    </section>

    <section class="analysis-grid lower-grid" :class="{ 'single-column': !showSalesView }">
      <article v-if="showSalesView" class="panel-card">
        <div class="panel-head">
          <div>
            <h3>Top sản phẩm bán chạy</h3>
          </div>
          <span class="panel-tag">Top 5</span>
        </div>

        <div class="table-wrap">
          <table class="table align-middle mb-0">
            <thead>
              <tr>
                <th>Sản phẩm</th>
                <th>Danh mục</th>
                <th class="text-end">Đã bán</th>
                <th class="text-end">Doanh thu</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in topProducts" :key="item.name">
                <td>
                  <div class="fw-semibold">{{ item.name }}</div>
                  <div class="small opacity-75">{{ item.note }}</div>
                </td>
                <td>{{ item.category }}</td>
                <td class="text-end">{{ item.sold }}</td>
                <td class="text-end fw-semibold">{{ money(item.revenue) }}</td>
              </tr>
              <tr v-if="!topProducts.length">
                <td colspan="4" class="empty-row">Chưa có dữ liệu sản phẩm bán chạy.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </article>

      <article class="panel-card">
        <div class="panel-head">
          <div>
            <h3>Cảnh báo vận hành</h3>
          </div>
          <span class="panel-tag">Hành động</span>
        </div>

        <div v-if="alerts.length" class="alert-list">
          <div v-for="alert in alerts" :key="alert.title" class="alert-item">
            <div class="alert-copy">
              <div class="alert-title">{{ alert.title }}</div>
              <div class="alert-text">{{ alert.text }}</div>
            </div>

            <RouterLink class="alert-link" :to="alert.to">
              {{ alert.action }}
            </RouterLink>
          </div>
        </div>
        <div v-else class="empty-state">Không có cảnh báo nào trong kỳ lọc hiện tại.</div>
      </article>
    </section>

    <section class="analysis-grid lower-grid secondary-grid"
      :class="{ 'single-column': !showSalesView || !showReviewView }">
      <article v-if="showSalesView" class="panel-card">
        <div class="panel-head">
          <div>
            <h3>Phương thức thanh toán</h3>
          </div>
          <span class="panel-tag">Theo số đơn</span>
        </div>

        <div v-if="paymentMix.length" class="mix-list">
          <div v-for="item in paymentMix" :key="item.method" class="mix-item">
            <div class="mix-top">
              <div class="mix-title-wrap">
                <span class="mix-dot" :class="`tone-${item.tone}`"></span>
                <span class="mix-title">{{ item.label }}</span>
              </div>
              <div class="mix-values">
                <strong>{{ item.count }} đơn</strong>
                <span>{{ item.share }}%</span>
              </div>
            </div>

            <div class="mix-track">
              <div class="mix-fill" :class="`tone-${item.tone}`" :style="{ width: `${item.share}%` }"></div>
            </div>

            <div class="payment-meta">{{ money(item.revenue) }}</div>
          </div>
        </div>
        <div v-else class="empty-state">Chưa có dữ liệu phương thức thanh toán.</div>
      </article>

      <article v-if="showReviewView" class="panel-card">
        <div class="panel-head">
          <div>
            <h3>Tổng quan đánh giá</h3>
          </div>
          <span class="panel-tag">1-5 sao</span>
        </div>

        <div class="review-summary">
          <div class="review-score">
            <div class="review-score-value">{{ reviewsSummary.averageRating.toFixed(1) }}</div>
            <div class="review-score-label">Điểm trung bình</div>
          </div>

          <div class="review-meta">
            <div class="review-chip">
              <strong>{{ reviewsSummary.totalReviews }}</strong>
              <span>Đánh giá</span>
            </div>
            <div class="review-chip">
              <strong>{{ reviewsSummary.pendingReplies }}</strong>
              <span>Chờ phản hồi</span>
            </div>
            <div class="review-chip">
              <strong>{{ positiveReviewShare }}%</strong>
              <span>Tỉ lệ 4-5 sao</span>
            </div>
          </div>
        </div>

        <div v-if="reviewsSummary.distribution.length" class="mix-list rating-list">
          <div v-for="item in reviewsSummary.distribution" :key="item.rate" class="mix-item">
            <div class="mix-top">
              <div class="mix-title-wrap">
                <span class="mix-dot" :class="`tone-${item.tone}`"></span>
                <span class="mix-title">{{ item.label }}</span>
              </div>
              <div class="mix-values">
                <strong>{{ item.count }}</strong>
                <span>{{ item.share }}%</span>
              </div>
            </div>

            <div class="mix-track">
              <div class="mix-fill" :class="`tone-${item.tone}`" :style="{ width: `${item.share}%` }"></div>
            </div>
          </div>
        </div>
        <div v-else class="empty-state">Chưa có dữ liệu đánh giá trong kỳ lọc.</div>

        <div class="panel-footnote">
          Đánh giá tích cực 4-5 sao đang chiếm <strong>{{ positiveReviewShare }}%</strong> tổng số đánh giá trong kỳ.
        </div>
      </article>
    </section>

  </section>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue";
import { RouterLink } from "vue-router";
import StatCard from "@/components/dashboard/StatCard.vue";
import statisticsService from "@/services/statistics.service";
import { downloadFileBlob, downloadStatisticsExcel } from "@/utils/statistics-export";

const rangeOptions = [
  { value: "7d", label: "7 ngày gần nhất" },
  { value: "30d", label: "30 ngày gần nhất" },
  { value: "month", label: "Tháng này" },
  { value: "quarter", label: "Quý này" },
];

const orderStatusOptions = [
  { value: "all", label: "Tất cả trạng thái" },
  { value: "pending", label: "Chờ xác nhận" },
  { value: "shipping", label: "Đang giao" },
  { value: "completed", label: "Hoàn tất" },
  { value: "cancelled", label: "Đã hủy" },
];

const scopeOptions = [
  { value: "overview", label: "Tổng quan" },
  { value: "sales", label: "Bán hàng" },
  { value: "reviews", label: "Đánh giá" },
];

const EMPTY_OVERVIEW = Object.freeze({
  revenue: 0,
  orders: 0,
  averageOrderValue: 0,
  completionRate: 0,
  pendingOrders: 0,
  pendingReviews: 0,
});

const EMPTY_REVENUE_SERIES = Object.freeze([]);
const EMPTY_ORDER_MIX = Object.freeze([]);
const EMPTY_PAYMENT_MIX = Object.freeze([]);
const EMPTY_TOP_PRODUCTS = Object.freeze([]);
const EMPTY_REVIEWS_SUMMARY = Object.freeze({
  totalReviews: 0,
  averageRating: 0,
  pendingReplies: 0,
  distribution: [],
});
const EMPTY_ALERTS = Object.freeze([]);

const STATUS_LABELS = Object.freeze({
  pending: "Chờ xác nhận",
  shipping: "Đang giao",
  completed: "Hoàn tất",
  cancelled: "Đã hủy",
});

const filters = ref({
  range: "30d",
  orderStatus: "all",
  scope: "overview",
});

const loading = ref(false);
const exportingPdf = ref(false);
const lastSync = ref("--");
const dataSource = ref("idle");

const overview = ref({ ...EMPTY_OVERVIEW });
const revenueSeries = ref(cloneList(EMPTY_REVENUE_SERIES));
const orderMix = ref(cloneList(EMPTY_ORDER_MIX));
const paymentMix = ref(cloneList(EMPTY_PAYMENT_MIX));
const topProducts = ref(cloneList(EMPTY_TOP_PRODUCTS));
const reviewsSummary = ref(cloneReviewsSummary(EMPTY_REVIEWS_SUMMARY));
const alerts = ref(cloneList(EMPTY_ALERTS));

const currency = new Intl.NumberFormat("vi-VN");

function cloneList(items) {
  return items.map((item) => ({ ...item }));
}

function cloneReviewsSummary(summary) {
  return {
    ...summary,
    distribution: cloneList(summary.distribution || []),
  };
}

function num(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function percent(value, fallback = 0) {
  const parsed = num(value, fallback);
  if (parsed > 0 && parsed <= 1) {
    return Math.round(parsed * 100);
  }
  return Math.round(parsed);
}

function extractItems(payload) {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.items)) return payload.items;
  if (Array.isArray(payload?.data)) return payload.data;
  return [];
}

function buildParams() {
  const params = {
    range: filters.value.range,
    scope: filters.value.scope,
  };

  if (filters.value.orderStatus !== "all") {
    params.order_status = filters.value.orderStatus;
  }

  return params;
}

function normalizeOverview(payload) {
  if (!payload || typeof payload !== "object") {
    return { ...EMPTY_OVERVIEW };
  }

  return {
    revenue: num(payload.revenue ?? payload.total_revenue, EMPTY_OVERVIEW.revenue),
    orders: num(payload.orders ?? payload.total_orders, EMPTY_OVERVIEW.orders),
    averageOrderValue: num(
      payload.average_order_value ?? payload.averageOrderValue ?? payload.aov,
      EMPTY_OVERVIEW.averageOrderValue,
    ),
    completionRate: percent(
      payload.completion_rate ?? payload.completionRate,
      EMPTY_OVERVIEW.completionRate,
    ),
    pendingOrders: num(
      payload.pending_orders ?? payload.pendingOrders,
      EMPTY_OVERVIEW.pendingOrders,
    ),
    pendingReviews: num(
      payload.pending_reviews ?? payload.pendingReviews,
      EMPTY_OVERVIEW.pendingReviews,
    ),
  };
}

function normalizeRevenueSeries(payload) {
  const items = extractItems(payload)
    .map((item, index) => ({
      label: String(item.label ?? item.date ?? item.name ?? `Mốc ${index + 1}`),
      value: num(item.value ?? item.revenue ?? item.amount, 0),
    }))
    .filter((item) => item.label);

  return items;
}

function resolveTone(label, tone) {
  if (tone) return tone;

  const normalized = String(label || "").toLowerCase();
  if (normalized.includes("hủy")) return "danger";
  if (normalized.includes("hoàn tất")) return "success";
  if (normalized.includes("giao")) return "info";
  return "warning";
}

function resolvePaymentTone(label, tone) {
  if (tone) return tone;

  const normalized = String(label || "").toLowerCase();
  if (normalized.includes("vnpay") || normalized.includes("online")) return "info";
  if (normalized.includes("chuyển khoản") || normalized.includes("bank")) return "success";
  if (normalized.includes("vi") || normalized.includes("wallet")) return "success";
  return "warning";
}

function resolveRatingTone(rate, tone) {
  if (tone) return tone;
  if (num(rate, 0) >= 4) return "success";
  if (num(rate, 0) === 3) return "warning";
  return "danger";
}

function normalizeOrderMix(payload) {
  const items = extractItems(payload)
    .map((item) => {
      const rawLabel = item.label ?? STATUS_LABELS[item.status] ?? item.status;
      const count = num(item.count ?? item.total, 0);

      return {
        label: rawLabel || "Khác",
        count,
        share: percent(item.share, 0),
        tone: resolveTone(rawLabel, item.tone),
      };
    })
    .filter((item) => item.count > 0 || item.share > 0);

  const total = items.reduce((sum, item) => sum + item.count, 0) || 1;
  return items.map((item) => ({
    ...item,
    share: item.share > 0 ? item.share : Math.round((item.count / total) * 100),
  }));
}

function normalizePaymentMix(payload) {
  const items = extractItems(payload)
    .map((item, index) => {
      const rawLabel = item.label ?? item.method ?? item.name ?? `Phương thức ${index + 1}`;
      const count = num(item.count ?? item.total, 0);

      return {
        method: String(item.method ?? rawLabel).toLowerCase().replace(/\s+/g, "_"),
        label: String(rawLabel),
        count,
        revenue: num(item.revenue ?? item.total_revenue ?? item.amount, 0),
        share: percent(item.share, 0),
        tone: resolvePaymentTone(rawLabel, item.tone),
      };
    })
    .filter((item) => item.label);

  const total = items.reduce((sum, item) => sum + item.count, 0) || 1;
  return items.map((item) => ({
    ...item,
    share: item.share > 0 ? item.share : Math.round((item.count / total) * 100),
  }));
}

function normalizeTopProducts(payload) {
  const items = extractItems(payload)
    .map((item) => ({
      name: String(item.name ?? item.product_name ?? ""),
      category: String(item.category ?? item.category_name ?? "-"),
      sold: num(item.sold ?? item.quantity_sold ?? item.total_quantity, 0),
      revenue: num(item.revenue ?? item.total_revenue ?? item.amount, 0),
      note: String(item.note ?? item.description ?? ""),
    }))
    .filter((item) => item.name);

  return items;
}

function normalizeReviewsSummary(payload) {
  if (!payload || typeof payload !== "object") {
    return cloneReviewsSummary(EMPTY_REVIEWS_SUMMARY);
  }

  const rawItems = Array.isArray(payload.distribution) ? payload.distribution : extractItems(payload);
  const distribution = rawItems
    .map((item) => {
      const rate = num(item.rate ?? item.star ?? item.value, 0);
      return {
        rate,
        label: `${rate} sao`,
        count: num(item.count ?? item.total, 0),
        share: percent(item.share, 0),
        tone: resolveRatingTone(rate, item.tone),
      };
    })
    .filter((item) => item.rate >= 1 && item.rate <= 5)
    .sort((a, b) => b.rate - a.rate);

  const totalReviews = num(
    payload.total_reviews ?? payload.totalReviews ?? payload.total,
    EMPTY_REVIEWS_SUMMARY.totalReviews,
  );
  const total = distribution.reduce((sum, item) => sum + item.count, 0) || totalReviews || 1;

  return {
    totalReviews,
    averageRating: num(
      payload.average_rating ?? payload.averageRating ?? payload.rating,
      EMPTY_REVIEWS_SUMMARY.averageRating,
    ),
    pendingReplies: num(
      payload.pending_replies ?? payload.pendingReplies,
      EMPTY_REVIEWS_SUMMARY.pendingReplies,
    ),
    distribution: distribution.map((item) => ({
      ...item,
      share: item.share > 0 ? item.share : Math.round((item.count / total) * 100),
    })),
  };
}

function normalizeAlerts(payload) {
  const items = extractItems(payload)
    .map((item) => ({
      title: String(item.title ?? item.name ?? ""),
      text: String(item.text ?? item.description ?? ""),
      action: String(item.action ?? item.cta_label ?? "Xem chi tiết"),
      to: String(item.to ?? item.link ?? "/statistics"),
    }))
    .filter((item) => item.title);

  return items;
}

function money(value) {
  return `${currency.format(Number(value || 0))} VNĐ`;
}

function compactMoney(value) {
  const number = Number(value || 0);
  if (number >= 1000000) {
    return `${(number / 1000000).toFixed(1)}M`;
  }
  return currency.format(number);
}

function updateSync() {
  lastSync.value = new Date().toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

async function loadStatistics() {
  loading.value = true;

  const params = buildParams();
  const requests = [
    ["overview", statisticsService.overview(params)],
    ["revenueSeries", statisticsService.revenueSeries(params)],
    ["alerts", statisticsService.alerts(params)],
  ];

  if (showSalesView.value) {
    requests.push(["orderMix", statisticsService.orderMix(params)]);
    requests.push(["paymentMix", statisticsService.paymentMix(params)]);
    requests.push(["topProducts", statisticsService.topProducts(params)]);
  }

  if (showReviewView.value) {
    requests.push(["reviewsSummary", statisticsService.reviewsSummary(params)]);
  }

  const settled = await Promise.allSettled(requests.map(([, request]) => request));
  const results = new Map(requests.map(([key], index) => [key, settled[index]]));

  let successCount = 0;

  if (results.get("overview")?.status === "fulfilled") {
    overview.value = normalizeOverview(results.get("overview").value);
    successCount += 1;
  } else {
    overview.value = { ...EMPTY_OVERVIEW };
  }

  if (results.get("revenueSeries")?.status === "fulfilled") {
    revenueSeries.value = normalizeRevenueSeries(results.get("revenueSeries").value);
    successCount += 1;
  } else {
    revenueSeries.value = cloneList(EMPTY_REVENUE_SERIES);
  }

  if (showSalesView.value) {
    if (results.get("orderMix")?.status === "fulfilled") {
      orderMix.value = normalizeOrderMix(results.get("orderMix").value);
      successCount += 1;
    } else {
      orderMix.value = cloneList(EMPTY_ORDER_MIX);
    }

    if (results.get("paymentMix")?.status === "fulfilled") {
      paymentMix.value = normalizePaymentMix(results.get("paymentMix").value);
      successCount += 1;
    } else {
      paymentMix.value = cloneList(EMPTY_PAYMENT_MIX);
    }

    if (results.get("topProducts")?.status === "fulfilled") {
      topProducts.value = normalizeTopProducts(results.get("topProducts").value);
      successCount += 1;
    } else {
      topProducts.value = cloneList(EMPTY_TOP_PRODUCTS);
    }
  }

  if (showReviewView.value) {
    if (results.get("reviewsSummary")?.status === "fulfilled") {
      reviewsSummary.value = normalizeReviewsSummary(results.get("reviewsSummary").value);
      successCount += 1;
    } else {
      reviewsSummary.value = cloneReviewsSummary(EMPTY_REVIEWS_SUMMARY);
    }
  }

  if (results.get("alerts")?.status === "fulfilled") {
    alerts.value = normalizeAlerts(results.get("alerts").value);
    successCount += 1;
  } else {
    alerts.value = cloneList(EMPTY_ALERTS);
  }

  if (successCount === settled.length) {
    dataSource.value = "api";
  } else if (successCount > 0) {
    dataSource.value = "partial";
    console.warn("Statistics page could only load part of the API data.");
  } else {
    dataSource.value = "unavailable";
    console.warn("Statistics page could not load statistics endpoints.");
  }

  updateSync();
  loading.value = false;
}

const selectedRangeLabel = computed(
  () => rangeOptions.find((item) => item.value === filters.value.range)?.label || "30 ngày gần nhất",
);

const filterSummary = computed(() => {
  const status =
    orderStatusOptions.find((item) => item.value === filters.value.orderStatus)?.label ||
    "Tất cả trạng thái";
  const scope =
    scopeOptions.find((item) => item.value === filters.value.scope)?.label || "Tổng quan";

  return `Đang xem ${scope.toLowerCase()} trong ${selectedRangeLabel.value.toLowerCase()}, lọc ${status.toLowerCase()}.`;
});

const dataSourceLabel = computed(() => {
  if (loading.value) return "Đang đồng bộ dữ liệu";
  if (dataSource.value === "api") return "Nguồn dữ liệu: API";
  if (dataSource.value === "partial") return "Nguồn dữ liệu: API một phần";
  if (dataSource.value === "unavailable") return "Nguồn dữ liệu: chưa tải được";
  return "Nguồn dữ liệu: Đang chờ tải";
});

const dataModeMessage = computed(() => {
  if (loading.value) {
    return `Đang tải thống kê. ${filterSummary.value}`;
  }

  if (dataSource.value === "api") {
    return `${filterSummary.value} Các widget chính đang đọc từ API.`;
  }

  if (dataSource.value === "partial") {
    return `${filterSummary.value} Một số widget chưa tải được từ API, trang đang hiển thị dữ liệu rỗng cho các khối bị lỗi.`;
  }

  return `${filterSummary.value} Chưa tải được dữ liệu từ API. Trang không còn dùng dữ liệu mẫu.`;
});

const statCards = computed(() =>
  filters.value.scope === "reviews"
    ? [
      {
        label: "Tổng đánh giá",
        value: reviewsSummary.value.totalReviews,
        icon: "fa-solid fa-comments",
      },
      {
        label: "Điểm trung bình",
        value: reviewsSummary.value.averageRating.toFixed(1),
        icon: "fa-solid fa-star",
      },
      {
        label: "Chờ phản hồi",
        value: reviewsSummary.value.pendingReplies,
        icon: "fa-solid fa-message",
      },
      {
        label: "Tỉ lệ 4-5 sao",
        value: `${positiveReviewShare.value}%`,
        icon: "fa-solid fa-thumbs-up",
      },
      {
        label: "Đánh giá 1-2 sao",
        value: lowRatingCount.value,
        icon: "fa-solid fa-triangle-exclamation",
      },
    ]
    : filters.value.scope === "sales"
      ? [
        {
          label: "Doanh thu",
          value: money(overview.value.revenue),
          icon: "fa-solid fa-sack-dollar",
        },
        {
          label: "Đơn hàng",
          value: overview.value.orders,
          icon: "fa-solid fa-cart-shopping",
        },
        {
          label: "Giá trị đơn trung bình",
          value: money(overview.value.averageOrderValue),
          icon: "fa-solid fa-money-bill-trend-up",
        },
        {
          label: "Tỉ lệ hoàn tất",
          value: `${overview.value.completionRate}%`,
          icon: "fa-solid fa-circle-check",
        },
        {
          label: "Đơn chờ xác nhận",
          value: overview.value.pendingOrders,
          icon: "fa-solid fa-hourglass-half",
        },
        {
          label: "Phương thức thanh toán chính",
          value: `${topPaymentMethod.value.label} ${topPaymentMethod.value.share}%`,
          icon: "fa-solid fa-credit-card",
        },
      ]
      : [
        {
          label: "Doanh thu",
          value: money(overview.value.revenue),
          icon: "fa-solid fa-sack-dollar",
        },
        {
          label: "Đơn hàng",
          value: overview.value.orders,
          icon: "fa-solid fa-cart-shopping",
        },
        {
          label: "Giá trị đơn TB",
          value: money(overview.value.averageOrderValue),
          icon: "fa-solid fa-money-bill-trend-up",
        },
        {
          label: "Tỉ lệ hoàn tất",
          value: `${overview.value.completionRate}%`,
          icon: "fa-solid fa-circle-check",
        },
        {
          label: "Đơn chờ xác nhận",
          value: overview.value.pendingOrders,
          icon: "fa-solid fa-hourglass-half",
        },
        {
          label: "Đánh giá chờ phản hồi",
          value: overview.value.pendingReviews,
          icon: "fa-solid fa-message",
        },
      ]);
const maxRevenue = computed(() => Math.max(...revenueSeries.value.map((item) => item.value), 1));

const peakRevenuePoint = computed(() =>
  revenueSeries.value.reduce(
    (peak, item) => (item.value > peak.value ? item : peak),
    revenueSeries.value[0] || { label: "--", value: 0 },
  ),
);

const positiveReviewShare = computed(() => {
  const total = reviewsSummary.value.distribution.reduce((sum, item) => sum + item.count, 0) || 1;
  const positive = reviewsSummary.value.distribution
    .filter((item) => item.rate >= 4)
    .reduce((sum, item) => sum + item.count, 0);
  return Math.round((positive / total) * 100);
});

const lowRatingCount = computed(() =>
  reviewsSummary.value.distribution
    .filter((item) => item.rate <= 2)
    .reduce((sum, item) => sum + item.count, 0),
);

const topPaymentMethod = computed(() => paymentMix.value[0] || { label: "--", share: 0 });

const showSalesView = computed(() => filters.value.scope !== "reviews");
const showReviewView = computed(() => filters.value.scope !== "sales");

const scopeChip = computed(() => {
  if (filters.value.scope === "sales") return "Bán hàng";
  if (filters.value.scope === "reviews") return "Đánh giá";
  return "Tổng quan";
});

const activeScopeLabel = computed(
  () => scopeOptions.find((item) => item.value === filters.value.scope)?.label || "Tổng quan",
);

const scopeDescription = computed(() => {
  if (filters.value.scope === "sales") {
    return "Tập trung vào doanh thu, đơn hàng, phương thức thanh toán và nhóm sản phẩm bán chạy trong kỳ.";
  }
  if (filters.value.scope === "reviews") {
    return "Tập trung vào điểm đánh giá, phân bố số sao và các phản hồi còn chờ xử lý.";
  }
  return "Kết hợp số liệu bán hàng và đánh giá để theo dõi nhanh tình hình vận hành trong kỳ đã chọn.";
});

function buildExportSections() {
  const sections = [
    {
      title: "KPI tổng quan",
      columns: ["Chỉ số", "Giá trị"],
      rows: statCards.value.map((card) => [card.label, String(card.value)]),
    },
  ];

  if (showSalesView.value) {
    sections.push({
      title: "Xu hướng doanh thu",
      columns: ["Mốc", "Doanh thu"],
      rows: revenueSeries.value.map((item) => [item.label, money(item.value)]),
    });

    sections.push({
      title: "Cơ cấu đơn hàng",
      columns: ["Trạng thái", "Số đơn", "Tỉ lệ"],
      rows: orderMix.value.map((item) => [item.label, String(item.count), `${item.share}%`]),
    });
    sections.push({
      title: "Top sản phẩm bán chạy",
      columns: ["Sản phẩm", "Danh muc", "Đã bán", "Doanh thu", "Ghi chú"],
      rows: topProducts.value.map((item) => [
        item.name,
        item.category,
        String(item.sold),
        money(item.revenue),
        item.note || "-",
      ]),
    });
    sections.push({
      title: "Phương thức thanh toán",
      columns: ["Phương thức", "Số đơn", "Tỉ lệ", "Doanh thu"],
      rows: paymentMix.value.map((item) => [
        item.label,
        String(item.count),
        `${item.share}%`,
        money(item.revenue),
      ]),
    });
  }

  if (showReviewView.value) {
    sections.push({
      title: "Tổng quan đánh giá",
      columns: ["Chỉ số", "Giá trị"],
      rows: [
        ["Tổng đánh giá", String(reviewsSummary.value.totalReviews)],
        ["Điểm trung bình", reviewsSummary.value.averageRating.toFixed(1)],
        ["Chờ phản hồi", String(reviewsSummary.value.pendingReplies)],
        ["Tỉ lệ 4-5 sao", `${positiveReviewShare.value}%`],
        ["Đánh giá 1-2 sao", String(lowRatingCount.value)],
      ],
    });

    sections.push({
      title: "Phân bố 1-5 sao",
      columns: ["Mức sao", "Số lượng", "Tỉ lệ"],
      rows: reviewsSummary.value.distribution.map((item) => [
        item.label,
        String(item.count),
        `${item.share}%`,
      ]),
    });
  }

  sections.push({
    title: "Cảnh báo vận hàng",
    columns: ["Tiêu đề", "Mô tả", "Hành động"],
    rows: alerts.value.map((item) => [item.title, item.text, item.action]),
  });

  return sections;
}

function buildExportSnapshot() {
  return {
    title: "Báo cáo thống kê",
    subtitle: filterSummary.value,
    scopeLabel: activeScopeLabel.value,
    rangeLabel: selectedRangeLabel.value,
    generatedAt: new Date().toLocaleString("vi-VN"),
    dataSourceLabel: dataSourceLabel.value,
    sections: buildExportSections(),
  };
}

function makeExportFilename(extension) {
  const timestamp = new Date().toISOString().slice(0, 16).replace(/[:T]/g, "-");
  return `statistics-${filters.value.scope}-${timestamp}.${extension}`;
}

function handleExportExcel() {
  downloadStatisticsExcel(buildExportSnapshot(), makeExportFilename("xls"));
}

async function handleExportPdf() {
  exportingPdf.value = true;

  try {
    const result = await statisticsService.exportPdf(buildParams());
    downloadFileBlob(result.blob, result.filename || makeExportFilename("pdf"));
  } catch (_error) {
    window.alert("Không thể tạo file PDF từ backend. Hãy kiểm tra API statistics export.");
  } finally {
    exportingPdf.value = false;
  }
}

watch(filters, () => {
  void loadStatistics();
}, { deep: true });

onMounted(() => {
  void loadStatistics();
});
</script>

<style scoped>
.statistics-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.hero-card,
.toolbar-card,
.panel-card {
  position: relative;
  overflow: hidden;
  background: linear-gradient(180deg, var(--main-extra-bg) 0%, color-mix(in srgb, var(--main-extra-bg) 88%, var(--extra-bg)) 100%);
  border: 1px solid var(--border-color);
  border-radius: 1.4rem;
  box-shadow: 0 18px 38px var(--shadow-color);
}

.hero-card {
  display: grid;
  grid-template-columns: minmax(0, 1.8fr) minmax(280px, 1fr);
  gap: 1.5rem;
  padding: 1.75rem;
  background:
    radial-gradient(circle at top left, color-mix(in srgb, var(--main-color) 18%, transparent), transparent 42%),
    radial-gradient(circle at bottom right, color-mix(in srgb, #4fd1c5 16%, transparent), transparent 40%),
    linear-gradient(135deg, color-mix(in srgb, var(--main-extra-bg) 90%, #fff7ed) 0%, var(--main-extra-bg) 100%);
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.35rem 0.7rem;
  margin-bottom: 0.9rem;
  border-radius: 999px;
  background: color-mix(in srgb, var(--main-color) 12%, transparent);
  color: var(--font-extra-color);
  font-size: 0.82rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.hero-copy h1,
.toolbar-head h2,
.panel-head h3 {
  margin: 0;
  color: var(--font-color);
}

.hero-copy h1 {
  font-size: clamp(1.8rem, 2.8vw, 2.6rem);
  line-height: 1.08;
  letter-spacing: -0.04em;
}

.hero-text,
.toolbar-head p,
.panel-head p,
.panel-footnote,
.alert-text {
  margin: 0;
  color: var(--font-extra-color);
}

.hero-text {
  margin-top: 0.9rem;
  max-width: 52rem;
  font-size: 1rem;
  line-height: 1.7;
}

.hero-actions,
.quick-links {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.hero-actions {
  margin-top: 1.25rem;
}

.btn-refresh,
.btn-link,
.quick-link,
.alert-link {
  display: inline-flex;
  /* Quan trọng: align-items center để icon và chữ luôn thẳng hàng */
  align-items: center;
  justify-content: center;

  /* Khoảng cách giữa icon và chữ */
  gap: 0.5rem;

  /* Ép chữ trên 1 dòng duy nhất, không bao giờ cho phép xuống hàng */
  white-space: nowrap;

  /* Đảm bảo nút không bị co lại khi nằm trong flexbox cha */
  flex-shrink: 0;

  /* Dùng padding thay vì cố định min-height giúp nút co giãn theo chữ */
  padding: 0.6rem 1.2rem;

  /* Nếu bạn bắt buộc phải giữ chiều cao tối thiểu */
  min-height: 2.8rem;

  /* Reset các thuộc tính khác */
  text-decoration: none;
  font-weight: 700;
  border-radius: 0.95rem;
  transition: all 0.2s ease;

  /* Thêm dòng này nếu nút nằm trong thẻ <a> hoặc <button> */
  box-sizing: border-box;
}


.btn-refresh {
  background: var(--font-color);
  color: #fff;
}

.btn-refresh:hover {
  filter: brightness(1.05);
}

.btn-link,
.quick-link,
.alert-link {
  background: color-mix(in srgb, var(--main-color) 10%, transparent);
  color: var(--font-color);
  border-color: color-mix(in srgb, var(--main-color) 25%, var(--border-color));
}

.btn-link:hover,
.quick-link:hover,
.alert-link:hover {
  background: color-mix(in srgb, var(--main-color) 16%, transparent);
}

.toolbar-chip,
.panel-tag {
  display: inline-flex;
  align-items: center;
  min-height: 2rem;
  padding: 0.35rem 0.75rem;
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 700;
}

.panel-tag {
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid color-mix(in srgb, var(--border-color) 70%, transparent);
  color: var(--font-extra-color);
}

.toolbar-chip {
  background: color-mix(in srgb, var(--main-color) 12%, transparent);
}

.hero-side {
  display: grid;
  gap: 1rem;
}

.hero-side-card,
.alert-item {
  border-radius: 1.15rem;
  border: 1px solid color-mix(in srgb, var(--border-color) 80%, transparent);
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: blur(8px);
}

.hero-side-card {
  padding: 1.2rem;
}

.hero-side-label,
.highlight-key,
.chart-label,
.chart-value,
.mix-title,
.toolbar-note,
.filter-field span {
  color: var(--font-extra-color);
}

.hero-side-value {
  margin-top: 0.35rem;
  font-size: 1.7rem;
  font-weight: 800;
  color: var(--font-color);
}

.hero-side-meta {
  margin-top: 0.45rem;
  color: var(--font-extra-color);
  line-height: 1.6;
}

.hero-highlights {
  display: grid;
  gap: 0.75rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.hero-highlights li {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.95rem 1rem;
  border-radius: 1rem;
  border: 1px solid color-mix(in srgb, var(--border-color) 80%, transparent);
  background: color-mix(in srgb, var(--main-extra-bg) 82%, var(--extra-bg));
}

.highlight-value {
  color: var(--font-color);
  font-weight: 700;
  text-align: right;
}

.toolbar-card,
.panel-card {
  padding: 1.25rem;
}

.toolbar-head,
.panel-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.85rem;
  margin-top: 1.1rem;
}

.filter-field {
  display: grid;
  gap: 0.45rem;
}

.filter-field span {
  font-size: 0.9rem;
  font-weight: 700;
}

.filter-field select {
  min-height: 3rem;
  padding: 0.75rem 0.95rem;
  border-radius: 0.95rem;
  border: 1px solid var(--border-color);
  background: var(--main-extra-bg);
  color: var(--font-color);
  outline: none;
}

.toolbar-note {
  display: inline-flex;
  align-items: flex-start;
  gap: 0.55rem;
  margin-top: 1rem;
  padding: 0.85rem 1rem;
  border-radius: 1rem;
  background: color-mix(in srgb, var(--main-color) 10%, transparent);
  line-height: 1.6;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: 1rem;
}

.analysis-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(320px, 1fr);
  gap: 1rem;
}

.lower-grid {
  grid-template-columns: minmax(0, 1.25fr) minmax(320px, 0.95fr);
}

.single-column {
  grid-template-columns: 1fr;
}

.secondary-grid {
  align-items: start;
}

.chart-shell {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 0.8rem;
  align-items: end;
  margin-top: 1.2rem;
}

.chart-col {
  display: grid;
  gap: 0.6rem;
}

.chart-value,
.chart-label {
  text-align: center;
  font-size: 0.82rem;
  font-weight: 700;
}

.chart-track {
  display: flex;
  align-items: end;
  justify-content: center;
  height: 230px;
  padding: 0.4rem;
  border-radius: 999px;
  background: linear-gradient(180deg, color-mix(in srgb, var(--main-color) 8%, transparent), transparent 70%);
}

.chart-fill {
  width: 100%;
  border-radius: 999px;
  background: linear-gradient(180deg, color-mix(in srgb, #4fd1c5 74%, white), color-mix(in srgb, var(--main-color) 70%, #f59e0b));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.35);
}

.panel-footnote {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid color-mix(in srgb, var(--border-color) 70%, transparent);
}

.empty-state,
.empty-row {
  padding: 1rem;
  border-radius: 1rem;
  color: var(--font-extra-color);
  background: color-mix(in srgb, var(--main-color) 6%, transparent);
}

.empty-row {
  text-align: center;
}

.mix-list {
  display: grid;
  gap: 0.9rem;
  margin-top: 1.2rem;
}

.mix-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.mix-title-wrap,
.mix-values {
  display: flex;
  align-items: center;
  gap: 0.55rem;
}

.mix-title {
  font-weight: 700;
}

.mix-values {
  color: var(--font-extra-color);
}

.mix-track {
  height: 0.7rem;
  margin-top: 0.45rem;
  border-radius: 999px;
  background: color-mix(in srgb, var(--border-color) 55%, transparent);
  overflow: hidden;
}

.mix-fill,
.mix-dot {
  transition: 0.2s ease;
}

.mix-fill {
  display: block;
  height: 100%;
  border-radius: inherit;
}

.mix-dot {
  width: 0.72rem;
  height: 0.72rem;
  border-radius: 999px;
}

.tone-warning {
  background: #f59e0b;
}

.tone-info {
  background: #0ea5e9;
}

.tone-success {
  background: #10b981;
}

.tone-danger {
  background: #ef4444;
}

.quick-links {
  margin-top: 1.25rem;
}

.payment-meta {
  margin-top: 0.55rem;
  color: var(--font-extra-color);
  font-size: 0.9rem;
  font-weight: 700;
}

.table-wrap {
  margin-top: 1.2rem;
  border: 1px solid color-mix(in srgb, var(--border-color) 80%, transparent);
  border-radius: 1rem;
  overflow: hidden;
}

.review-summary {
  display: grid;
  grid-template-columns: minmax(120px, auto) 1fr;
  gap: 1rem;
  margin-top: 1.2rem;
  padding: 1rem;
  border: 1px solid color-mix(in srgb, var(--border-color) 78%, transparent);
  border-radius: 1rem;
  background: color-mix(in srgb, var(--main-color) 6%, transparent);
}

.review-score {
  display: grid;
  place-items: center;
  align-content: center;
  padding: 1rem;
  border-radius: 1rem;
  background: linear-gradient(180deg, color-mix(in srgb, var(--main-color) 14%, transparent), transparent);
}

.review-score-value {
  font-size: clamp(2rem, 5vw, 3rem);
  font-weight: 800;
  line-height: 1.2;
  color: var(--font-color);
  white-space: nowrap;
  display: block;
}

.review-score-label {
  margin-top: 0.45rem;
  color: var(--font-extra-color);
  font-weight: 700;
}

.review-meta {
  display: flex;
  gap: 0.75rem;
}

.review-chip {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.2rem;
  padding: 0.8rem 0.5rem;
  border-radius: 1rem;
  background: var(--main-extra-bg);
  border: 1px solid color-mix(in srgb, var(--border-color) 75%, transparent);
  text-align: center;
  min-width: fit-content;
}

.review-chip strong {
  font-size: 1.25rem;
  line-height: 1;
}

.review-chip span {
  font-size: 0.85rem;
  /* Giảm nhẹ size chữ nhãn */
  white-space: nowrap;
  /* QUAN TRỌNG: Ép chữ luôn nằm trên 1 hàng */
  color: var(--font-extra-color);
  font-weight: 500;
}

/* Tùy chỉnh thêm cho phần Score bên trái để cân đối */
.review-score-label {
  white-space: nowrap;
  /* Tránh chữ "Điểm trung bình" bị xuống hàng */
  font-size: 0.9rem;
}

.rating-list {
  margin-top: 1rem;
}

.alert-list {
  display: grid;
  gap: 0.9rem;
  margin-top: 1.2rem;
}

.alert-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
}

.alert-copy {
  display: grid;
  gap: 0.35rem;
}

.alert-title {
  color: var(--font-color);
  font-weight: 800;
}

@media (max-width: 1399.98px) {
  .metrics-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 1199.98px) {

  .hero-card,
  .analysis-grid,
  .lower-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 991.98px) {

  .filter-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .review-summary,
  .review-meta {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 767.98px) {
  .statistics-page {
    gap: 1rem;
  }

  .hero-card,
  .toolbar-card,
  .panel-card {
    padding: 1rem;
    border-radius: 1.15rem;
  }

  .filter-grid,
  .metrics-grid,
  .chart-shell {
    grid-template-columns: 1fr;
  }

  .chart-track {
    height: 120px;
  }

  .toolbar-head,
  .panel-head,
  .alert-item {
    flex-direction: column;
  }

  .hero-highlights li,
  .mix-top {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
