<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'

const TOTAL_SECTIONS = 5 // 0=hero, 1=about, 2=howItWorks, 3=downloadCTA, 4=footer
const currentIndex = ref(0)
let isScrolling = false
const heroVideo = ref<HTMLVideoElement | null>(null)

// Loading state — wait for all videos
const loading = ref(true)
const loadingReady = ref(false)
const videosLoaded = ref(0)
const TOTAL_VIDEOS = 4 // 1.mp4, 2.mp4, 3.mp4, 4.mp4

function onVideoReady() {
  videosLoaded.value++
  if (videosLoaded.value >= TOTAL_VIDEOS) {
    // All videos ready — fade out loader
    setTimeout(() => {
      loadingReady.value = true
      setTimeout(() => { loading.value = false }, 600)
    }, 300)
  }
}

// Login modal
const showLogin = ref(false)
const loginReady = ref(false)
const loginEmail = ref('')
const loginPassword = ref('')
const showPassword = ref(false)
const loginLoading = ref(false)
const loginError = ref('')

function openLogin() {
  showLogin.value = true
  nextTick(() => { loginReady.value = true })
}

function closeLogin() {
  loginReady.value = false
  setTimeout(() => {
    showLogin.value = false
    loginError.value = ''
  }, 300)
}

async function handleLogin() {
  if (!loginEmail.value || !loginPassword.value) {
    loginError.value = 'Please fill in all fields.'
    return
  }
  loginLoading.value = true
  loginError.value = ''
  // TODO: integrate with API
  setTimeout(() => {
    loginLoading.value = false
    loginError.value = 'Login is only available in the app.'
  }, 1200)
}

// Section 1 staggered entrance — each element animates individually
const S1_COUNT = 8
const s1Visible = ref<boolean[]>(Array(S1_COUNT).fill(false))

watch(currentIndex, (val) => {
  if (val === 1) {
    s1Visible.value = Array(S1_COUNT).fill(false)
    for (let i = 0; i < S1_COUNT; i++) {
      setTimeout(() => {
        s1Visible.value = [...s1Visible.value]
        s1Visible.value[i] = true
      }, 150 + i * 100)
    }
  } else {
    s1Visible.value = Array(S1_COUNT).fill(false)
  }
})

function s1Style(idx: number, distance = 50) {
  return {
    transform: s1Visible.value[idx] ? 'translateY(0)' : `translateY(${distance}px)`,
    opacity: s1Visible.value[idx] ? 1 : 0,
    transition: 'all 700ms cubic-bezier(0.16, 1, 0.3, 1)',
  }
}

// Line width animation for section 1 divider
const s1LineWidth = computed(() => s1Visible.value[2] ? '80px' : '0px')

// Section 2 staggered entrance
const S2_COUNT = 6
const s2Visible = ref<boolean[]>(Array(S2_COUNT).fill(false))

watch(currentIndex, (val) => {
  if (val === 2) {
    s2Visible.value = Array(S2_COUNT).fill(false)
    for (let i = 0; i < S2_COUNT; i++) {
      setTimeout(() => {
        s2Visible.value = [...s2Visible.value]
        s2Visible.value[i] = true
      }, 200 + i * 150)
    }
  } else {
    s2Visible.value = Array(S2_COUNT).fill(false)
  }
})

function s2Style(idx: number, distance = 50) {
  return {
    transform: s2Visible.value[idx] ? 'translateY(0)' : `translateY(${distance}px)`,
    opacity: s2Visible.value[idx] ? 1 : 0,
    transition: 'all 700ms cubic-bezier(0.16, 1, 0.3, 1)',
  }
}

function goToSection(index: number) {
  if (index < 0 || index >= TOTAL_SECTIONS || index === currentIndex.value) return
  if (isScrolling) return
  isScrolling = true
  currentIndex.value = index
  setTimeout(() => { isScrolling = false }, 800)
}

