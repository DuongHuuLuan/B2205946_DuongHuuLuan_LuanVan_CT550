<template>
  <div class="row g-3">
    <div class="col-12">
      <div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2">
        <div>
          <h4 class="mb-1">Hỗ trợ khách hàng</h4>
          <!-- <div class="small opacity-75">
          </div> -->
        </div>

        <div class="d-flex gap-2">
          <RouterLink v-if="route.query.userId" class="btn btn-outline-secondary"
            :to="{ name: 'users.detail', params: { id: route.query.userId } }">
            <i class="fa-solid fa-user me-1"></i>
            Quay lại người dùng
          </RouterLink>
          <button class="btn btn-outline-secondary" type="button" :disabled="loadingConversations" @click="refreshAll">
            <i class="fa-solid fa-rotate-right me-1"></i>
            Làm mới
          </button>
        </div>
      </div>
    </div>

    <div class="col-12">
      <div class="card card-soft chat-shell">
        <div class="chat-sidebar border-end">
          <div class="p-3 border-bottom">
            <div class="fw-semibold">Danh sách hội thoại</div>
            <div class="small opacity-75">
              {{ conversations.length }} cuộc trò chuyện
            </div>
          </div>

          <div v-if="loadingConversations" class="p-3 small opacity-75">
            <i class="fa-solid fa-spinner fa-spin me-2"></i>
            Đang tải hội thoại...
          </div>

          <div v-else-if="!conversations.length" class="p-3 small opacity-75">
            Chưa có cuộc hội thoại nào.
          </div>

          <div v-else class="conversation-list">
            <button v-for="conversation in conversations" :key="conversation.id" type="button" class="conversation-item"
              :class="{ active: conversation.id === activeConversationId }"
              @click="selectConversation(conversation.id)">
              <div class="d-flex align-items-start justify-content-between gap-2">
                <div class="text-start conversation-copy">
                  <div class="fw-semibold text-truncate" :title="getCustomerDisplayName(conversation.user_id)">
                    {{ getCustomerDisplayName(conversation.user_id) }}
                  </div>
                  <!-- <div class="small opacity-75 text-truncate" :title="getCustomerSecondaryText(conversation.user_id)">
                    {{ getCustomerSecondaryText(conversation.user_id) }}
                  </div> -->
                  <div class="small opacity-75">
                    {{ formatConversationStamp(conversation) }}
                  </div>
                </div>
                <div class="d-flex flex-column align-items-end gap-1">
                  <span v-if="isConversationHandoffActive(conversation)" class="badge text-bg-warning rounded-pill">
                    Chờ tiếp quản
                  </span>
                  <span v-if="conversation.unread_count" class="badge text-bg-danger rounded-pill">
                    {{ conversation.unread_count > 99 ? "99+" : conversation.unread_count }}
                  </span>
                </div>
              </div>
            </button>
          </div>
        </div>

        <div class="chat-main">
          <template v-if="activeConversation">
            <div
              class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2 p-3 border-bottom">
              <div>
                <div class="fw-semibold">
                  {{ getCustomerDisplayName(activeConversation.user_id) }}
                </div>
                <!-- <div class="small opacity-75">
                  {{ getCustomerSecondaryText(activeConversation.user_id) }}
                </div> -->
                <div class="small opacity-75">
                  {{ socketConnected ? "Đã kết nối trực tuyến" : "Mất kết nối trực tuyến" }}
                </div>
              </div>

              <div v-if="activeConversationHandoffActive" class="small mt-1 text-warning-emphasis fw-semibold">
                {{ activeConversationClaimed ? "Tư vấn viên đang hỗ trợ thủ công" : "Cuộc chat đang chờ tiếp quản" }}
              </div>

              <div class="d-flex gap-2">
                <button
                  v-if="activeConversationHandoffActive && !activeConversationClaimed"
                  class="btn btn-sm btn-warning"
                  type="button"
                  :disabled="handoffActionLoading === 'claim'"
                  @click="claimActiveHandoff"
                >
                  <i v-if="handoffActionLoading === 'claim'" class="fa-solid fa-spinner fa-spin me-1"></i>
                  <i v-else class="fa-solid fa-user-check me-1"></i>
                  Tiếp nhận
                </button>
                <button
                  v-if="activeConversationHandoffActive"
                  class="btn btn-sm btn-outline-primary"
                  type="button"
                  :disabled="handoffActionLoading === 'resume'"
                  @click="resumeActiveChatbot"
                >
                  <i v-if="handoffActionLoading === 'resume'" class="fa-solid fa-spinner fa-spin me-1"></i>
                  <i v-else class="fa-solid fa-robot me-1"></i>
                  Bật lại trợ lý AI
                </button>
                <RouterLink class="btn btn-sm btn-outline-secondary"
                  :to="{ name: 'users.detail', params: { id: activeConversation.user_id } }">
                  <i class="fa-solid fa-user me-1"></i>
                  Xem hồ sơ
                </RouterLink>
              </div>
            </div>

            <div ref="messagesContainer" class="chat-messages">
              <div v-if="loadingMessages" class="p-3 small opacity-75">
                <i class="fa-solid fa-spinner fa-spin me-2"></i>
                Đang tải tin nhắn...
              </div>

              <div v-else-if="!messages.length" class="p-3 small opacity-75">
                Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện.
              </div>

              <div v-else class="p-3 d-flex flex-column gap-2">
                <div v-for="message in messages" :key="message.id || message.client_msg_id" class="message-row"
                  :class="{
                    mine: isMine(message),
                    'system-row': isBotLikeMessage(message),
                    'handoff-row': isHandoffNotice(message),
                  }">
                  <div class="message-bubble" :class="{
                    'message-bubble-bot': isBotLikeMessage(message),
                    'message-bubble-notice': isHandoffNotice(message),
                  }">
                    <div v-if="messageSenderLabel(message)" class="message-sender">
                      <i class="me-2" :class="messageSenderIconClass(message)"></i>
                      {{ messageSenderLabel(message) }}
                    </div>

                    <div v-if="isRecalled(message)" class="message-recalled">
                      <i class="fa-solid fa-rotate-left me-2"></i>
                      {{ message.content || "Tin nhắn đã được thu hồi" }}
                    </div>

                    <div v-else-if="message.media_items?.length" class="d-flex flex-column gap-2">
                      <template v-for="media in message.media_items" :key="`${message.id}-${media.id}`">
                        <img v-if="media.media_type === 'image'" :src="media.path" alt="tệp đính kèm"
                          class="message-image" />
                        <a v-else :href="media.path" target="_blank" rel="noreferrer" class="file-chip">
                          <i class="fa-solid fa-paperclip me-2"></i>
                          {{ fileNameFromUrl(media.path) }}
                        </a>
                      </template>
                    </div>

                    <div v-if="!isRecalled(message) && message.content"
                      :class="{ 'mt-2': message.media_items?.length }">
                      {{ message.content }}
                    </div>

                    <div
                      v-if="!isRecalled(message) && hasMonitoringCardPayload(message)"
                      class="message-structured"
                      :class="{ 'mt-3': hasMessageBody(message) }"
                    >
                      <template v-if="isProductListMessage(message)">
                        <div class="monitor-card-stack">
                          <div
                            v-if="message.payload?.title"
                            class="monitor-section-title"
                          >
                            <i class="fa-solid fa-box-open"></i>
                            {{ message.payload.title }}
                          </div>

                          <div
                            v-for="product in message.payload?.products || []"
                            :key="`product-${message.id}-${product.product_id}`"
                            class="monitor-card"
                          >
                            <div class="monitor-card-head">
                              <img
                                v-if="product.image_url"
                                :src="product.image_url"
                                :alt="product.name || 'Sản phẩm'"
                                class="monitor-thumb"
                              />

                              <div class="monitor-card-copy">
                                <div class="monitor-card-heading">
                                  {{ product.name || `Sản phẩm #${product.product_id}` }}
                                </div>

                                <div class="monitor-card-subtitle">
                                  <span v-if="product.category_name">
                                    {{ product.category_name }}
                                  </span>
                                  <span v-if="product.price != null">
                                    {{ formatCurrency(product.price) }}
                                  </span>
                                </div>

                                <div
                                  v-if="product.short_description"
                                  class="monitor-card-text"
                                >
                                  {{ product.short_description }}
                                </div>
                              </div>
                            </div>

                            <div
                              v-if="product.variants?.length"
                              class="monitor-chip-row"
                            >
                              <span
                                v-for="variant in product.variants"
                                :key="`variant-${message.id}-${variant.product_detail_id}`"
                                class="monitor-chip"
                                :class="
                                  variant.is_available
                                    ? 'monitor-chip-available'
                                    : 'monitor-chip-unavailable'
                                "
                              >
                                {{ formatVariantLabel(variant) }}
                                <span class="monitor-chip-divider">•</span>
                                {{ formatVariantStock(variant) }}
                              </span>
                            </div>

                            <div class="monitor-inline-actions">
                              <RouterLink
                                v-if="toPositiveNumber(product.product_id)"
                                class="monitor-inline-link"
                                :to="{
                                  name: 'products.detail',
                                  params: { id: product.product_id },
                                }"
                              >
                                <i class="fa-solid fa-up-right-from-square me-1"></i>
                                Xem sản phẩm
                              </RouterLink>
                            </div>
                          </div>

                          <div
                            v-if="message.payload?.follow_up_suggestions?.length"
                            class="monitor-card monitor-card-muted"
                          >
                            <div class="monitor-section-title monitor-section-title-sm">
                              <i class="fa-solid fa-comment-dots"></i>
                              Gợi ý tiếp theo của bot
                            </div>

                            <div class="monitor-suggestion-row">
                              <span
                                v-for="(suggestion, index) in message.payload.follow_up_suggestions"
                                :key="`suggestion-${message.id}-${index}`"
                                class="monitor-suggestion"
                              >
                                {{ suggestion }}
                              </span>
                            </div>
                          </div>
                        </div>
                      </template>

                      <template v-else-if="isDiscountListMessage(message)">
                        <div class="monitor-card-stack">
                          <div
                            v-if="message.payload?.title"
                            class="monitor-section-title"
                          >
                            <i class="fa-solid fa-ticket-percent"></i>
                            {{ message.payload.title }}
                          </div>

                          <div
                            v-for="discount in message.payload?.discounts || []"
                            :key="`discount-${message.id}-${discount.discount_id}`"
                            class="monitor-card"
                          >
                            <div class="d-flex flex-column flex-md-row gap-3 justify-content-between">
                              <div class="monitor-card-copy">
                                <div class="monitor-card-heading">
                                  {{ discount.name || `Mã #${discount.discount_id}` }}
                                </div>

                                <div class="monitor-card-subtitle">
                                  <span class="monitor-emphasis">
                                    Giảm {{ formatPercent(discount.percent) }}
                                  </span>
                                  <span v-if="discount.category_name">
                                    {{ discount.category_name }}
                                  </span>
                                  <span class="monitor-status-pill monitor-status-neutral">
                                    {{ discountStatusLabel(discount.status) }}
                                  </span>
                                </div>

                                <div
                                  v-if="discount.description"
                                  class="monitor-card-text"
                                >
                                  {{ discount.description }}
                                </div>

                                <div class="monitor-inline-meta">
                                  <span v-if="discount.start_at">
                                    Bắt đầu: {{ formatDate(discount.start_at) }}
                                  </span>
                                  <span v-if="discount.end_at">
                                    Kết thúc: {{ formatDate(discount.end_at) }}
                                  </span>
                                </div>
                              </div>

                              <div class="monitor-inline-actions monitor-inline-actions-tight">
                                <RouterLink
                                  v-if="toPositiveNumber(discount.discount_id)"
                                  class="monitor-inline-link"
                                  :to="{
                                    name: 'discounts.detail',
                                    params: { id: discount.discount_id },
                                  }"
                                >
                                  <i class="fa-solid fa-up-right-from-square me-1"></i>
                                  Xem mã
                                </RouterLink>
                              </div>
                            </div>
                          </div>
                        </div>
                      </template>

                      <template v-else-if="isOrderSummaryMessage(message)">
                        <div class="monitor-card-stack">
                          <div class="monitor-section-title">
                            <i class="fa-solid fa-receipt"></i>
                            {{ message.payload?.title || `Đơn hàng #${message.payload?.order?.order_id}` }}
                          </div>

                          <div class="monitor-card">
                            <div class="d-flex flex-column flex-md-row gap-3 justify-content-between">
                              <div class="monitor-card-copy">
                                <div class="monitor-card-subtitle">
                                  <span
                                    class="monitor-status-pill"
                                    :class="orderStatusClass(message.payload?.order?.status)"
                                  >
                                    {{
                                      message.payload?.order?.status_label ||
                                      message.payload?.order?.status ||
                                      "Không rõ trạng thái"
                                    }}
                                  </span>

                                  <span
                                    class="monitor-status-pill"
                                    :class="paymentStatusClass(message.payload?.order?.payment_status)"
                                  >
                                    {{
                                      message.payload?.order?.payment_status_label ||
                                      message.payload?.order?.payment_status ||
                                      "Không rõ thanh toán"
                                    }}
                                  </span>

                                  <span
                                    v-if="message.payload?.order?.refund_support_status_label"
                                    class="monitor-status-pill monitor-status-neutral"
                                  >
                                    {{ message.payload.order.refund_support_status_label }}
                                  </span>
                                </div>

                                <div class="monitor-inline-meta">
                                  <span v-if="message.payload?.order?.created_at">
                                    Tạo lúc: {{ formatDateTime(message.payload.order.created_at) }}
                                  </span>
                                  <span v-if="message.payload?.order?.payment_method_name">
                                    Thanh toán: {{ message.payload.order.payment_method_name }}
                                  </span>
                                  <span v-if="message.payload?.order?.recipient_name">
                                    Người nhận: {{ message.payload.order.recipient_name }}
                                  </span>
                                  <span v-if="message.payload?.order?.recipient_phone">
                                    SĐT: {{ message.payload.order.recipient_phone }}
                                  </span>
                                </div>

                                <div
                                  v-if="message.payload?.order?.delivery_address"
                                  class="monitor-card-text"
                                >
                                  {{ message.payload.order.delivery_address }}
                                </div>
                              </div>

                              <div class="monitor-inline-actions monitor-inline-actions-tight">
                                <RouterLink
                                  v-if="toPositiveNumber(message.payload?.order?.order_id)"
                                  class="monitor-inline-link"
                                  :to="{
                                    name: 'orders.detail',
                                    params: { id: message.payload.order.order_id },
                                  }"
                                >
                                  <i class="fa-solid fa-up-right-from-square me-1"></i>
                                  Chi tiết đơn
                                </RouterLink>

                                <RouterLink
                                  v-if="toPositiveNumber(message.payload?.order?.order_id)"
                                  class="monitor-inline-link"
                                  :to="{
                                    name: 'orders.production',
                                    params: { id: message.payload.order.order_id },
                                  }"
                                >
                                  <i class="fa-solid fa-industry me-1"></i>
                                  Sản xuất
                                </RouterLink>
                              </div>
                            </div>

                            <div
                              v-if="message.payload?.order?.items?.length"
                              class="monitor-order-items"
                            >
                              <div
                                v-for="(item, index) in message.payload.order.items"
                                :key="`order-item-${message.id}-${index}`"
                                class="monitor-order-item"
                              >
                                <img
                                  v-if="item.image_url"
                                  :src="item.image_url"
                                  :alt="item.product_name || 'Sản phẩm'"
                                  class="monitor-order-thumb"
                                />

                                <div class="monitor-card-copy">
                                  <div class="monitor-card-heading monitor-card-heading-sm">
                                    {{ item.product_name || "Sản phẩm" }}
                                  </div>
                                  <div
                                    v-if="formatOrderItemVariant(item)"
                                    class="monitor-card-subtitle"
                                  >
                                    {{ formatOrderItemVariant(item) }}
                                  </div>
                                </div>

                                <div class="monitor-order-price">
                                  {{ item.quantity || 0 }} ×
                                  {{ formatCurrency(item.unit_price) }}
                                </div>
                              </div>
                            </div>

                            <div class="monitor-stat-grid">
                              <div class="monitor-stat">
                                <div class="monitor-stat-label">Số lượng</div>
                                <div class="monitor-stat-value">
                                  {{ message.payload?.order?.total_items || 0 }}
                                </div>
                              </div>

                              <div class="monitor-stat">
                                <div class="monitor-stat-label">Phí ship</div>
                                <div class="monitor-stat-value">
                                  {{ formatCurrency(message.payload?.order?.shipping_fee) }}
                                </div>
                              </div>

                              <div class="monitor-stat">
                                <div class="monitor-stat-label">Tổng tiền</div>
                                <div class="monitor-stat-value">
                                  {{ formatCurrency(message.payload?.order?.total_amount) }}
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </template>

                      <template v-else-if="isCartActionResultMessage(message)">
                        <div class="monitor-card-stack">
                          <div class="monitor-section-title">
                            <i class="fa-solid fa-cart-shopping"></i>
                            {{ message.payload?.title || "Kết quả thao tác giỏ hàng" }}
                          </div>

                          <div
                            class="monitor-card"
                            :class="
                              message.payload?.cart_action_result?.status === 'error'
                                ? 'monitor-card-error'
                                : 'monitor-card-success'
                            "
                          >
                            <div class="monitor-card-head">
                              <img
                                v-if="message.payload?.cart_action_result?.image_url"
                                :src="message.payload.cart_action_result.image_url"
                                :alt="
                                  message.payload?.cart_action_result?.product_name ||
                                  'Sản phẩm'
                                "
                                class="monitor-thumb"
                              />

                              <div class="monitor-card-copy">
                                <div class="monitor-card-heading">
                                  {{
                                    message.payload?.cart_action_result?.product_name ||
                                    "Sản phẩm trong giỏ"
                                  }}
                                </div>

                                <div class="monitor-card-subtitle">
                                  <span
                                    class="monitor-status-pill"
                                    :class="
                                      cartActionStatusClass(
                                        message.payload?.cart_action_result?.status
                                      )
                                    "
                                  >
                                    {{
                                      cartActionStatusLabel(
                                        message.payload?.cart_action_result?.status
                                      )
                                    }}
                                  </span>

                                  <span v-if="message.payload?.cart_action_result?.variant_label">
                                    {{ message.payload.cart_action_result.variant_label }}
                                  </span>

                                  <span>
                                    SL {{ message.payload?.cart_action_result?.quantity || 0 }}
                                  </span>
                                </div>

                                <div
                                  v-if="message.payload?.cart_action_result?.message"
                                  class="monitor-card-text"
                                >
                                  {{ message.payload.cart_action_result.message }}
                                </div>

                                <div
                                  v-if="toPositiveNumber(message.payload?.cart_action_result?.product_detail_id)"
                                  class="monitor-inline-meta"
                                >
                                  <span>
                                    Mã biến thể:
                                    PD{{ message.payload.cart_action_result.product_detail_id }}
                                  </span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </template>
                    </div>

                    <div v-if="!isRecalled(message) && isHandoffNotice(message) && message.payload?.notice_message"
                      class="message-notice">
                      <i class="fa-solid fa-user-headset me-2"></i>
                      {{ message.payload.notice_message }}
                    </div>
                  </div>

                  <div class="message-meta-row">
                    <button v-if="canRecallMessage(message)" class="message-action" type="button"
                      :disabled="recallingMessageId === message.id" @click="recallMessage(message)">
                      <i v-if="recallingMessageId === message.id" class="fa-solid fa-spinner fa-spin me-1"></i>
                      <i v-else class="fa-solid fa-rotate-left me-1"></i>
                      Thu hồi
                    </button>
                    <div class="message-meta">{{ formatMessageMeta(message) }}
                    </div>
                  </div>
                </div>
              </div>

              <div v-if="selectedFiles.length" class="file-preview border-top">
                <div v-for="(file, index) in selectedFiles" :key="`${file.name}-${index}`" class="file-preview-item">
                  <div class="small fw-semibold text-truncate">
                    {{ file.name }}
                  </div>
                  <button class="btn btn-sm btn-link text-danger p-0" type="button" @click="removeSelectedFile(index)">
                    Gỡ bỏ
                  </button>
                </div>
              </div>
            </div>

            <div class="p-3 border-top">
              <div v-if="errorMessage" class="alert alert-danger py-2 mb-3">
                {{ errorMessage }}
              </div>

              <div class="d-flex gap-2 align-items-end">
                <button class="btn btn-outline-secondary" type="button" :disabled="sending" @click="openFilePicker">
                  <i class="fa-solid fa-paperclip"></i>
                </button>

                <input ref="fileInput" type="file" class="d-none" multiple @change="handleFileChange" />

                <div class="flex-grow-1">
                  <textarea v-model="draft" class="form-control" rows="2" placeholder="Nhập tin nhắn..."
                    @keydown.enter.exact.prevent="submitMessage" />
                </div>

                <button class="btn btn-primary" type="button"
                  :disabled="sending || (!draft.trim() && !selectedFiles.length)" @click="submitMessage">
                  <span v-if="sending">
                    <i class="fa-solid fa-spinner fa-spin me-1"></i>
                    Đang gửi
                  </span>
                  <span v-else>
                    <i class="fa-solid fa-paper-plane me-1"></i>
                    Gửi
                  </span>
                </button>
              </div>
            </div>
          </template>

          <div v-else class="h-100 d-flex align-items-center justify-content-center text-center p-4 opacity-75">
            <div>
              <div class="fs-4 mb-2">
                <i class="fa-regular fa-comments"></i>
              </div>
              <div>Chọn một hội thoại để bắt đầu nhắn tin.</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute } from "vue-router";
