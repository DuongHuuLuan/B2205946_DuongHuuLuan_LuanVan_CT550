<template>
  <Teleport to="body">
    <div v-if="toasts.length" class="chat-toast-stack" role="region" aria-label="Thông báo tin nhắn">
      <article v-for="toast in toasts" :key="toast.id" class="chat-toast" role="button" tabindex="0"
        @click="openToast(toast)" @keydown.enter.prevent="openToast(toast)" @keydown.space.prevent="openToast(toast)">
        <div class="chat-toast__accent"></div>
        <div class="chat-toast__content">
          <div class="chat-toast__top">
            <div class="chat-toast__title">{{ toast.title }}</div>
            <button type="button" class="chat-toast__close" aria-label="Đóng thông báo"
              @click.stop="dismissChatToast(toast.id)">
              <i class="fa-solid fa-xmark"></i>
            </button>
          </div>
          <div class="chat-toast__body">{{ toast.body }}</div>
          <div class="chat-toast__time">{{ formatTime(toast.createdAt) }}</div>
        </div>
      </article>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from "vue";
import { useRouter } from "vue-router";
import {
  chatNotificationState,
  dismissChatToast,
} from "@/state/chat-notification.state";

const router = useRouter();
const toasts = computed(() => chatNotificationState.toasts);

function formatTime(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function openToast(toast) {
  dismissChatToast(toast.id);
  if (!toast?.userId) return;
  router.push({ name: "chat", query: { userId: toast.userId } }).catch(() => { });
}
</script>

<style scoped>
.chat-toast-stack {
  position: fixed;
  top: 5rem;
  right: 1rem;
  z-index: 1100;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  width: min(360px, calc(100vw - 2rem));
}

.chat-toast {
  display: grid;
  grid-template-columns: 4px minmax(0, 1fr);
  border: 1px solid var(--border-color);
  border-radius: 1rem;
  overflow: hidden;
  background: rgba(20, 29, 41, 0.96);
  color: #f7fafc;
  box-shadow: 0 18px 40px rgba(15, 23, 42, 0.28);
  cursor: pointer;
}

.chat-toast__accent {
  background: linear-gradient(180deg, #38bdf8, #22c55e);
}

.chat-toast__content {
  padding: 0.9rem 1rem 0.85rem;
  min-width: 0;
}

.chat-toast__top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.75rem;
}

.chat-toast__title {
  font-weight: 700;
  line-height: 1.35;
}

.chat-toast__body {
  margin-top: 0.35rem;
  color: rgba(241, 245, 249, 0.82);
  font-size: 0.92rem;
  line-height: 1.45;
  word-break: break-word;
}

.chat-toast__time {
  margin-top: 0.5rem;
  font-size: 0.78rem;
  color: rgba(191, 219, 254, 0.82);
}

.chat-toast__close {
  border: 0;
  background: transparent;
  color: rgba(241, 245, 249, 0.72);
  width: 28px;
  height: 28px;
  border-radius: 999px;
  flex: 0 0 auto;
}

.chat-toast__close:hover {
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
}

@media (max-width: 767.98px) {
  .chat-toast-stack {
    top: auto;
    bottom: 1rem;
  }
}
</style>
