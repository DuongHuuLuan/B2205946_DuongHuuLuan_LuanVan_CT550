<template>
  <header class="topbar">
    <div class="container-fluid d-flex align-items-center justify-content-between">
      <div class="header-left d-flex align-items-center gap-2">
        <button class="icon-btn d-lg-none" @click="emit('toggleSidebar')">
          <i class="fa-solid fa-bars"></i>
        </button>
        <button class="icon-btn d-none d-lg-inline-flex" aria-label="Menu">
          <i class="fa-solid fa-bars"></i>
        </button>
        <button class="icon-btn" aria-label="Search">
          <i class="fa-solid fa-magnifying-glass"></i>
        </button>
      </div>

      <div class="header-right d-flex align-items-center gap-2">
        <button class="icon-btn" :class="{ 'has-dot': notificationCount > 0 }" aria-label="Notifications">
          <i class="fa-regular fa-bell"></i>
        </button>
        <button class="icon-btn" :class="{ 'has-badge': messageCount > 0 }" aria-label="Messages">
          <i class="fa-regular fa-envelope"></i>
        </button>
        <button class="icon-btn" :class="{ 'has-dot': alertCount > 0 }" aria-label="Alerts">
          <i class="fa-regular fa-circle-question"></i>
        </button>

        <div class="profile d-flex align-items-center gap-2">
          <div class="avatar">
            <img v-if="avatarUrl" :src="avatarUrl" alt="avatar" />
            <span v-else>{{ initials }}</span>
          </div>
          <span class="name">{{ displayName }}</span>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import AuthService from "@/services/auth.service";

const emit = defineEmits(["toggleSidebar"]);

const user = ref(null);
const notificationCount = ref(0);
const messageCount = ref(0);
const alertCount = ref(0);

function readCachedUser() {
  try {
    const raw = localStorage.getItem("currentUser");
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function getDisplayName(value) {
  return (
    value?.full_name ||
    value?.name ||
    value?.username ||
    value?.email ||
    "Admin"
  );
}

function getInitials(value) {
  const name = getDisplayName(value);
  const parts = String(name).trim().split(/\s+/).slice(0, 2);
  return parts.map((p) => p[0]?.toUpperCase()).join("") || "AD";
}

const displayName = computed(() => getDisplayName(user.value));
const initials = computed(() => getInitials(user.value));
const avatarUrl = computed(
  () =>
    user.value?.avatar_url ||
    user.value?.avatar ||
    user.value?.photo_url ||
    user.value?.photo ||
    ""
);

async function fetchProfile() {
  const cached = readCachedUser();
  if (cached) user.value = cached;

  if (!AuthService.isLoggin()) return;

  try {
    const res = await AuthService.me();
    const nextUser = res?.user ?? res?.data ?? res;
    if (nextUser) {
      user.value = nextUser;
      localStorage.setItem("currentUser", JSON.stringify(nextUser));
    }
  } catch {
  }
}

onMounted(fetchProfile);
</script>

<style scoped>
.topbar {
  height: 64px;
  background: var(--main-extra-bg);
  border-bottom: 1px solid var(--border-color);
  color: var(--font-color);
}

.topbar .container-fluid {
  height: 100%;
  padding: 0 1rem;
}

.icon-btn {
  width: 36px;
  height: 36px;
  border-radius: 999px;
  border: 1px solid var(--border-color);
  background: var(--main-extra-bg);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--font-extra-color);
  position: relative;
  transition: all 0.2s ease;
}

.icon-btn:hover {
  border-color: color-mix(in srgb, var(--main-color) 35%, var(--border-color));
  color: var(--font-color);
  box-shadow: 0 6px 14px var(--shadow-color);
}

.icon-btn.has-dot::after {
  content: "";
  position: absolute;
  top: 6px;
  right: 7px;
  width: 7px;
  height: 7px;
  background: #ff6b6b;
  border-radius: 999px;
  box-shadow: 0 0 0 2px var(--main-extra-bg);
}

.icon-btn.has-badge::after {
  content: "3";
  position: absolute;
  top: -4px;
  right: -2px;
  min-width: 16px;
  height: 16px;
  padding: 0 3px;
  background: #ff6b6b;
  color: #fff;
  font-size: 0.65rem;
  font-weight: 600;
  line-height: 16px;
  text-align: center;
  border-radius: 999px;
  box-shadow: 0 0 0 2px var(--main-extra-bg);
}

.profile {
  padding-left: 0.5rem;
  border-left: 1px solid var(--border-color);
}

.avatar {
  width: 34px;
  height: 34px;
  border-radius: 999px;
  background: color-mix(in srgb, var(--main-color) 35%, var(--main-extra-bg));
  color: var(--dark);
  font-weight: 600;
  font-size: 0.8rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid color-mix(in srgb, var(--main-color) 55%, var(--border-color));
  overflow: hidden;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.name {
  font-weight: 600;
  color: var(--font-color);
  font-size: 0.9rem;
}
</style>
