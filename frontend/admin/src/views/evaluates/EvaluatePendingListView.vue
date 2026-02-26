<template>
    <div class="row g-3">
        <div class="col-12 d-flex justify-content-between align-items-center">
            <div>
                <h4 class="mb-1">Đánh giá sản phẩm</h4>
                <div class="small opacity-75">Danh sách đánh giá chưa phản hồi</div>
            </div>
            <button class="btn btn-outline-secondary btn-sm" @click="fetchItems" :disabled="loading">
                <i class="fa-solid fa-rotate-right"></i> Làm mới
            </button>
        </div>

        <div class="col-12">
            <div class="card card-soft">
                <div class="card-body">
                    <div class="row g-2">
                        <div class="col-12 col-md-3">
                            <input v-model.number="filters.order_id" type="number" min="1" class="form-control"
                                placeholder="Lọc theo mã đơn" />
                        </div>
                        <div class="col-12 col-md-3">
                            <select v-model="replyMode" class="form-select">
                                <option value="pending">Chưa phản hồi</option>
                                <option value="all">Tất cả</option>
                                <option value="replied">Đã phản hồi</option>
                            </select>
                        </div>
                        <div class="col-12 col-md-3">
                            <button class="btn btn-primary w-100" @click="applyFilters" :disabled="loading">
                                Lọc
                            </button>
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
                                    <th class="ps-3">Mã ĐG</th>
                                    <th>Đơn hàng</th>
                                    <th>Số sao</th>
                                    <th>Nội dung</th>
                                    <th>Ảnh</th>
                                    <th>Ngày tạo</th>
                                    <th class="text-end pe-3">Thao tác</th>
                                </tr>
                            </thead>
                            <tbody v-if="items.length">
                                <tr v-for="r in items" :key="r.id">
                                    <td class="ps-3 fw-semibold">#RV-{{ r.id }}</td>
                                    <td>#DH-{{ r.order_id }}</td>
                                    <td>
                                        <span class="badge bg-warning-subtle text-warning-emphasis">
                                            {{ r.rate }}/5
                                        </span>
                                    </td>
                                    <td style="max-width: 320px">
                                        <div class="text-truncate">{{ r.content || "(Không có nội dung)" }}</div>
                                        <div v-if="r.admin_reply" class="small text-success mt-1">
                                            Đã phản hồi
                                        </div>
                                    </td>
                                    <td>
                                        <div class="d-flex gap-1 flex-wrap">
                                            <img v-for="img in (r.images || []).slice(0, 3)" :key="img.id"
                                                :src="resolveUrl(img.image_url)" alt="evaluate-image"
                                                style="width: 34px; height: 34px; object-fit: cover; border-radius: 6px;" />
                                            <span v-if="(r.images || []).length > 3" class="small opacity-75">
                                                +{{ (r.images || []).length - 3 }}
                                            </span>
                                        </div>
                                    </td>
                                    <td class="small opacity-75">{{ formatDate(r.created_at) }}</td>
                                    <td class="text-end pe-3">
                                        <button class="btn btn-sm btn-outline-primary" @click="openReply(r.id)">
                                            {{ r.admin_reply ? "Xem/Sửa phản hồi" : "Phản hồi" }}
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                            <tbody v-else>
                                <tr>
                                    <td colspan="7" class="text-center py-5 opacity-75">
                                        Không có đánh giá phù hợp.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="d-flex justify-content-between align-items-center p-3 border-top" v-if="meta.total">
                        <div class="small opacity-75">
                            {{ meta.total }} đánh giá
                        </div>
                        <div class="btn-group">
                            <button class="btn btn-outline-secondary btn-sm" :disabled="page === 1"
                                @click="page--; fetchItems()">
                                <i class="fa-solid fa-chevron-left"></i>
                            </button>
                            <button class="btn btn-outline-secondary btn-sm" disabled>
                                Trang {{ meta.page }} / {{ meta.total_pages || 1 }}
                            </button>
                            <button class="btn btn-outline-secondary btn-sm"
                                :disabled="meta.total_pages === 0 || page >= meta.total_pages"
                                @click="page++; fetchItems()">
                                <i class="fa-solid fa-chevron-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div v-if="replyDialog.open" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,.35)"
            @click.self="closeReply">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Phản hồi đánh giá #RV-{{ replyDialog.item?.id }}</h5>
                        <button type="button" class="btn-close" @click="closeReply"></button>
                    </div>
                    <div class="modal-body">
                        <div v-if="replyDialog.loadingDetail" class="py-4 text-center opacity-75">
                            <i class="fa-solid fa-spinner fa-spin me-2"></i>
                            Đang tải chi tiết...
                        </div>
                        <div v-else class="evaluate-reply-body">
                            <div class="mb-2">
                                <div class="small opacity-75">Đơn hàng</div>
                                <div>#DH-{{ replyDialog.item?.order_id }}</div>
                            </div>
                            <div class="mb-2">
                                <div class="small opacity-75">Nội dung khách hàng</div>
                                <div>{{ replyDialog.item?.content || "(Không có nội dung)" }}</div>
                            </div>
                            <div class="mb-3">
                                <div class="small opacity-75">Ảnh</div>
                                <div class="d-flex gap-2 flex-wrap">
                                    <img v-for="img in (replyDialog.item?.images || [])" :key="img.id"
                                        :src="resolveUrl(img.image_url)"
                                        style="width: 72px; height: 72px; object-fit: cover; border-radius: 8px" />
                                </div>
                            </div>
                            <label class="form-label fw-semibold">Nội dung phản hồi</label>
                            <textarea v-model="replyDialog.reply" rows="4" class="form-control"
                                :disabled="replyDialog.loadingDetail || replyDialog.submitting"
                                placeholder="Nhập phản hồi cho khách hàng..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" @click="closeReply"
                            :disabled="replyDialog.submitting">
                            Đóng
                        </button>
                        <button class="btn btn-primary" @click="submitReply"
                            :disabled="replyDialog.submitting || replyDialog.loadingDetail">
                            {{ replyDialog.submitting ? "Đang gửi..." : "Gửi phản hồi" }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import Swal from "sweetalert2";
import EvaluateService from "@/services/evaluate.service";

const page = ref(1);
const perPage = 10;
const loading = ref(false);

const items = ref([]);
const meta = ref({ page: 1, per_page: perPage, total: 0, total_pages: 0 });

const replyMode = ref("pending");
const filters = ref({ order_id: null });

const replyDialog = ref({
    open: false,
    item: null,
    reply: "",
    submitting: false,
    loadingDetail: false,
});

function resolveUrl(url) {
    if (!url) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    const base = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, "") || "";
    return `${base}${url.startsWith("/") ? "" : "/"}${url}`;
}