function sectionStyle(idx: number) {
  return {
    position: 'fixed' as const,
    top: '0',
    left: '0',
    width: '100%',
    height: '100%',
    zIndex: idx + 10,
    transform: idx <= currentIndex.value ? 'translateY(0%) translateZ(0)' : 'translateY(100%) translateZ(0)',
    transition: 'transform 700ms cubic-bezier(0.16, 1, 0.3, 1)',
    overflow: 'hidden' as const,
    backfaceVisibility: 'hidden' as const,
    willChange: 'transform',
  }
}

// Dot navigation
const dots = computed(() =>
  Array.from({ length: TOTAL_SECTIONS }, (_, i) => i === currentIndex.value)
)

// Wheel
function handleWheel(e: WheelEvent) {
  e.preventDefault()
  if (isScrolling || showLogin.value || loading.value) return
  if (Math.abs(e.deltaY) < 15) return
  goToSection(currentIndex.value + (e.deltaY > 0 ? 1 : -1))
}

// Keyboard
function handleKeyDown(e: KeyboardEvent) {
  if (showLogin.value) {
    if (e.key === 'Escape') closeLogin()
    return
  }
  if (isScrolling) return
  if (e.key === 'ArrowDown' || e.key === ' ') { e.preventDefault(); goToSection(currentIndex.value + 1) }
  if (e.key === 'ArrowUp') { e.preventDefault(); goToSection(currentIndex.value - 1) }
}

// Touch
let touchStartY = 0
let touchStartT = 0
function handleTouchStart(e: TouchEvent) {
  touchStartY = e.touches[0].clientY
  touchStartT = Date.now()
}
function handleTouchEnd(e: TouchEvent) {
  const dy = touchStartY - e.changedTouches[0].clientY
  const dt = Date.now() - touchStartT
  if (dt > 900 || Math.abs(dy) < 50) return
  goToSection(currentIndex.value + (dy > 0 ? 1 : -1))
}

// Resume videos when tab becomes visible again
function handleVisibility() {
  if (document.visibilityState === 'visible') {
    document.querySelectorAll('.landing-root video').forEach((v) => {
      const video = v as HTMLVideoElement
      if (video.paused) {
        video.currentTime = video.currentTime
        video.play().catch(() => {})
      }
    })
  }
}

onMounted(() => {
  document.body.style.overflow = 'hidden'
  document.documentElement.style.overflow = 'hidden'
  window.addEventListener('wheel', handleWheel, { passive: false })
  window.addEventListener('keydown', handleKeyDown)
  window.addEventListener('touchstart', handleTouchStart, { passive: true })
  window.addEventListener('touchend', handleTouchEnd, { passive: true })
  document.addEventListener('visibilitychange', handleVisibility)

  // Force play hero video
  if (heroVideo.value) {
    heroVideo.value.play().catch(() => {})
  }
})

onUnmounted(() => {
  document.body.style.overflow = ''
  document.documentElement.style.overflow = ''
  window.removeEventListener('wheel', handleWheel)
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('touchstart', handleTouchStart)
  window.removeEventListener('touchend', handleTouchEnd)
  document.removeEventListener('visibilitychange', handleVisibility)
})
</script>

