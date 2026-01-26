<template>
    <div class="row g-3">
        <div class="col-12">
            <div
                class="d-flex align-items-start align-items-md-center justify-content-between gap-2 flex-column flex-md-row">
                <div>
                    <h4 class="mb-1">Đơn hàng</h4>
                    <div class="small opacity-75">Quản lý danh sách đơn hàng</div>
                </div>
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
                                <input v-model="keyword" type="text" class="form-control bg-transparent"
                                    placeholder="Tìm theo mã đơn, email, username..." />
                                <button class="btn btn-outline-secondary" @click="keyword = ''" v-if="keyword"
                                    title="Clear">
                                    <i class="fa-solid fa-xmark"></i>
                                </button>
                            </div>
                        </div>

                        <div class="col-12 col-md-6 col-lg-3">
                            <select v-model="status" class="form-select bg-transparent">
                                <option value="">Tất cả trạng thái</option>
                                <option value="pending">Pending</option>
                                <option value="shipping">Shipping</option>
                                <option value="completed">Completed</option>
                                <option value="cancelled">Cancelled</option>
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
                                    <th class="ps-3" style="width: 120px">Mã đơn</th>
                                    <th>Người đặt</th>
                                    <th>Thanh toán</th>
                                    <th style="width: 160px">Trạng thái</th>
                                    <th class="text-end" style="width: 160px">Ngày tạo</th>
                                    <th class="text-end" style="width: 160px">Tổng tiền</th>
                                    <th class="text-end pe-3" style="width: 140px">Thao tác</th>
                                </tr>
                            </thead>

                            <tbody v-if="items.length">
                                <tr v-for="o in items" :key="o.id">
                                    <td class="ps-3">
                                        <span class="code-pill">O{{ o.id }}</span>
                                    </td>

                                    <td>
                                        <RouterLink class="name-link"
                                            :to="{ name: 'orders.detail', params: { id: o.id } }">
                                            <div class="fw-semibold">
                                                {{ o?.user?.username || o?.delivery_info?.name || "-" }}
                                            </div>
                                            <div class="small opacity-75">
                                                {{ o?.user?.email || o?.delivery_info?.phone || "-" }}
                                            </div>
                                        </RouterLink>
                                    </td>

                                    <td>
                                        <span class="opacity-75">
                                            {{ o?.payment_method?.name || "-" }}
                                        </span>
                                    </td>

                                    <td>
                                        <span class="badge" :class="statusTableBadgeClass(o?.status)">
                                            {{ statusLabel(o?.status) }}
                                        </span>
                                    </td>

                                    <td class="text-end">
                                        <span class="small opacity-75">{{ formatDateTimeVN(o?.created_at) }}</span>
                                    </td>

                                    <td class="text-end fw-semibold">
                                        {{ formatMoney(calcTotal(o)) }}
                                    </td>

                                    <td class="text-end pe-3">
                                        <div class="d-flex justify-content-end gap-2">
                                            <RouterLink class="icon-btn icon-view"
                                                :to="{ name: 'orders.detail', params: { id: o.id } }"
                                                title="Xem chi tiết">
                                                <i class="fa-solid fa-eye"></i>
                                            </RouterLink>
                                            <RouterLink class="icon-btn icon-edit"
                                                :to="{ name: 'orders.edit', params: { id: o.id } }"
                                                title="Cập nhật trạng thái">
                                                <i class="fa-solid fa-pen-to-square"></i>
                                            </RouterLink>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>

                            <tbody v-else>
                                <tr>
                                    <td colspan="7" class="text-center py-5">
                                        <div class="opacity-75">
                                            <i class="fa-regular fa-folder-open fs-4 d-block mb-2"></i>
                                            Không có đơn hàng phù hợp.
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="d-flex justify-content-between align-items-center p-3 border-top" v-if="meta.total">
                        <div class="small opacity-75">
                            Hiển thị
                            {{ (meta.current_page - 1) * meta.per_page + 1 }}
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
                            <button class="btn btn-outline-secondary btn-sm"
                                :disabled="meta.current_page >= meta.last_page" @click="page++">
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
import OrderService from "@/services/order.service";
import { formatMoney, statusLabel, statusTableBadgeClass, formatDateTimeVN } from "@/utils/utils";

const keyword = ref("");
const status = ref("");
const page = ref(1);
const perPage = 8;

const items = ref([]);
const meta = ref({ current_page: 1, per_page: perPage, total: 0, last_page: 1 });
const loading = ref(false);

function calcTotal(order) {
    const details = order?.order_details || [];
    return details.reduce((sum, d) => {
        const qty = Number(d?.quantity || 0);
        const price = Number(d?.price || 0);
        return sum + qty * price;
    }, 0);
}

async function fetchOrders() {
    loading.value = true;
    try {
        const res = await OrderService.getAll({
            q: keyword.value.trim() || undefined,
            status: status.value || undefined,
            page: page.value,
            per_page: perPage,
        });

        const list = res.items ?? [];
        items.value = Array.isArray(list) ? list : [];

        meta.value = res.meta ?? {
            current_page: 1,
            per_page: perPage,
            total: 0,
            last_page: 1,
        };
    } catch (e) {
        const msg =
            e?.response?.data?.message ||
            e?.response?.data?.error ||
            "Không thể tải đơn hàng. Vui lòng thử lại!";
        Swal.fire("Lỗi", msg, "error");
    } finally {
        loading.value = false;
    }
}

onMounted(fetchOrders);

watch([keyword, status], async () => {
    page.value = 1;
    await fetchOrders();
});

watch(page, async () => {
    await fetchOrders();
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

.status-pending {
    background: color-mix(in srgb, #f59e0b 18%, transparent);
    border: 1px solid color-mix(in srgb, #f59e0b 45%, transparent);
    color: var(--font-color);
    font-weight: 700;
}

.status-shipping {
    background: color-mix(in srgb, #0ea5e9 18%, transparent);
    border: 1px solid color-mix(in srgb, #0ea5e9 45%, transparent);
    color: var(--font-color);
    font-weight: 700;
}

.status-completed {
    background: color-mix(in srgb, #16a34a 18%, transparent);
    border: 1px solid color-mix(in srgb, #16a34a 45%, transparent);
    color: var(--font-color);
    font-weight: 700;
}

.status-canceled {
    background: color-mix(in srgb, #ef4444 18%, transparent);
    border: 1px solid color-mix(in srgb, #ef4444 45%, transparent);
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

.icon-view {
    color: #0ea5e9;
}

.icon-edit {
    color: #f59e0b;
}
</style>