function formatDate(value) {
    if (!value) return "--";
    try {
        return new Date(value).toLocaleString("vi-VN");
    } catch {
        return value;
    }
}

function buildQuery() {
    const params = {
        page: page.value,
        per_page: perPage,
    };

    if (filters.value.order_id) params.order_id = filters.value.order_id;
    if (replyMode.value === "pending") params.has_reply = false;
    if (replyMode.value === "replied") params.has_reply = true;

    return params;
}

async function fetchItems() {
    loading.value = true;
    try {
        const res = await EvaluateService.getAdminList(buildQuery());
        items.value = Array.isArray(res?.items) ? res.items : [];
        meta.value = res?.meta ?? { page: 1, per_page: perPage, total: 0, total_pages: 0 };
    } catch (e) {
        const msg = e?.response?.data?.detail || "Không thể tải danh sách đánh giá.";
        Swal.fire("Lỗi", msg, "error");
    } finally {
        loading.value = false;
    }
}

function applyFilters() {
    page.value = 1;
    fetchItems();
}

async function openReply(id) {
    replyDialog.value = {
        open: true,
        item: null,
        reply: "",
        submitting: false,
        loadingDetail: true,
    };
    try {
        const detail = await EvaluateService.getById(id);
        if (!replyDialog.value.open) return;
        replyDialog.value.item = detail;
        replyDialog.value.reply = detail?.admin_reply || "";
    } catch (e) {
        const msg = e?.response?.data?.detail || "Không thể tải chi tiết đánh giá.";
        Swal.fire("Lỗi", msg, "error");
        closeReply();
    } finally {
        if (replyDialog.value.open) {
            replyDialog.value.loadingDetail = false;
        }
    }
}

function closeReply() {
    replyDialog.value = {
        open: false,
        item: null,
        reply: "",
        submitting: false,
        loadingDetail: false,
    };
}

async function submitReply() {
    const current = replyDialog.value;
    if (!current.item || current.loadingDetail) return;
    const reply = (current.reply || "").trim();
    if (!reply) {
        Swal.fire("Thiếu nội dung", "Vui lòng nhập nội dung phản hồi.", "warning");
        return;
    }

    current.submitting = true;
    try {
        await EvaluateService.reply(current.item.id, { admin_reply: reply });
        Swal.fire("Thành công", "Đã phản hồi đánh giá.", "success");
        closeReply();
        await fetchItems();
    } catch (e) {
        const msg = e?.response?.data?.detail || "Không thể gửi phản hồi.";
        Swal.fire("Lỗi", msg, "error");
    } finally {
        current.submitting = false;
    }
}

onMounted(fetchItems);
</script>