import Swal from "sweetalert2";
import ChatService from "@/services/chat.service";
import UserService from "@/services/user.service";
import {
  chatNotificationState,
  clearActiveChatConversation,
  setActiveChatConversation,
  setChatPageActive,
} from "@/state/chat-notification.state";

const route = useRoute();

const conversations = ref([]);
const activeConversationId = ref(null);
const messages = ref([]);
const loadingConversations = ref(false);
const loadingMessages = ref(false);
const sending = ref(false);
const recallingMessageId = ref(null);
const handoffActionLoading = ref("");
const errorMessage = ref("");
const draft = ref("");
const selectedFiles = ref([]);
const fileInput = ref(null);
const messagesContainer = ref(null);
const customerMap = ref({});

const loadingCustomerIds = new Set();

const currentAdmin = computed(() => {
  try {
    return JSON.parse(localStorage.getItem("currentUser") || "null");
  } catch (_) {
    return null;
  }
});

const currentAdminId = computed(() => Number(currentAdmin.value?.id || 0));
const socketConnected = computed(() => chatNotificationState.socketConnected);

const activeConversation = computed(() =>
  conversations.value.find((item) => item.id === activeConversationId.value) || null
);
const activeConversationHandoffActive = computed(() =>
  isConversationHandoffActive(activeConversation.value)
);
const activeConversationClaimed = computed(() => hasClaimedNotice(messages.value));

