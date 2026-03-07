<template>
  <div class="app-shell">
    <div class="d-flex">
      <AppSidebar :collapsed="collapsed" @toggle="collapsed = !collapsed" />

      <div class="flex-grow-1">
        <AppHeader @toggleSidebar="collapsed = !collapsed" />
        <main class="container-fluid py-3 py-lg-4">
          <router-view />
        </main>
        <AppFooter />
      </div>
    </div>
    <ChatToastStack />
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";
import ChatToastStack from "@/components/chat/ChatToastStack.vue";
import AppHeader from "@/components/layout/AppHeader.vue";
import AppSidebar from "@/components/layout/AppSidebar.vue";
import AppFooter from "@/components/layout/AppFooter.vue";
import {
  startChatNotifications,
  stopChatNotifications,
} from "@/state/chat-notification.state";

const collapsed = ref(false);

onMounted(() => {
  void startChatNotifications();
});

onBeforeUnmount(() => {
  stopChatNotifications();
});
</script>

<style scoped>
.app-shell {
  background: var(--main-bg);
  color: var(--font-color);
  min-height: 100vh;
}
</style>
