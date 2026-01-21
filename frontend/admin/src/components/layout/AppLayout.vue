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
  </div>
</template>

<script setup>
import { ref } from "vue";
import AppHeader from "@/components/layout/AppHeader.vue";
import AppSidebar from "@/components/layout/AppSidebar.vue";
import AppFooter from "@/components/layout/AppFooter.vue";

const collapsed = ref(false);
</script>

<style scoped>
.app-shell {
  background: var(--main-bg);
  color: var(--font-color);
  min-height: 100vh;
}
</style>