const lastSeenByCustomerMessageId = computed(
  () => activeConversation.value?.last_read_user_message_id || 0
);

const currencyFormatter = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

const percentFormatter = new Intl.NumberFormat("vi-VN", {
  maximumFractionDigits: 2,
});

const shortDateFormatter = new Intl.DateTimeFormat("vi-VN", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

const dateTimeFormatter = new Intl.DateTimeFormat("vi-VN", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

function normalizeConversation(item = {}) {
  return {
    unread_count: 0,
    last_message_id: null,
    last_read_user_message_id: null,
    last_read_admin_message_id: null,
    last_message_at: null,
    ...item,
  };
}

function normalizeMessage(item = {}) {
  return {
    media_items: [],
    is_recalled: false,
    recalled_at: null,
    sender_role: null,
    payload: null,
    ...item,
  };
}

function getCachedCustomer(userId) {
  if (!userId) return null;
  return customerMap.value[String(userId)] || null;
}

function customerIdLabel(userId) {
  return userId ? `Mã KH: U${userId}` : "Khách hàng";
}

function getCustomerDisplayName(userId) {
  const customer = getCachedCustomer(userId);
  return (
    customer?.profile?.name ||
    customer?.full_name ||
    customer?.name ||
    customer?.username ||
    customerIdLabel(userId)
  );
}

function getCustomerSecondaryText(userId) {
  const customer = getCachedCustomer(userId);
  if (!customer) return customerIdLabel(userId);
  if (customer?.profile?.name) {
    return customer?.username || customer?.email || customerIdLabel(userId);
  }
  return customer?.email || customerIdLabel(userId);
}

async function loadCustomer(userId) {
  const normalizedId = Number(userId || 0);
  if (!normalizedId || getCachedCustomer(normalizedId) || loadingCustomerIds.has(normalizedId)) {
    return;
  }

  loadingCustomerIds.add(normalizedId);
  try {
    const response = await UserService.get(normalizedId);
    const customer = response?.data ?? response ?? null;
    if (!customer) return;

    customerMap.value = {
      ...customerMap.value,
      [normalizedId]: customer,
    };
  } catch (_) {
    // Giữ fallback theo ID nếu không tải được thông tin khách hàng.
  } finally {
    loadingCustomerIds.delete(normalizedId);
  }
}

async function hydrateConversationCustomers(list = []) {
  const userIds = [...new Set(list.map((item) => Number(item?.user_id || 0)).filter(Boolean))];
  await Promise.all(userIds.map((userId) => loadCustomer(userId)));
}

function sortConversations() {
  conversations.value.sort((left, right) => {
    const leftTime = new Date(
      left.last_message_at || left.updated_at || left.created_at || 0
    ).getTime();
    const rightTime = new Date(
      right.last_message_at || right.updated_at || right.created_at || 0
    ).getTime();
    return rightTime - leftTime;
  });
}

function upsertConversation(conversation, { moveToTop = false } = {}) {
  const normalized = normalizeConversation(conversation);
  const index = conversations.value.findIndex((item) => item.id === normalized.id);
  void loadCustomer(normalized.user_id);
  if (index >= 0) {
    conversations.value.splice(index, 1, {
      ...conversations.value[index],
      ...normalized,
    });
  } else {
    conversations.value.push(normalized);
  }

  if (moveToTop) {
    const currentIndex = conversations.value.findIndex(
      (item) => item.id === normalized.id
    );
    if (currentIndex > 0) {
      const [item] = conversations.value.splice(currentIndex, 1);
      conversations.value.unshift(item);
      return;
    }
  }

  sortConversations();
}

function upsertMessage(message) {
  const normalized = normalizeMessage(message);
  const index = messages.value.findIndex(
    (item) =>
      item.id === normalized.id ||
      (item.client_msg_id && item.client_msg_id === normalized.client_msg_id)
  );

  if (index >= 0) {
    messages.value.splice(index, 1, {
      ...messages.value[index],
      ...normalized,
    });
  } else {
    messages.value.push(normalized);
  }

  messages.value.sort(
    (left, right) =>
      new Date(left.created_at || 0).getTime() -
      new Date(right.created_at || 0).getTime()
  );
}

function messageSenderRole(message) {
  const senderRole = String(message?.sender_role || "")
    .trim()
    .toLowerCase();
  if (senderRole) return senderRole;
  return Number(message?.user_id || 0) === currentAdminId.value ? "admin" : "user";
}

function isMine(message) {
  return messageSenderRole(message) === "admin";
}

function isBotLikeMessage(message) {
  const role = messageSenderRole(message);
  return role === "bot" || role === "system";
}

function isHandoffNotice(message) {
  return String(message?.payload?.kind || "")
    .trim()
    .toLowerCase() === "handoff_notice";
}

function messagePayloadKind(message) {
  return String(message?.payload?.kind || "")
    .trim()
    .toLowerCase();
}

function isProductListMessage(message) {
  return (
    messagePayloadKind(message) === "product_list" &&
    Array.isArray(message?.payload?.products) &&
    message.payload.products.length > 0
  );
}

function isDiscountListMessage(message) {
  return (
    messagePayloadKind(message) === "discount_list" &&
    Array.isArray(message?.payload?.discounts) &&
    message.payload.discounts.length > 0
  );
}

function isOrderSummaryMessage(message) {
  return (
    messagePayloadKind(message) === "order_summary" &&
    message?.payload?.order &&
    typeof message.payload.order === "object"
  );
}

function isCartActionResultMessage(message) {
  return (
    messagePayloadKind(message) === "cart_action_result" &&
    message?.payload?.cart_action_result &&
    typeof message.payload.cart_action_result === "object"
  );
}

function hasMonitoringCardPayload(message) {
  return (
    isProductListMessage(message) ||
    isDiscountListMessage(message) ||
    isOrderSummaryMessage(message) ||
    isCartActionResultMessage(message)
  );
}

function hasMessageBody(message) {
  return (
    Boolean(String(message?.content || "").trim()) ||
    Boolean(message?.media_items?.length)
  );
}

function toPositiveNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
}

function formatCurrency(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return "Chưa có giá";
  return currencyFormatter.format(amount);
}

function formatPercent(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return "0%";
  return `${percentFormatter.format(amount)}%`;
}

function formatDate(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return shortDateFormatter.format(date);
}

function formatDateTime(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return dateTimeFormatter.format(date);
}

function formatVariantLabel(variant = {}) {
  const bits = [variant.color_name, variant.size_name].filter(Boolean);
  return bits.join(" / ") || `PD${variant.product_detail_id || "?"}`;
}

function formatVariantStock(variant = {}) {
  const stock = Number(variant?.stock || 0);
  return variant?.is_available ? `Tồn ${stock}` : "Hết hàng";
}

function discountStatusLabel(status) {
  const normalized = String(status || "")
    .trim()
    .toLowerCase();

  if (normalized === "active") return "Đang áp dụng";
  if (normalized === "upcoming") return "Sắp áp dụng";
  if (normalized === "expired") return "Hết hạn";
  if (normalized === "inactive") return "Tạm ngưng";
  return status || "Không rõ trạng thái";
}

function formatOrderItemVariant(item = {}) {
  return [item.color_name, item.size_name].filter(Boolean).join(" / ");
}

function orderStatusClass(status) {
  const normalized = String(status || "")
    .trim()
    .toLowerCase();

  if (normalized === "completed") return "monitor-status-success";
  if (normalized === "shipping") return "monitor-status-warning";
  if (normalized === "cancelled") return "monitor-status-danger";
  return "monitor-status-neutral";
}

function paymentStatusClass(status) {
  const normalized = String(status || "")
    .trim()
    .toLowerCase();

  if (normalized === "paid") return "monitor-status-success";
  if (normalized === "unpaid") return "monitor-status-warning";
  return "monitor-status-neutral";
}

function cartActionStatusClass(status) {
  const normalized = String(status || "")
    .trim()
    .toLowerCase();

  if (normalized === "success") return "monitor-status-success";
  if (normalized === "error") return "monitor-status-danger";
  return "monitor-status-neutral";
}

function cartActionStatusLabel(status) {
  const normalized = String(status || "")
    .trim()
    .toLowerCase();

  if (normalized === "success") return "Thành công";
  if (normalized === "error") return "Thất bại";
  return status || "Không rõ trạng thái";
}

function handoffNoticeCode(message) {
  return String(message?.payload?.notice_code || "")
    .trim()
    .toLowerCase();
}

function hasClaimedNotice(list = []) {
  for (let index = list.length - 1; index >= 0; index -= 1) {
    const message = list[index];
    if (!isHandoffNotice(message)) continue;
    const code = handoffNoticeCode(message);
    if (code === "human_handoff_claimed") return true;
    if (code === "human_handoff_requested" || code === "bot_resumed") return false;
  }
  return false;
}

function isConversationHandoffActive(conversation) {
  return String(conversation?.status || "")
    .trim()
    .toLowerCase() === "closed";
}

function messageSenderLabel(message) {
  const role = messageSenderRole(message);
  if (role === "bot") return "Trợ lý AI";
  if (role === "system") return "Hệ thống";
  return "";
}

function messageSenderIconClass(message) {
  if (isHandoffNotice(message)) return "fa-solid fa-user-headset";
  const role = messageSenderRole(message);
  if (role === "bot") return "fa-solid fa-robot";
  if (role === "system") return "fa-solid fa-circle-info";
  return "fa-regular fa-message";
}

function isRecalled(message) {
  return Boolean(message?.is_recalled);
}

function wasSeenByCustomer(message) {
  return isMine(message) && Number(message.id || 0) <= lastSeenByCustomerMessageId.value;
}

function canRecallMessage(message) {
  return (
    Boolean(activeConversation.value) &&
    isMine(message) &&
    !isRecalled(message) &&
    Number(message.id || 0) > 0
  );
}

function fileNameFromUrl(path = "") {
  return String(path).split("/").pop() || "tệp đính kèm";
}

function formatMessageTime(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatMessageMeta(message) {
  if (isRecalled(message)) return "Đã thu hồi";
  if (isMine(message) && wasSeenByCustomer(message)) return "Đã xem";
  return formatMessageTime(message?.created_at);
}

function formatConversationStamp(conversation) {
  const source =
    conversation.last_message_at || conversation.updated_at || conversation.created_at;
  if (!source) return "Không có hoạt động";
  const date = new Date(source);
  if (Number.isNaN(date.getTime())) return "Không có hoạt động";
  return date.toLocaleString("vi-VN");
}

async function scrollToBottom() {
  await nextTick();
  if (!messagesContainer.value) return;
  messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
}

async function loadConversations({ silent = false } = {}) {
  if (!silent) {
    loadingConversations.value = true;
    errorMessage.value = "";
  }

  try {
    const items = await ChatService.getConversations();
    conversations.value = items.map(normalizeConversation);
    sortConversations();
    await hydrateConversationCustomers(conversations.value);
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể tải danh sách hội thoại.";
  } finally {
    loadingConversations.value = false;
  }
}

async function loadMessages(conversationId) {
  loadingMessages.value = true;
  errorMessage.value = "";
  try {
    const payload = await ChatService.getMessages(conversationId);
    messages.value = (payload.items || []).map(normalizeMessage);
    await scrollToBottom();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể tải tin nhắn.";
  } finally {
    loadingMessages.value = false;
  }
}

function applyReadPayload(actorUserId, payload) {
  const index = conversations.value.findIndex(
    (item) => Number(item.id) === Number(payload?.conversation_id)
  );
  if (index < 0) return;

  const current = conversations.value[index];
  const updated = { ...current };

  if (Number(actorUserId) === currentAdminId.value) {
    updated.last_read_admin_message_id = payload.last_read_message_id;
    updated.unread_count = payload.unread_count ?? 0;
  } else {
    updated.last_read_user_message_id = payload.last_read_message_id;
  }

  conversations.value.splice(index, 1, updated);
}

function touchConversationAfterMessage(message) {
  const index = conversations.value.findIndex(
    (item) => Number(item.id) === Number(message.conversation_id)
  );
  if (index < 0) return;

  const current = conversations.value[index];
  const incoming = messageSenderRole(message) === "user";
  const updated = {
    ...current,
    last_message_id: message.id,
    last_message_at: message.created_at,
    unread_count:
      activeConversationId.value === current.id
        ? 0
        : incoming
          ? Number(current.unread_count || 0) + 1
          : Number(current.unread_count || 0),
  };

  upsertConversation(updated, { moveToTop: true });
}

async function markConversationRead(messageId = null) {
  if (!activeConversation.value) return;

  try {
    const response = await ChatService.markConversationRead(
      activeConversation.value.id,
      messageId
    );
    applyReadPayload(currentAdminId.value, response);
  } catch (_) {
    // Giữ UI hoạt động ngay cả khi việc đồng bộ trạng thái đọc thất bại.
  }
}

async function selectConversation(conversationId) {
  if (Number(activeConversationId.value) === Number(conversationId)) {
    setActiveChatConversation(conversationId);
    return;
  }

  activeConversationId.value = Number(conversationId);
  setActiveChatConversation(conversationId);
  errorMessage.value = "";
  await loadMessages(conversationId);
  await markConversationRead();
}

async function ensureConversationFromRoute() {
  const requestedUserId = Number(route.query.userId || 0);
  if (!requestedUserId) return false;

  try {
    const conversation = await ChatService.createOrGetConversation({
      userId: requestedUserId,
    });
    upsertConversation(conversation, { moveToTop: true });
    await selectConversation(conversation.id);
    return true;
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail ||
      error?.message ||
      "Không thể mở hội thoại cho người dùng này.";
    return false;
  }
}

function openFilePicker() {
  fileInput.value?.click();
}

function handleFileChange(event) {
  const files = Array.from(event.target?.files || []);
  selectedFiles.value = files;
}

function removeSelectedFile(index) {
  selectedFiles.value.splice(index, 1);
  if (!selectedFiles.value.length && fileInput.value) {
    fileInput.value.value = "";
  }
}

function resetComposer() {
  draft.value = "";
  selectedFiles.value = [];
  if (fileInput.value) {
    fileInput.value.value = "";
  }
}

function createClientMsgId() {
  return `admin-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

async function submitMessage() {
  if (!activeConversation.value || sending.value) return;
  if (!draft.value.trim() && !selectedFiles.value.length) return;

  sending.value = true;
  errorMessage.value = "";

  try {
    const response = await ChatService.sendMessage(activeConversation.value.id, {
      content: draft.value,
      clientMsgId: createClientMsgId(),
      files: selectedFiles.value,
    });
    upsertMessage(response);
    touchConversationAfterMessage(response);
    resetComposer();
    await scrollToBottom();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể gửi tin nhắn.";
  } finally {
    sending.value = false;
  }
}

async function claimActiveHandoff() {
  if (!activeConversation.value || handoffActionLoading.value) return;

  handoffActionLoading.value = "claim";
  errorMessage.value = "";
  try {
    const response = await ChatService.claimHandoff(activeConversation.value.id);
    upsertMessage(response);
    touchConversationAfterMessage(response);
    await loadConversations({ silent: true });
    await scrollToBottom();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể tiếp nhận cuộc hội thoại này.";
  } finally {
    handoffActionLoading.value = "";
  }
}

async function resumeActiveChatbot() {
  if (!activeConversation.value || handoffActionLoading.value) return;

  handoffActionLoading.value = "resume";
  errorMessage.value = "";
  try {
    const response = await ChatService.resumeChatbot(activeConversation.value.id);
    upsertMessage(response);
    touchConversationAfterMessage(response);
    await loadConversations({ silent: true });
    await scrollToBottom();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể bật lại trợ lý AI lúc này.";
  } finally {
    handoffActionLoading.value = "";
  }
}

async function recallMessage(message) {
  if (!activeConversation.value || !canRecallMessage(message)) return;

  const result = await Swal.fire({
    title: "Thu hồi tin nhắn?",
    text: "Bạn có chắc chắn muốn thu hồi tin nhắn?",
    icon: "warning",
    showCancelButton: true,
    confirmButtonText: "Thu hồi",
    cancelButtonText: "Hủy",
  });
  if (!result.isConfirmed) return;

  recallingMessageId.value = message.id;
  errorMessage.value = "";

  try {
    const response = await ChatService.recallMessage(activeConversation.value.id, message.id);
    upsertMessage(response);
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.detail || error?.message || "Không thể thu hồi tin nhắn.";
  } finally {
    recallingMessageId.value = null;
  }
}

async function refreshAll() {
  await loadConversations();
  if (activeConversationId.value) {
    await loadMessages(activeConversationId.value);
    await markConversationRead();
  } else if (conversations.value.length) {
    await selectConversation(conversations.value[0].id);
  }
}

watch(
  () => route.query.userId,
  async (nextUserId, previousUserId) => {
    if (nextUserId === previousUserId) return;
    const opened = await ensureConversationFromRoute();
    if (!opened && !activeConversationId.value && conversations.value.length) {
      await selectConversation(conversations.value[0].id);
    }
  }
);

watch(
  () => messages.value.length,
  async () => {
    await scrollToBottom();
  }
);

watch(
  () => chatNotificationState.lastEventTick,
  async () => {
    const payload = chatNotificationState.lastEvent;
    if (!payload) return;

    if (payload.event === "message:new" && payload.data) {
      const message = normalizeMessage(payload.data);
      if (payload.conversation) {
        upsertConversation(payload.conversation, { moveToTop: true });
      } else {
        touchConversationAfterMessage(message);
      }

      if (Number(payload.conversation_id) !== Number(activeConversationId.value)) {
        return;
      }

      upsertMessage(message);
      await scrollToBottom();
      if (messageSenderRole(message) === "user") {
        await markConversationRead(message.id);
      }
      return;
    }

    if (payload.event === "message:read" && payload.data) {
      if (payload.conversation) {
        upsertConversation(payload.conversation);
      } else {
        applyReadPayload(payload.user_id, payload.data);
      }
      return;
    }

    if (payload.event === "message:recalled" && payload.data) {
      if (payload.conversation) {
        upsertConversation(payload.conversation);
      }

      if (Number(payload.conversation_id) !== Number(activeConversationId.value)) {
        return;
      }

      upsertMessage(payload.data);
      return;
    }

    if (payload.event === "conversation:upsert" && payload.conversation) {
      upsertConversation(payload.conversation, { moveToTop: true });
    }
  }
);

onMounted(async () => {
  setChatPageActive(true);
  await loadConversations();

  const openedFromRoute = await ensureConversationFromRoute();
  if (!openedFromRoute && conversations.value.length) {
    await selectConversation(conversations.value[0].id);
  }
});

onBeforeUnmount(() => {
  clearActiveChatConversation();
  setChatPageActive(false);
});
</script>

<style scoped>
.card-soft {
  background: var(--main-extra-bg);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  color: var(--font-color);
}

.chat-shell {
  /* min-height: 72vh; */
  min-height: 80vh;
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  overflow: hidden;
}

.chat-sidebar {
  min-width: 0;
  background: color-mix(in srgb, var(--main-color) 6%, transparent);
}

.conversation-list {
  /* max-height: calc(72vh - 73px); */
  max-height: calc(80vh - 73px);
  overflow: auto;
}

.conversation-item {
  width: 100%;
  padding: 1rem;
  border: 0;
  border-bottom: 1px solid var(--border-color);
  background: transparent;
  color: inherit;
}

.conversation-copy {
  min-width: 0;
  flex: 1 1 auto;
}

.conversation-item:hover,
.conversation-item.active {
  background: color-mix(in srgb, var(--main-color) 14%, transparent);
}

.chat-main {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.chat-messages {
  flex: 1;
  min-height: 0;
  /* max-height: calc(72vh - 182px); */
  max-height: calc(80vh - 182px);
  overflow: auto;
}

.message-row {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.message-row.mine {
  align-items: flex-end;
}

.message-row.system-row {
  align-items: flex-start;
}

.message-bubble {
  max-width: min(70%, 720px);
  padding: 0.85rem 1rem;
  border-radius: 1rem;
  background: #eef2f8;
  color: #213042;
  box-shadow: 0 8px 24px rgba(31, 44, 62, 0.08);
}

.message-row.mine .message-bubble {
  background: var(--main-color);
  color: #112033;
}

.message-bubble-bot {
  background: #f5f7fb;
  color: #213042;
}

.message-bubble-notice {
  background: #fff3d6;
  color: #5f4500;
  border: 1px solid rgba(185, 132, 0, 0.18);
}

.message-sender {
  display: inline-flex;
  align-items: center;
  margin-bottom: 0.45rem;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.01em;
  opacity: 0.84;
}

.message-recalled {
  font-style: italic;
  opacity: 0.82;
}

.message-notice {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px dashed rgba(95, 69, 0, 0.2);
  font-size: 0.92rem;
  line-height: 1.45;
}

.message-structured {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.monitor-card-stack {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.monitor-section-title {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.8rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  opacity: 0.8;
}

.monitor-section-title-sm {
  font-size: 0.74rem;
}

.monitor-card {
  padding: 0.85rem;
  border-radius: 0.9rem;
  border: 1px solid rgba(33, 48, 66, 0.1);
  background: rgba(255, 255, 255, 0.56);
}

.monitor-card-muted {
  background: rgba(255, 255, 255, 0.36);
}

.monitor-card-success {
  border-color: rgba(46, 125, 50, 0.25);
}

.monitor-card-error {
  border-color: rgba(176, 0, 32, 0.25);
}

.monitor-card-head {
  display: grid;
  grid-template-columns: 72px minmax(0, 1fr);
  gap: 0.85rem;
  align-items: start;
}

.monitor-thumb {
  width: 72px;
  height: 72px;
  border-radius: 0.8rem;
  object-fit: cover;
  background: rgba(255, 255, 255, 0.45);
}

.monitor-card-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.32rem;
}

.monitor-card-heading {
  font-weight: 700;
  line-height: 1.35;
}

.monitor-card-heading-sm {
  font-size: 0.92rem;
}

.monitor-card-subtitle {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem 0.65rem;
  font-size: 0.82rem;
  opacity: 0.82;
}

.monitor-card-text {
  font-size: 0.92rem;
  line-height: 1.48;
}

.monitor-emphasis {
  font-weight: 700;
}

.monitor-chip-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.45rem;
  margin-top: 0.75rem;
}

.monitor-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.38rem 0.65rem;
  border-radius: 999px;
  border: 1px solid rgba(33, 48, 66, 0.12);
  background: rgba(255, 255, 255, 0.48);
  font-size: 0.78rem;
  line-height: 1.2;
}

.monitor-chip-available {
  color: #1f4f29;
}

.monitor-chip-unavailable {
  color: #8b1831;
  background: rgba(176, 0, 32, 0.07);
}

.monitor-chip-divider {
  opacity: 0.45;
}

.monitor-inline-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.75rem;
  align-items: center;
}

.monitor-inline-actions-tight {
  margin-top: 0;
}

.monitor-inline-link {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0;
  border: 0;
  background: transparent;
  color: #486581;
  text-decoration: none;
  font-size: 0.84rem;
  font-weight: 600;
  line-height: 1.35;
}

.monitor-inline-link:hover {
  color: #213042;
  text-decoration: underline;
  text-underline-offset: 0.18em;
}

.monitor-inline-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem 0.8rem;
  margin-top: 0.5rem;
  font-size: 0.8rem;
  opacity: 0.78;
}

.monitor-suggestion-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.65rem;
}

.monitor-suggestion {
  display: inline-flex;
  align-items: center;
  padding: 0.36rem 0.65rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.45);
  font-size: 0.78rem;
}

.monitor-order-items {
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
  margin-top: 0.85rem;
}

.monitor-order-item {
  display: grid;
  grid-template-columns: 48px minmax(0, 1fr) auto;
  gap: 0.75rem;
  align-items: center;
}

.monitor-order-thumb {
  width: 48px;
  height: 48px;
  border-radius: 0.7rem;
  object-fit: cover;
  background: rgba(255, 255, 255, 0.45);
}

.monitor-order-price {
  text-align: right;
  font-size: 0.84rem;
  font-weight: 700;
  white-space: nowrap;
}

.monitor-stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 0.55rem;
  margin-top: 0.85rem;
}

.monitor-stat {
  padding: 0.65rem 0.75rem;
  border-radius: 0.8rem;
  background: rgba(255, 255, 255, 0.42);
}

.monitor-stat-label {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  opacity: 0.7;
}

.monitor-stat-value {
  margin-top: 0.2rem;
  font-weight: 700;
}

.monitor-status-pill {
  display: inline-flex;
  align-items: center;
  padding: 0.28rem 0.56rem;
  border-radius: 999px;
  border: 1px solid transparent;
  font-size: 0.75rem;
  font-weight: 700;
}

.monitor-status-success {
  background: rgba(46, 125, 50, 0.14);
  color: #215c29;
}

.monitor-status-warning {
  background: rgba(185, 132, 0, 0.14);
  color: #7a5a00;
}

.monitor-status-danger {
  background: rgba(176, 0, 32, 0.12);
  color: #8b1831;
}

.monitor-status-neutral {
  background: rgba(33, 48, 66, 0.08);
  color: inherit;
}

.message-meta-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0.25rem 0.4rem 0;
}

.message-meta {
  font-size: 0.8rem;
  opacity: 0.75;
}

.message-action {
  border: 0;
  padding: 0;
  background: transparent;
  color: var(--font-extra-color);
  font-size: 0.8rem;
  transition: color 0.15s ease;
}

.message-action:hover:not(:disabled) {
  color: var(--status-danger);
}

.message-action:disabled {
  opacity: 0.65;
}

.message-image {
  max-width: 220px;
  max-height: 220px;
  object-fit: cover;
  border-radius: 0.85rem;
  display: block;
}

.file-chip {
  display: inline-flex;
  align-items: center;
  max-width: 100%;
  padding: 0.5rem 0.75rem;
  border-radius: 999px;
  text-decoration: none;
  background: rgba(255, 255, 255, 0.35);
  color: inherit;
}

.file-preview {
  display: flex;
  gap: 0.75rem;
  padding: 0.9rem 1rem;
  overflow-x: auto;
}

.file-preview-item {
  min-width: 180px;
  padding: 0.75rem;
  border-radius: 0.85rem;
  background: color-mix(in srgb, var(--main-color) 10%, transparent);
  border: 1px solid var(--border-color);
}

@media (max-width: 991.98px) {
  .chat-shell {
    grid-template-columns: 1fr;
  }

  .chat-sidebar {
    border-right: 0 !important;
    border-bottom: 1px solid var(--border-color);
  }

  .conversation-list {
    max-height: 260px;
  }

  .chat-messages {
    max-height: 56vh;
  }

  .message-bubble {
    max-width: 88%;
  }

  .monitor-card-head {
    grid-template-columns: 56px minmax(0, 1fr);
  }

  .monitor-thumb {
    width: 56px;
    height: 56px;
  }

  .monitor-order-item {
    grid-template-columns: 40px minmax(0, 1fr);
  }

  .monitor-order-thumb {
    width: 40px;
    height: 40px;
  }

  .monitor-order-price {
    grid-column: 2;
    text-align: left;
  }
}

.btn-primary {
  background-color: var(--main-color) !important;
  border-color: var(--main-color) !important;
  color: #112033 !important;
  /* Hoặc #fff tùy vào độ sáng của màu vàng */
}

.btn-primary:hover:not(:disabled) {
  filter: brightness(0.9);
  /* Tự động làm tối màu một chút */
}
</style>
