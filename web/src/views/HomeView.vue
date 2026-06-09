<script setup lang="ts"></script>

<template>
  <!-- ── Navbar ── -->
  <nav class="fixed top-0 left-0 right-0 z-50 bg-bone border-b border-hairline">
    <div class="max-w-[var(--container)] mx-auto flex items-center h-[var(--topbar-h)] px-6">
      <img src="/logo.svg" alt="CO" class="w-9 h-9 rounded-lg" />
      <span class="ml-3 font-serif text-lg text-ink-strong tracking-tight">Chosen Object</span>
    </div>
  </nav>

  <main>
    <!-- ── Hero ── -->
    <section
      class="min-h-screen flex flex-col items-center justify-center px-6 pt-[var(--topbar-h)]"
    >
      <div class="text-center max-w-2xl">
        <!-- Nº ornament -->
        <p class="font-serif italic text-gold text-xl mb-4 tracking-wide">Nº</p>

        <h1 class="font-serif text-5xl sm:text-6xl md:text-7xl text-ink-strong leading-tight mb-6">
          Chosen Object
        </h1>

        <p class="font-serif italic text-ink-soft text-lg sm:text-xl leading-relaxed mb-12">
          Curated craft, collected with care.
        </p>

        <!-- Store buttons -->
        <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
          <!-- App Store -->
          <a
            href="#"
            class="inline-flex items-center gap-3 border border-ink rounded-lg px-6 py-3 hover:bg-ink hover:text-bone transition-colors duration-300 group"
          >
            <svg class="w-7 h-7" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"
              />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-70">Download on the</div>
              <div class="text-sm font-medium leading-tight">App Store</div>
            </div>
          </a>

          <!-- Google Play -->
          <a
            href="#"
            class="inline-flex items-center gap-3 border border-ink rounded-lg px-6 py-3 hover:bg-ink hover:text-bone transition-colors duration-300 group"
          >
            <svg class="w-7 h-7" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M3.61 1.814L13.793 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .61-.92zm10.895 9.476l2.56-2.56L5.574.587l8.93 10.703zm-8.93 10.703l11.49-6.143-2.56-2.56-8.93 8.703zM21.408 10.9l-2.764-1.478-2.81 2.578 2.81 2.578 2.764-1.478a1.003 1.003 0 0 0 0-1.8v.6z"
              />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-70">Get it on</div>
              <div class="text-sm font-medium leading-tight">Google Play</div>
            </div>
          </a>
        </div>
      </div>

      <!-- Scroll hint -->
      <div class="absolute bottom-10 animate-bounce">
        <svg
          class="w-5 h-5 text-muted"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </section>

    <!-- ── Features ── -->
    <section class="py-24 px-6">
      <div
        class="max-w-[var(--container)] mx-auto grid grid-cols-1 md:grid-cols-3 gap-16 md:gap-12"
      >
        <!-- Feature 1 -->
        <div class="text-center">
          <div
            class="w-14 h-14 mx-auto mb-6 rounded-full bg-surface border border-hairline flex items-center justify-center"
          >
            <svg
              class="w-6 h-6 text-ink-soft"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
          </div>
          <h3 class="font-serif text-xl text-ink-strong mb-3">Discover studios</h3>
          <p class="text-muted text-sm leading-relaxed">
            Browse curated artisan studios. Ceramics, sculpture, furniture, textiles — every
            discipline, one place.
          </p>
        </div>

        <!-- Feature 2 -->
        <div class="text-center">
          <div
            class="w-14 h-14 mx-auto mb-6 rounded-full bg-surface border border-hairline flex items-center justify-center"
          >
            <svg
              class="w-6 h-6 text-ink-soft"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z"
              />
            </svg>
          </div>
          <h3 class="font-serif text-xl text-ink-strong mb-3">Collect pieces</h3>
          <p class="text-muted text-sm leading-relaxed">
            Save and purchase unique handmade works. Build your personal collection of one-of-a-kind
            objects.
          </p>
        </div>

        <!-- Feature 3 -->
        <div class="text-center">
          <div
            class="w-14 h-14 mx-auto mb-6 rounded-full bg-surface border border-hairline flex items-center justify-center"
          >
            <svg
              class="w-6 h-6 text-ink-soft"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5"
              />
            </svg>
          </div>
          <h3 class="font-serif text-xl text-ink-strong mb-3">Rent or buy</h3>
          <p class="text-muted text-sm leading-relaxed">
            Flexible options for every collector. Purchase outright or rent pieces for your space,
            your way.
          </p>
        </div>
      </div>
    </section>

    <!-- ── Banner ── -->
    <section class="bg-ink py-20 px-6">
      <div class="max-w-2xl mx-auto text-center">
        <p class="font-serif italic text-bone text-2xl sm:text-3xl leading-snug">
          &ldquo;Every object tells the story of the hands that made it.&rdquo;
        </p>
      </div>
    </section>

    <!-- ── Second CTA ── -->
    <section class="py-24 px-6">
      <div class="max-w-lg mx-auto text-center">
        <p class="font-serif italic text-gold text-lg mb-2">Nº</p>
        <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong mb-4">Start collecting</h2>
        <p class="text-muted text-sm mb-10">
          Download the app and explore a world of handmade craft.
        </p>
        <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href="#"
            class="inline-flex items-center gap-3 bg-ink text-bone rounded-lg px-6 py-3 hover:bg-ink-soft transition-colors duration-300"
          >
            <svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"
              />
            </svg>
            <span class="text-sm font-medium">App Store</span>
          </a>
          <a
            href="#"
            class="inline-flex items-center gap-3 bg-ink text-bone rounded-lg px-6 py-3 hover:bg-ink-soft transition-colors duration-300"
          >
            <svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M3.61 1.814L13.793 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .61-.92zm10.895 9.476l2.56-2.56L5.574.587l8.93 10.703zm-8.93 10.703l11.49-6.143-2.56-2.56-8.93 8.703zM21.408 10.9l-2.764-1.478-2.81 2.578 2.81 2.578 2.764-1.478a1.003 1.003 0 0 0 0-1.8v.6z"
              />
            </svg>
            <span class="text-sm font-medium">Google Play</span>
          </a>
        </div>
      </div>
    </section>

    <!-- ── Footer ── -->
    <footer class="border-t border-hairline py-10 px-6">
      <div class="max-w-[var(--container)] mx-auto flex flex-col items-center gap-3">
        <img src="/logo.svg" alt="CO" class="w-8 h-8 rounded-md opacity-60" />
        <p class="text-muted-2 text-xs">&copy; 2026 Chosen Object. All rights reserved.</p>
      </div>
    </footer>
  </main>
</template>