<template>
  <div class="landing-root">

    <!-- ── Loading screen ── -->
    <Teleport to="body">
      <div
        v-if="loading"
        class="fixed inset-0 z-[200] flex flex-col items-center justify-center bg-surface transition-opacity duration-500"
        :style="{ opacity: loadingReady ? 0 : 1 }"
      >
        <p class="font-serif text-xl text-ink-strong mb-8">Chosen Object</p>
        <div class="w-40 h-0.5 bg-hairline rounded-full overflow-hidden">
          <div
            class="h-full bg-ink/40 rounded-full transition-all duration-500 ease-out"
            :style="{ width: (videosLoaded / TOTAL_VIDEOS * 100) + '%' }"
          ></div>
        </div>
      </div>
    </Teleport>

    <!-- ── Navbar (always on top) ── -->
    <nav
      class="fixed top-6 left-8 right-8 z-50 transition-all duration-500"
      :style="{ opacity: currentIndex === TOTAL_SECTIONS - 1 ? 0 : 1, pointerEvents: currentIndex === TOTAL_SECTIONS - 1 ? 'none' : 'auto' }"
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <img src="/logo.svg" alt="CO" class="w-12 h-12 rounded-lg" />
          <span
            class="ml-4 font-serif text-2xl tracking-tight transition-colors duration-500"
            :class="currentIndex === 0 ? 'text-ink-strong' : 'text-white'"
          >Chosen Object</span>
        </div>
        <button
          @click="openLogin"
          class="px-5 py-2 rounded-full text-sm font-medium transition-all duration-500 border cursor-pointer"
          :class="currentIndex === 0
            ? 'border-ink/20 text-ink-strong hover:bg-ink hover:text-bone'
            : 'border-white/20 text-white hover:bg-white hover:text-ink'"
        >Log in</button>
      </div>
    </nav>

    <!-- ── Dot navigation ── -->
    <div class="fixed right-8 top-1/2 -translate-y-1/2 z-50 flex flex-col gap-5">
      <button
        v-for="(active, i) in dots"
        :key="i"
        class="w-6 h-6 rounded-full transition-all duration-300"
        :class="[
          currentIndex === 0
            ? (active ? 'bg-ink scale-110' : 'bg-transparent border-2 border-ink/40 hover:border-ink')
            : (active ? 'bg-white scale-110' : 'bg-transparent border-2 border-white/50 hover:border-white')
        ]"
        @click="goToSection(i)"
      />
    </div>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Section 0 — Hero                                   -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section :style="sectionStyle(0)" class="flex flex-col justify-center px-6 md:px-16 lg:px-24">
      <!-- Video background -->
      <video
        ref="heroVideo"
        class="absolute inset-0 w-full h-full object-cover"
        src="/landing_videos/1.mp4"
        autoplay
        loop
        muted
        playsinline
        preload="auto"
        disablePictureInPicture
        @canplaythrough.once="onVideoReady"
      ></video>

      <div class="text-center md:text-left max-w-3xl relative z-10">
        <p class="font-serif italic text-ink/60 text-xl mb-6 tracking-widest">N&ordm;</p>
        <h1 class="font-serif text-5xl sm:text-6xl md:text-7xl lg:text-8xl text-ink-strong leading-[0.95] mb-8">
          Chosen<br />Object
        </h1>
        <div class="w-16 h-px bg-ink/20 md:mx-0 mx-auto mb-8"></div>
        <p class="font-serif italic text-ink-soft text-lg sm:text-xl md:text-2xl leading-relaxed max-w-xl md:mx-0 mx-auto">
          Where artisans meet collectors.<br class="hidden sm:block" />
          Curated craft, collected with care.
        </p>
      </div>

      <div class="absolute bottom-10 left-1/2 -translate-x-1/2 animate-bounce z-10">
        <svg class="w-5 h-5 text-ink/40" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Section 1 — What is Chosen Object                  -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section :style="sectionStyle(1)" class="flex flex-col justify-center items-center px-6 relative overflow-hidden">

      <!-- Video background -->
      <video
        class="absolute inset-0 w-full h-full object-cover"
        src="/landing_videos/2.mp4"
        autoplay
        loop
        muted
        playsinline
        preload="auto"
        disablePictureInPicture
        @canplaythrough.once="onVideoReady"
      ></video>
      <!-- Dark overlay for readability -->
      <div class="absolute inset-0 bg-black/50"></div>

      <!-- Decorative large background text -->
      <span
        class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 font-serif text-[18vw] text-white/[0.04] leading-none select-none pointer-events-none whitespace-nowrap"
        :style="{ ...s1Style(0, 0), opacity: s1Visible[0] ? 0.04 : 0 }"
      >CRAFT</span>

      <!-- Center content -->
      <div class="relative z-10 max-w-3xl mx-auto text-center">
        <!-- Eyebrow -->
        <p class="font-serif italic text-gold text-sm tracking-[0.3em] uppercase mb-6" :style="s1Style(0)">
          The platform
        </p>

        <!-- Main headline -->
        <h2
          class="font-serif text-4xl sm:text-5xl md:text-6xl lg:text-7xl text-white leading-[1.05] mb-8"
          :style="s1Style(1, 60)"
        >
          A marketplace for<br>
          <span class="italic text-gold">handmade</span> pieces
        </h2>

        <!-- Animated divider -->
        <div class="flex justify-center mb-8" :style="s1Style(2)">
          <div
            class="h-px bg-white/30"
            :style="{ width: s1LineWidth, transition: 'width 800ms cubic-bezier(0.16, 1, 0.3, 1)' }"
          ></div>
        </div>

        <!-- Description -->
        <p class="text-white/80 text-lg md:text-xl leading-relaxed max-w-2xl mx-auto mb-4" :style="s1Style(3, 40)">
          Chosen Object connects independent artisans with collectors who value craftsmanship,
          materiality, and the story behind every piece.
        </p>
        <p class="text-white/50 text-sm leading-relaxed max-w-lg mx-auto" :style="s1Style(4, 40)">
          Available for iOS and Android. Browse studios, collect pieces, and support the makers
          shaping contemporary craft.
        </p>
      </div>

      <!-- Stats strip — bottom -->
      <div class="absolute bottom-14 left-0 right-0 flex justify-center gap-12 md:gap-20 px-6">
        <div class="text-center" :style="s1Style(4, 30)">
          <p class="font-serif text-3xl md:text-4xl text-white">100+</p>
          <p class="text-white/40 text-[11px] tracking-widest uppercase mt-1">Studios</p>
        </div>
        <div class="text-center" :style="s1Style(5, 30)">
          <p class="font-serif text-3xl md:text-4xl text-white">500+</p>
          <p class="text-white/40 text-[11px] tracking-widest uppercase mt-1">Pieces</p>
        </div>
        <div class="text-center" :style="s1Style(6, 30)">
          <p class="font-serif text-3xl md:text-4xl text-white">12</p>
          <p class="text-white/40 text-[11px] tracking-widest uppercase mt-1">Disciplines</p>
        </div>
        <div class="text-center" :style="s1Style(7, 30)">
          <p class="font-serif text-3xl md:text-4xl text-white">EU</p>
          <p class="text-white/40 text-[11px] tracking-widest uppercase mt-1">Shipping</p>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Section 2 — How it works                           -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section :style="sectionStyle(2)" class="relative overflow-hidden">

      <!-- Video background -->
      <video
        class="absolute inset-0 w-full h-full object-cover"
        src="/landing_videos/3.mp4"
        autoplay
        loop
        muted
        playsinline
        preload="auto"
        disablePictureInPicture
        @canplaythrough.once="onVideoReady"
      ></video>
      <div class="absolute inset-0 bg-black/60"></div>

      <!-- Content — full height, two-column layout -->
      <div class="relative z-10 h-full flex items-center px-8 md:px-16 lg:px-24">
        <div class="w-full grid grid-cols-1 lg:grid-cols-[1fr_1px_1fr] gap-10 lg:gap-16 items-center">

          <!-- Left — large typographic headline -->
          <div>
            <p class="font-serif italic text-gold/80 text-sm tracking-[0.3em] uppercase mb-5" :style="s2Style(0)">
              How it works
            </p>
            <h2
              class="font-serif text-4xl sm:text-5xl md:text-6xl text-white leading-[1.05] mb-8"
              :style="s2Style(1, 60)"
            >
              Three steps.<br>
              <span class="italic text-white/50">One journey.</span>
            </h2>
            <p class="text-white/50 text-base leading-relaxed max-w-md" :style="s2Style(2, 40)">
              From discovery to acquisition, every interaction is designed around the relationship between maker and collector.
            </p>
          </div>

          <!-- Vertical divider (desktop) -->
          <div class="hidden lg:block h-80 bg-white/10"></div>

          <!-- Right — steps with staggered entrance -->
          <div class="flex flex-col gap-10">
            <!-- Step 1 -->
            <div class="flex items-start gap-6" :style="s2Style(3, 40)">
              <div class="shrink-0 w-14 h-14 rounded-full border border-white/20 flex items-center justify-center">
                <span class="font-serif text-white/70 text-xl">01</span>
              </div>
              <div>
                <h3 class="font-serif text-xl text-white mb-2">Discover</h3>
                <p class="text-white/50 text-sm leading-relaxed">
                  Browse curated artisan studios. Explore ceramics, sculpture, furniture, textiles, lighting, and more.
                </p>
              </div>
            </div>
            <!-- Step 2 -->
            <div class="flex items-start gap-6" :style="s2Style(4, 40)">
              <div class="shrink-0 w-14 h-14 rounded-full border border-white/20 flex items-center justify-center">
                <span class="font-serif text-white/70 text-xl">02</span>
              </div>
              <div>
                <h3 class="font-serif text-xl text-white mb-2">Collect</h3>
                <p class="text-white/50 text-sm leading-relaxed">
                  Save your favourite pieces, follow studios, and build a personal collection of handcrafted works.
                </p>
              </div>
            </div>
            <!-- Step 3 -->
            <div class="flex items-start gap-6" :style="s2Style(5, 40)">
              <div class="shrink-0 w-14 h-14 rounded-full border border-white/20 flex items-center justify-center">
                <span class="font-serif text-white/70 text-xl">03</span>
              </div>
              <div>
                <h3 class="font-serif text-xl text-white mb-2">Acquire</h3>
                <p class="text-white/50 text-sm leading-relaxed">
                  Purchase outright or rent pieces for your space. Flexible options for every collector.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Section 3 — Download CTA                           -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section :style="sectionStyle(3)" class="flex items-center justify-center px-6 relative overflow-hidden">
      <!-- Video background -->
      <video
        class="absolute inset-0 w-full h-full object-cover"
        src="/landing_videos/4.mp4"
        autoplay
        loop
        muted
        playsinline
        preload="auto"
        disablePictureInPicture
        @canplaythrough.once="onVideoReady"
      ></video>
      <div class="absolute inset-0 bg-black/50"></div>

      <div class="relative z-10 max-w-2xl text-center">
        <img src="/logo.svg" alt="CO" class="w-20 h-20 rounded-2xl mx-auto mb-10 ring-1 ring-white/10" />
        <h2 class="font-serif text-4xl sm:text-5xl md:text-6xl text-bone leading-[1.1] mb-5">
          Start collecting
        </h2>
        <p class="text-bone/50 text-lg leading-relaxed mb-12 max-w-md mx-auto">
          Download the app and explore a world of handmade craft. Available on iOS and Android.
        </p>
        <div class="flex flex-col sm:flex-row items-center justify-center gap-5">
          <a href="#" class="inline-flex items-center gap-4 bg-white text-ink rounded-2xl px-8 py-5 hover:bg-bone transition-colors duration-300 shadow-lg shadow-white/5">
            <svg class="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z" />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-50">Download on the</div>
              <div class="text-lg font-medium leading-tight">App Store</div>
            </div>
          </a>
          <a href="#" class="inline-flex items-center gap-4 bg-white text-ink rounded-2xl px-8 py-5 hover:bg-bone transition-colors duration-300 shadow-lg shadow-white/5">
            <svg class="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3.61 1.814L13.793 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .61-.92zm10.895 9.476l2.56-2.56L5.574.587l8.93 10.703zm-8.93 10.703l11.49-6.143-2.56-2.56-8.93 8.703zM21.408 10.9l-2.764-1.478-2.81 2.578 2.81 2.578 2.764-1.478a1.003 1.003 0 0 0 0-1.8v.6z" />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-50">Get it on</div>
              <div class="text-lg font-medium leading-tight">Google Play</div>
            </div>
          </a>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Section 5 — Footer                                 -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section :style="sectionStyle(4)" class="bg-surface flex flex-col justify-between px-6 sm:px-12 py-12">
      <!-- Large title -->
      <h2 class="font-serif text-[14vw] text-ink-strong text-center leading-none">
        Chosen Object
      </h2>

      <!-- Footer content -->
      <div>
        <!-- Links grid -->
        <div class="max-w-[var(--container)] mx-auto grid grid-cols-2 sm:grid-cols-4 gap-8 sm:gap-12 mb-12">
          <!-- Platform -->
          <div>
            <p class="text-ink-strong text-xs font-medium uppercase tracking-widest mb-4">Platform</p>
            <ul class="space-y-2.5">
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Browse pieces</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Explore studios</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Disciplines</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">How it works</a></li>
            </ul>
          </div>
          <!-- For artisans -->
          <div>
            <p class="text-ink-strong text-xs font-medium uppercase tracking-widest mb-4">For artisans</p>
            <ul class="space-y-2.5">
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Start selling</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Pricing</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Seller guidelines</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Success stories</a></li>
            </ul>
          </div>
          <!-- Company -->
          <div>
            <p class="text-ink-strong text-xs font-medium uppercase tracking-widest mb-4">Company</p>
            <ul class="space-y-2.5">
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">About us</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Blog</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Careers</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Press</a></li>
            </ul>
          </div>
          <!-- Support -->
          <div>
            <p class="text-ink-strong text-xs font-medium uppercase tracking-widest mb-4">Support</p>
            <ul class="space-y-2.5">
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Help centre</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Contact us</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Privacy policy</a></li>
              <li><a href="#" class="text-muted text-sm hover:text-ink-soft transition-colors">Terms of service</a></li>
            </ul>
          </div>
        </div>

        <!-- App download -->
        <div class="max-w-[var(--container)] mx-auto flex justify-center gap-4 mb-10">
          <a href="#" class="inline-flex items-center gap-2.5 bg-ink text-bone rounded-lg px-5 py-3 hover:bg-ink-soft transition-colors duration-300">
            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"/></svg>
            <div class="text-left">
              <div class="text-[9px] leading-none opacity-50">Download on the</div>
              <div class="text-sm font-medium leading-tight">App Store</div>
            </div>
          </a>
          <a href="#" class="inline-flex items-center gap-2.5 bg-ink text-bone rounded-lg px-5 py-3 hover:bg-ink-soft transition-colors duration-300">
            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M3.61 1.814L13.793 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .61-.92zm10.895 9.476l2.56-2.56L5.574.587l8.93 10.703zm-8.93 10.703l11.49-6.143-2.56-2.56-8.93 8.703zM21.408 10.9l-2.764-1.478-2.81 2.578 2.81 2.578 2.764-1.478a1.003 1.003 0 0 0 0-1.8v.6z"/></svg>
            <div class="text-left">
              <div class="text-[9px] leading-none opacity-50">Get it on</div>
              <div class="text-sm font-medium leading-tight">Google Play</div>
            </div>
          </a>
        </div>

        <!-- Divider -->
        <div class="max-w-[var(--container)] mx-auto h-px bg-hairline mb-8"></div>

        <!-- Bottom bar -->
        <div class="max-w-[var(--container)] mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <img src="/logo.svg" alt="CO" class="w-6 h-6 rounded-md" />
            <p class="text-muted-2 text-xs">&copy; 2026 Chosen Object. All rights reserved.</p>
          </div>
          <div class="flex items-center gap-5">
            <!-- Social links -->
            <a href="#" class="text-muted hover:text-ink-soft transition-colors" aria-label="Instagram">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
            </a>
            <a href="#" class="text-muted hover:text-ink-soft transition-colors" aria-label="X">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
            </a>
            <a href="#" class="text-muted hover:text-ink-soft transition-colors" aria-label="TikTok">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>
            </a>
            <span class="text-hairline">|</span>
            <button
              @click="openLogin"
              class="text-muted text-xs font-medium hover:text-ink-soft transition-colors cursor-pointer"
            >Log in</button>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- Login Modal                                        -->
    <!-- ═══════════════════════════════════════════════════ -->
    <Teleport to="body">
      <div
        v-if="showLogin"
        class="fixed inset-0 z-[100] flex items-center justify-center px-4"
      >
        <!-- Backdrop -->
        <div
          class="absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity duration-300"
          :class="loginReady ? 'opacity-100' : 'opacity-0'"
          @click="closeLogin"
        ></div>

        <!-- Modal card -->
        <div
          class="relative z-10 w-full max-w-[420px] bg-bone rounded-2xl shadow-2xl transition-all duration-300"
          :style="{
            transform: loginReady ? 'translateY(0) scale(1)' : 'translateY(24px) scale(0.97)',
            opacity: loginReady ? 1 : 0,
          }"
        >
          <!-- Close button -->
          <button
            @click="closeLogin"
            class="absolute top-5 right-5 w-8 h-8 flex items-center justify-center rounded-full hover:bg-ink/5 transition-colors cursor-pointer"
          >
            <svg class="w-4 h-4 text-muted" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>

          <div class="px-10 pt-12 pb-10">
            <!-- Header -->
            <div class="text-center mb-10">
              <img src="/logo.svg" alt="CO" class="w-14 h-14 rounded-xl mx-auto mb-5" />
              <h2 class="font-serif text-[28px] text-ink-strong leading-tight">Chosen Object</h2>
              <p class="text-muted text-sm mt-2">Sign in to your account</p>
            </div>

            <!-- Form -->
            <form @submit.prevent="handleLogin" class="space-y-5">
              <!-- Email -->
              <div>
                <label class="block text-[11px] font-medium text-muted uppercase tracking-[1.4px] mb-2">
                  Email or username
                </label>
                <input
                  v-model="loginEmail"
                  type="text"
                  autocomplete="username"
                  class="w-full h-12 px-4 bg-surface border border-hairline rounded-lg text-ink text-sm outline-none transition-all duration-200 focus:border-ink/30 focus:ring-2 focus:ring-ink/5"
                  placeholder="you@example.com"
                />
              </div>

              <!-- Password -->
              <div>
                <label class="block text-[11px] font-medium text-muted uppercase tracking-[1.4px] mb-2">
                  Password
                </label>
                <div class="relative">
                  <input
                    v-model="loginPassword"
                    :type="showPassword ? 'text' : 'password'"
                    autocomplete="current-password"
                    class="w-full h-12 px-4 pr-12 bg-surface border border-hairline rounded-lg text-ink text-sm outline-none transition-all duration-200 focus:border-ink/30 focus:ring-2 focus:ring-ink/5"
                    placeholder="Your password"
                  />
                  <button
                    type="button"
                    @click="showPassword = !showPassword"
                    class="absolute right-3 top-1/2 -translate-y-1/2 w-8 h-8 flex items-center justify-center rounded-full hover:bg-ink/5 transition-colors cursor-pointer"
                  >
                    <svg v-if="!showPassword" class="w-4 h-4 text-muted" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <svg v-else class="w-4 h-4 text-muted" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12c1.292 4.338 5.31 7.5 10.066 7.5.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                    </svg>
                  </button>
                </div>
                <div class="text-right mt-2">
                  <a href="#" class="text-accent text-xs hover:underline">Forgot your password?</a>
                </div>
              </div>

              <!-- Error -->
              <p v-if="loginError" class="text-danger text-xs text-center">{{ loginError }}</p>

              <!-- Submit -->
              <button
                type="submit"
                :disabled="loginLoading"
                class="w-full h-12 rounded-lg text-sm font-medium transition-all duration-200 cursor-pointer"
                :class="loginLoading
                  ? 'bg-ink/70 text-bone'
                  : 'bg-ink text-bone hover:bg-ink-soft active:scale-[0.98]'"
              >
                <span v-if="!loginLoading">Sign in</span>
                <svg v-else class="w-5 h-5 mx-auto animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                </svg>
              </button>
            </form>

            <!-- Footer -->
            <p class="text-center text-muted text-xs mt-8">
              Don't have an account?
              <a href="#" class="text-accent font-medium hover:underline">Sign up</a>
            </p>
          </div>
        </div>
      </div>
    </Teleport>

  </div>
</template>

<style scoped>
.landing-root {
  overflow: hidden;
  height: 100%;
  position: fixed;
  inset: 0;
  background: var(--color-bone);
}
</style>
