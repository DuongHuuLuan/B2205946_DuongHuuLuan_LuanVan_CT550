import { reactive } from "vue";
import ChatService from "@/services/chat.service";

const RECONNECT_DELAY_MS = 3000;
const TOAST_LIFETIME_MS = 6000;
const MAX_TOASTS = 4;

export const chatNotificationState = reactive({
  started: false,
  socketConnected: false,
  isChatPageActive: false,
  activeConversationId: null,
  conversations: [],
  totalUnreadCount: 0,
  unreadConversationCount: 0,
  toasts: [],
  lastSyncedAt: null,
  lastEvent: null,
  lastEventTick: 0,
});

let adminSocket = null;
let reconnectTimer = null;
let refreshPromise = null;
const toastTimers = new Map();
const notifiedMessageIds = new Map();

function readCurrentAdminId() {
  try {
    const raw = localStorage.getItem("currentUser");
    const currentUser = raw ? JSON.parse(raw) : null;
    return Number(currentUser?.id || 0);
  } catch (_) {
    return 0;
  }
}

function readAccessToken() {
  try {
    return localStorage.getItem("access_token") || "";
  } catch (_) {
    return "";
  }
}

function isPageVisible() {
  if (typeof document === "undefined") return true;
  return document.visibilityState === "visible";
}

function normalizeConversation(item = {}) {
  return {
    unread_count: 0,
    last_message_id: null,
    last_read_user_message_id: null,
    last_read_admin_message_id: null,
    last_message_at: null,
    user: null,
    ...item,
  };
}

function sortConversations() {
  chatNotificationState.conversations.sort((left, right) => {
    const leftTime = new Date(
      left.last_message_at || left.updated_at || left.created_at || 0,
    ).getTime();
    const rightTime = new Date(
      right.last_message_at || right.updated_at || right.created_at || 0,
    ).getTime();
    return rightTime - leftTime;
  });
}

function syncUnreadTotals() {
  const conversations = chatNotificationState.conversations || [];
  chatNotificationState.totalUnreadCount = conversations.reduce(
    (sum, conversation) => sum + Number(conversation?.unread_count || 0),
    0,
  );
  chatNotificationState.unreadConversationCount = conversations.filter(
    (conversation) => Number(conversation?.unread_count || 0) > 0,
  ).length;
}

function findConversationIndex(conversationId) {
  return chatNotificationState.conversations.findIndex(
    (conversation) => Number(conversation?.id) === Number(conversationId),
  );
}

function getConversation(conversationId) {
  return (
    chatNotificationState.conversations.find(
      (conversation) => Number(conversation?.id) === Number(conversationId),
    ) || null
  );
}

function extractConversationUserId(conversation) {
  return Number(conversation?.user?.id || conversation?.user_id || 0);
}

function getConversationDisplayName(conversation) {
  return (
    conversation?.user?.profile?.name ||
    conversation?.user?.full_name ||
    conversation?.user?.name ||
    conversation?.user?.username ||
    conversation?.user?.email ||
    (extractConversationUserId(conversation)
      ? `Khách hàng #${extractConversationUserId(conversation)}`
      : "Khách hàng")
  );
}

function formatToastPreview(message = {}) {
  const content = String(message?.content || "").trim();
  if (content) return content;

  const mediaItems = Array.isArray(message?.media_items)
    ? message.media_items
    : [];
  if (mediaItems.length === 1) {
    return "Đã gửi 1 tệp đính kèm.";
  }
  if (mediaItems.length > 1) {
    return `Đã gửi ${mediaItems.length} tệp đính kèm.`;
  }

  return "Bạn có tin nhắn mới.";
}

function shouldSuppressToast(conversationId) {
  return (
    chatNotificationState.isChatPageActive &&
    isPageVisible() &&
    Number(chatNotificationState.activeConversationId || 0) ===
      Number(conversationId || 0)
  );
}

function rememberNotifiedMessage(conversationId, messageId) {
  const normalizedConversationId = Number(conversationId || 0);
  const normalizedMessageId = Number(messageId || 0);
  if (!normalizedConversationId || !normalizedMessageId) return;
  notifiedMessageIds.set(normalizedConversationId, normalizedMessageId);
}

function hasNotifiedMessage(conversationId, messageId) {
  return (
    Number(notifiedMessageIds.get(Number(conversationId || 0)) || 0) >=
    Number(messageId || 0)
  );
}

function clearToastTimer(toastId) {
  const timerId = toastTimers.get(toastId);
  if (!timerId) return;
  window.clearTimeout(timerId);
  toastTimers.delete(toastId);
}

function dismissChatToast(toastId) {
  const index = chatNotificationState.toasts.findIndex(
    (toast) => toast.id === toastId,
  );
  if (index >= 0) {
    chatNotificationState.toasts.splice(index, 1);
  }
  clearToastTimer(toastId);
}

function scheduleToastDismiss(toastId) {
  clearToastTimer(toastId);

  const timerId = window.setTimeout(() => {
    if (!isPageVisible()) {
      scheduleToastDismiss(toastId);
      return;
    }
    dismissChatToast(toastId);
  }, TOAST_LIFETIME_MS);

  toastTimers.set(toastId, timerId);
}

