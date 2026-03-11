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
                <span v-if="conversation.unread_count" class="badge text-bg-danger rounded-pill">
                  {{ conversation.unread_count > 99 ? "99+" : conversation.unread_count }}
                </span>
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

              <div class="d-flex gap-2">
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
                  :class="{ mine: isMine(message) }">
                  <div class="message-bubble">
                    <div v-if="message.media_items?.length" class="d-flex flex-column gap-2">
                      <template v-for="media in message.media_items" :key="`${message.id}-${media.id}`">
                        <img v-if="media.media_type === 'image'" :src="media.path" alt="tệp đính kèm"
                          class="message-image" />
                        <a v-else :href="media.path" target="_blank" rel="noreferrer" class="file-chip">
                          <i class="fa-solid fa-paperclip me-2"></i>
                          {{ fileNameFromUrl(media.path) }}
                        </a>
                      </template>
                    </div>

                    <div v-if="message.content" :class="{ 'mt-2': message.media_items?.length }">
                      {{ message.content }}
                    </div>
                  </div>

                  <div class="message-meta">
                    {{
                      isMine(message) && wasSeenByCustomer(message)
                        ? "Đã xem"
                        : formatMessageTime(message.created_at)
                    }}
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

const lastSeenByCustomerMessageId = computed(
  () => activeConversation.value?.last_read_user_message_id || 0
);

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

function isMine(message) {
  return Number(message.user_id) === currentAdminId.value;
}

function wasSeenByCustomer(message) {
  return isMine(message) && Number(message.id || 0) <= lastSeenByCustomerMessageId.value;
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
  const incoming = !isMine(message);
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
      if (!isMine(message)) {
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
  min-height: 72vh;
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  overflow: hidden;
}

.chat-sidebar {
  min-width: 0;
  background: color-mix(in srgb, var(--main-color) 6%, transparent);
}

.conversation-list {
  max-height: calc(72vh - 73px);
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
  max-height: calc(72vh - 182px);
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

.message-meta {
  padding: 0.25rem 0.4rem 0;
  font-size: 0.8rem;
  opacity: 0.75;
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
