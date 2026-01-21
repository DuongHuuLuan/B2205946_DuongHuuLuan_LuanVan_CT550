<template>
  <header class="topbar">
    <div class="container-fluid py-2 py-lg-3 d-flex align-items-center gap-2">
      <button class="btn btn-outline-secondary d-lg-none" @click="$emit('toggleSidebar')">
        <i class="fa-solid fa-bars"></i>
      </button>

      <div class="fw-semibold">
        <span class="accent">RoyalStore</span> Admin
      </div>

      <div class="ms-auto d-flex align-items-center gap-2">
        <div class="input-group d-none d-md-flex" style="max-width: 340px">
          <span class="input-group-text bg-transparent">
            <i class="fa-solid fa-magnifying-glass"></i>
          </span>
          <input class="form-control bg-transparent" placeholder="Search (sau này)" />
        </div>

        <button class="btn btn-accent">
          <i class="fa-solid fa-plus me-1"></i> New
        </button>
      </div>
    </div>
  </header>
</template>

<style scoped>
.topbar {
  background: var(--main-extra-bg);
  border-bottom: 1px solid var(--border-color);
  color: var(--font-color);
}

.accent {
  color: var(--main-color);
}

.btn-accent {
  background: var(--main-color);
  border: 1px solid var(--hover-border-color);
  color: var(--dark);
}

.btn-accent:hover {
  filter: var(--brightness);
}
</style>