function trimToastStack() {
  while (chatNotificationState.toasts.length > MAX_TOASTS) {
    const removed = chatNotificationState.toasts.pop();
    if (removed) {
      clearToastTimer(removed.id);
    }
  }
}

function enqueueToast({ conversation, message }) {
  const normalizedConversation = normalizeConversation(conversation);
  const conversationId = Number(normalizedConversation?.id || 0);
  const messageId = Number(message?.id || 0);

  if (
    !conversationId ||
    !messageId ||
    hasNotifiedMessage(conversationId, messageId)
  ) {
    return;
  }

  rememberNotifiedMessage(conversationId, messageId);

  const nextTitle = `${getConversationDisplayName(normalizedConversation)} vừa gửi tin nhắn`;
  const nextBody = formatToastPreview(message);
  const existingToast = chatNotificationState.toasts.find(
    (toast) => Number(toast.conversationId) === conversationId,
  );

  if (existingToast) {
    existingToast.userId = extractConversationUserId(normalizedConversation);
    existingToast.messageId = messageId;
    existingToast.title = nextTitle;
    existingToast.body = nextBody;
    existingToast.createdAt = new Date().toISOString();
    scheduleToastDismiss(existingToast.id);
    return;
  }

  const toast = {
    id: `chat-toast-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    conversationId,
    userId: extractConversationUserId(normalizedConversation) || null,
    messageId,
    title: nextTitle,
    body: nextBody,
    createdAt: new Date().toISOString(),
  };

  chatNotificationState.toasts.unshift(toast);
  trimToastStack();
  scheduleToastDismiss(toast.id);
}

function publishChatEvent(payload) {
  chatNotificationState.lastEvent = payload;
  chatNotificationState.lastEventTick += 1;
}

function upsertConversation(conversation, { moveToTop = false } = {}) {
  const normalized = normalizeConversation(conversation);
  const index = findConversationIndex(normalized.id);

  if (index >= 0) {
    chatNotificationState.conversations.splice(index, 1, {
      ...chatNotificationState.conversations[index],
      ...normalized,
    });
  } else {
    chatNotificationState.conversations.push(normalized);
  }

  if (moveToTop) {
    const currentIndex = findConversationIndex(normalized.id);
    if (currentIndex > 0) {
      const [item] = chatNotificationState.conversations.splice(
        currentIndex,
        1,
      );
      chatNotificationState.conversations.unshift(item);
      syncUnreadTotals();
      return;
    }
  }

  sortConversations();
  syncUnreadTotals();
}

function applyReadPayload(
  actorUserId,
  payload = {},
  conversationSnapshot = null,
) {
  if (conversationSnapshot) {
    upsertConversation(conversationSnapshot, { moveToTop: true });
    rememberNotifiedMessage(
      conversationSnapshot?.id,
      conversationSnapshot?.last_message_id,
    );
    return;
  }

  const index = findConversationIndex(payload?.conversation_id);
  if (index < 0) return;

  const current = chatNotificationState.conversations[index];
  const updated = { ...current };

  if (Number(actorUserId) === readCurrentAdminId()) {
    updated.last_read_admin_message_id = payload.last_read_message_id;
    updated.unread_count = payload.unread_count ?? 0;
    rememberNotifiedMessage(updated.id, updated.last_message_id);
  } else {
    updated.last_read_user_message_id = payload.last_read_message_id;
  }

  chatNotificationState.conversations.splice(index, 1, updated);
  syncUnreadTotals();
}

async function handleIncomingMessage(payload = {}) {
  const current = getConversation(payload.conversation_id);
  const baseConversation = normalizeConversation(
    payload.conversation ||
      current || {
        id: payload.conversation_id,
        user_id: payload?.data?.user_id,
      },
  );
  const incoming = Number(payload?.data?.user_id || 0) !== readCurrentAdminId();
  const nextConversation = {
    ...baseConversation,
    last_message_id:
      payload?.data?.id || baseConversation?.last_message_id || null,
    last_message_at:
      payload?.data?.created_at || baseConversation?.last_message_at || null,
    unread_count: incoming
      ? shouldSuppressToast(baseConversation.id)
        ? 0
        : Number(baseConversation?.unread_count || 0) + 1
      : Number(baseConversation?.unread_count || 0),
  };

  upsertConversation(nextConversation, { moveToTop: true });

  if (!incoming) {
    rememberNotifiedMessage(
      nextConversation.id,
      nextConversation.last_message_id,
    );
    return;
  }

  if (shouldSuppressToast(nextConversation.id)) {
    rememberNotifiedMessage(
      nextConversation.id,
      nextConversation.last_message_id,
    );
    return;
  }

  enqueueToast({
    conversation: nextConversation,
    message: payload.data,
  });
}

function buildAdminSocketUrl() {
  const token = readAccessToken();
  const baseUrl = import.meta.env.VITE_API_BASE_URL;
  if (!token || !baseUrl) return "";

  const url = new URL(baseUrl);
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  url.pathname = `${url.pathname.replace(/\/$/, "")}/chat/ws/admin`;
  url.searchParams.set("token", token);
  return url.toString();
}

function clearReconnectTimer() {
  if (!reconnectTimer) return;
  window.clearTimeout(reconnectTimer);
  reconnectTimer = null;
}

function scheduleReconnect() {
  if (!chatNotificationState.started || reconnectTimer) return;

  reconnectTimer = window.setTimeout(() => {
    reconnectTimer = null;
    connectAdminSocket();
  }, RECONNECT_DELAY_MS);
}

function disconnectAdminSocket() {
  clearReconnectTimer();
  if (!adminSocket) return;

  const socket = adminSocket;
  adminSocket = null;
  chatNotificationState.socketConnected = false;
  socket.onopen = null;
  socket.onmessage = null;
  socket.onerror = null;
  socket.onclose = null;

  try {
    socket.close();
  } catch (_) {
    // Ignore socket shutdown errors during cleanup.
  }
}

function handleAdminSocketMessage(rawEvent) {
  try {
    const payload = JSON.parse(rawEvent.data);

    if (payload.event === "connected" || payload.event === "pong") {
      return;
    }

    if (payload.event === "message:new" && payload.data) {
      publishChatEvent(payload);
      void handleIncomingMessage(payload);
      return;
    }

    if (payload.event === "message:read" && payload.data) {
      publishChatEvent(payload);
      applyReadPayload(payload.user_id, payload.data, payload.conversation);
      return;
    }

    if (payload.event === "message:recalled" && payload.data) {
      publishChatEvent(payload);
      if (payload.conversation) {
        upsertConversation(payload.conversation);
      }
      return;
    }

    if (payload.event === "conversation:upsert" && payload.conversation) {
      publishChatEvent(payload);
      upsertConversation(payload.conversation, { moveToTop: true });
    }
  } catch (_) {
    // Ignore malformed payloads on the global admin socket.
  }
}

function connectAdminSocket() {
  if (!chatNotificationState.started || adminSocket) return;

  const socketUrl = buildAdminSocketUrl();
  if (!socketUrl) return;

  const socket = new WebSocket(socketUrl);
  adminSocket = socket;
  clearReconnectTimer();

  socket.onopen = () => {
    chatNotificationState.socketConnected = true;
    void refreshChatNotifications();
  };
  socket.onmessage = handleAdminSocketMessage;
  socket.onerror = () => {
    // Reconnect is handled in onclose.
  };
  socket.onclose = () => {
    if (adminSocket === socket) {
      adminSocket = null;
    }
    chatNotificationState.socketConnected = false;
    scheduleReconnect();
  };
}

async function refreshChatNotifications() {
  if (!chatNotificationState.started) return [];
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    try {
      const items = await ChatService.getConversations();
      const nextConversations = Array.isArray(items)
        ? items.map(normalizeConversation)
        : [];

      chatNotificationState.conversations = nextConversations;
      sortConversations();
      syncUnreadTotals();
      chatNotificationState.lastSyncedAt = new Date().toISOString();

      nextConversations.forEach((conversation) => {
        rememberNotifiedMessage(
          conversation?.id,
          conversation?.last_message_id,
        );
      });

      return nextConversations;
    } catch (_) {
      return chatNotificationState.conversations;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

export async function startChatNotifications() {
  if (chatNotificationState.started) {
    return refreshChatNotifications();
  }

  chatNotificationState.started = true;
  await refreshChatNotifications();
  connectAdminSocket();
  return chatNotificationState.conversations;
}

export function stopChatNotifications() {
  chatNotificationState.started = false;
  chatNotificationState.socketConnected = false;
  chatNotificationState.isChatPageActive = false;
  chatNotificationState.activeConversationId = null;
  chatNotificationState.conversations = [];
  chatNotificationState.totalUnreadCount = 0;
  chatNotificationState.unreadConversationCount = 0;
  chatNotificationState.toasts = [];
  chatNotificationState.lastSyncedAt = null;
  chatNotificationState.lastEvent = null;
  chatNotificationState.lastEventTick = 0;

  disconnectAdminSocket();
  refreshPromise = null;
  notifiedMessageIds.clear();

  [...toastTimers.keys()].forEach((toastId) => {
    clearToastTimer(toastId);
  });
}

export function setChatPageActive(isActive) {
  chatNotificationState.isChatPageActive = Boolean(isActive);
  if (!isActive) {
    chatNotificationState.activeConversationId = null;
  }
}

export function setActiveChatConversation(conversationId) {
  chatNotificationState.activeConversationId =
    Number(conversationId || 0) || null;

  const index = findConversationIndex(conversationId);
  if (index >= 0) {
    const current = chatNotificationState.conversations[index];
    chatNotificationState.conversations.splice(index, 1, {
      ...current,
      unread_count: 0,
    });
    syncUnreadTotals();
    rememberNotifiedMessage(current.id, current.last_message_id);
  }
}

export function clearActiveChatConversation() {
  chatNotificationState.activeConversationId = null;
}

export function formatUnreadBadge(value) {
  const normalized = Number(value || 0);
  if (!normalized) return "";
  return normalized > 99 ? "99+" : String(normalized);
}

export { dismissChatToast };

