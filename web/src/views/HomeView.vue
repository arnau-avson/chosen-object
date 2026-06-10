<script setup lang="ts"></script>

<template>
  <!-- ── Navbar ── -->
  <nav class="fixed top-0 left-0 right-0 z-50 bg-bone/90 backdrop-blur-sm border-b border-hairline">
    <div class="max-w-[var(--container)] mx-auto flex items-center h-[var(--topbar-h)] px-6">
      <img src="/logo.svg" alt="CO" class="w-9 h-9 rounded-lg" />
      <span class="ml-3 font-serif text-lg text-ink-strong tracking-tight">Chosen Object</span>
    </div>
  </nav>

  <main>
    <!-- ── Hero ── -->
    <section
      class="min-h-screen flex flex-col items-center justify-center px-6 pt-[var(--topbar-h)] relative overflow-hidden"
    >
      <!-- Decorative background elements -->
      <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-1/4 -left-32 w-64 h-64 rounded-full bg-gold/5 blur-3xl"></div>
        <div class="absolute bottom-1/4 -right-32 w-80 h-80 rounded-full bg-accent/5 blur-3xl"></div>
      </div>

      <div class="text-center max-w-3xl relative z-10">
        <p class="font-serif italic text-gold text-xl mb-6 tracking-widest">N&ordm;</p>

        <h1 class="font-serif text-5xl sm:text-6xl md:text-7xl lg:text-8xl text-ink-strong leading-[0.95] mb-8">
          Chosen<br />Object
        </h1>

        <div class="w-16 h-px bg-hairline mx-auto mb-8"></div>

        <p class="font-serif italic text-ink-soft text-lg sm:text-xl md:text-2xl leading-relaxed max-w-xl mx-auto">
          Where artisans meet collectors.<br class="hidden sm:block" />
          Curated craft, collected with care.
        </p>
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

    <!-- ── What is Chosen Object ── -->
    <section class="py-24 px-6 bg-surface">
      <div class="max-w-[var(--container)] mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <div>
            <p class="font-serif italic text-gold text-sm tracking-widest mb-4">The platform</p>
            <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong leading-tight mb-6">
              A marketplace for handmade, one&#8209;of&#8209;a&#8209;kind pieces
            </h2>
            <p class="text-ink-soft text-base leading-relaxed mb-6">
              Chosen Object connects independent artisans with collectors who value craftsmanship,
              materiality, and the story behind every piece. From ceramics to sculpture, furniture
              to textiles &mdash; discover objects made to last.
            </p>
            <p class="text-muted text-sm leading-relaxed">
              Available for iOS and Android. Browse studios, collect pieces, and support the makers
              shaping contemporary craft.
            </p>
          </div>

          <!-- Visual card grid -->
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-bone rounded-lg p-6 border border-hairline">
              <p class="font-serif text-3xl text-ink-strong mb-1">100+</p>
              <p class="text-muted text-xs">Artisan studios</p>
            </div>
            <div class="bg-bone rounded-lg p-6 border border-hairline mt-6">
              <p class="font-serif text-3xl text-ink-strong mb-1">500+</p>
              <p class="text-muted text-xs">Unique pieces</p>
            </div>
            <div class="bg-bone rounded-lg p-6 border border-hairline">
              <p class="font-serif text-3xl text-ink-strong mb-1">12</p>
              <p class="text-muted text-xs">Disciplines</p>
            </div>
            <div class="bg-bone rounded-lg p-6 border border-hairline mt-6">
              <p class="font-serif text-3xl text-ink-strong mb-1">EU</p>
              <p class="text-muted text-xs">Shipping coverage</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ── How it works ── -->
    <section class="py-24 px-6">
      <div class="max-w-[var(--container)] mx-auto">
        <div class="text-center mb-16">
          <p class="font-serif italic text-gold text-sm tracking-widest mb-4">How it works</p>
          <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong">Three simple steps</h2>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-12 md:gap-8">
          <!-- Step 1 -->
          <div class="text-center relative">
            <div class="w-12 h-12 mx-auto mb-6 rounded-full bg-ink flex items-center justify-center">
              <span class="font-serif text-bone text-lg">1</span>
            </div>
            <h3 class="font-serif text-xl text-ink-strong mb-3">Discover</h3>
            <p class="text-muted text-sm leading-relaxed max-w-xs mx-auto">
              Browse curated artisan studios. Explore ceramics, sculpture, furniture, textiles, lighting, and more.
            </p>
            <!-- Connector line (desktop only) -->
            <div class="hidden md:block absolute top-6 left-[calc(50%+32px)] w-[calc(100%-64px)] h-px bg-hairline"></div>
          </div>

          <!-- Step 2 -->
          <div class="text-center relative">
            <div class="w-12 h-12 mx-auto mb-6 rounded-full bg-ink flex items-center justify-center">
              <span class="font-serif text-bone text-lg">2</span>
            </div>
            <h3 class="font-serif text-xl text-ink-strong mb-3">Collect</h3>
            <p class="text-muted text-sm leading-relaxed max-w-xs mx-auto">
              Save your favourite pieces, follow studios, and build a personal collection of handcrafted works.
            </p>
            <div class="hidden md:block absolute top-6 left-[calc(50%+32px)] w-[calc(100%-64px)] h-px bg-hairline"></div>
          </div>

          <!-- Step 3 -->
          <div class="text-center">
            <div class="w-12 h-12 mx-auto mb-6 rounded-full bg-ink flex items-center justify-center">
              <span class="font-serif text-bone text-lg">3</span>
            </div>
            <h3 class="font-serif text-xl text-ink-strong mb-3">Acquire</h3>
            <p class="text-muted text-sm leading-relaxed max-w-xs mx-auto">
              Purchase outright or rent pieces for your space. Flexible options for every collector.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Features ── -->
    <section class="py-24 px-6 bg-surface">
      <div class="max-w-[var(--container)] mx-auto">
        <div class="text-center mb-16">
          <p class="font-serif italic text-gold text-sm tracking-widest mb-4">Features</p>
          <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong">Built for craft lovers</h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
          <!-- Feature cards -->
          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-gold/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-gold" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Studio profiles</h3>
            <p class="text-muted text-sm leading-relaxed">
              Each artisan has a full profile with their story, discipline, and complete catalogue.
            </p>
          </div>

          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-accent/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Save favourites</h3>
            <p class="text-muted text-sm leading-relaxed">
              Bookmark pieces and studios you love. Build wishlists and get notified of new work.
            </p>
          </div>

          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-sage/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-sage" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Rent or buy</h3>
            <p class="text-muted text-sm leading-relaxed">
              Flexible acquisition options. Purchase outright or rent pieces for exhibitions and spaces.
            </p>
          </div>

          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-gold/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-gold" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 8.511c.884.284 1.5 1.128 1.5 2.097v4.286c0 1.136-.847 2.1-1.98 2.193-.34.027-.68.052-1.02.072v3.091l-3-3c-1.354 0-2.694-.055-4.02-.163a2.115 2.115 0 01-.825-.242m9.345-8.334a2.126 2.126 0 00-.476-.095 48.64 48.64 0 00-8.048 0c-1.131.094-1.976 1.057-1.976 2.192v4.286c0 .837.46 1.58 1.155 1.951m9.345-8.334V6.637c0-1.621-1.152-3.026-2.76-3.235A48.455 48.455 0 0011.25 3c-2.115 0-4.198.137-6.24.402-1.608.209-2.76 1.614-2.76 3.235v6.226c0 1.621 1.152 3.026 2.76 3.235.577.075 1.157.14 1.74.194V21l4.155-4.155" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Direct messaging</h3>
            <p class="text-muted text-sm leading-relaxed">
              Chat directly with artisans. Ask about materials, commissions, or bespoke pieces.
            </p>
          </div>

          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-accent/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Location-based</h3>
            <p class="text-muted text-sm leading-relaxed">
              Find studios near you or explore artisans by city and country across Europe.
            </p>
          </div>

          <div class="bg-bone rounded-lg p-8 border border-hairline hover:border-muted-2 transition-colors">
            <div class="w-10 h-10 mb-5 rounded-full bg-sage/10 flex items-center justify-center">
              <svg class="w-5 h-5 text-sage" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
              </svg>
            </div>
            <h3 class="font-serif text-lg text-ink-strong mb-2">Secure transactions</h3>
            <p class="text-muted text-sm leading-relaxed">
              Safe payments, verified artisans, and buyer protection on every purchase.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Quote banner ── -->
    <section class="bg-ink py-24 px-6 relative overflow-hidden">
      <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-0 left-1/4 w-96 h-96 rounded-full bg-gold/5 blur-3xl"></div>
      </div>
      <div class="max-w-2xl mx-auto text-center relative z-10">
        <p class="font-serif italic text-bone/30 text-6xl leading-none mb-4">&ldquo;</p>
        <p class="font-serif italic text-bone text-2xl sm:text-3xl leading-snug mb-2">
          Every object tells the story of the hands that made it.
        </p>
        <p class="text-muted-2 text-sm mt-6">&#8212; The Chosen Object philosophy</p>
      </div>
    </section>

    <!-- ── For artisans ── -->
    <section class="py-24 px-6">
      <div class="max-w-[var(--container)] mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <!-- Visual -->
          <div class="order-2 lg:order-1">
            <div class="bg-surface rounded-lg border border-hairline p-10">
              <div class="space-y-6">
                <div class="flex items-start gap-4">
                  <div class="w-8 h-8 rounded-full bg-accent/10 flex items-center justify-center shrink-0 mt-0.5">
                    <svg class="w-4 h-4 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-ink-strong text-sm font-medium mb-1">List your pieces</p>
                    <p class="text-muted text-xs leading-relaxed">Upload photos, set prices, manage stock and editions from your phone.</p>
                  </div>
                </div>
                <div class="flex items-start gap-4">
                  <div class="w-8 h-8 rounded-full bg-accent/10 flex items-center justify-center shrink-0 mt-0.5">
                    <svg class="w-4 h-4 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-ink-strong text-sm font-medium mb-1">Manage rentals</p>
                    <p class="text-muted text-xs leading-relaxed">Offer pieces for rent with a built-in calendar and daily rate system.</p>
                  </div>
                </div>
                <div class="flex items-start gap-4">
                  <div class="w-8 h-8 rounded-full bg-accent/10 flex items-center justify-center shrink-0 mt-0.5">
                    <svg class="w-4 h-4 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-ink-strong text-sm font-medium mb-1">Grow your audience</p>
                    <p class="text-muted text-xs leading-relaxed">Build a following, receive messages, and connect directly with collectors.</p>
                  </div>
                </div>
                <div class="flex items-start gap-4">
                  <div class="w-8 h-8 rounded-full bg-accent/10 flex items-center justify-center shrink-0 mt-0.5">
                    <svg class="w-4 h-4 text-accent" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-ink-strong text-sm font-medium mb-1">Dashboard & analytics</p>
                    <p class="text-muted text-xs leading-relaxed">Track views, sales, and rental activity with a simple seller dashboard.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Text -->
          <div class="order-1 lg:order-2">
            <p class="font-serif italic text-gold text-sm tracking-widest mb-4">For artisans</p>
            <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong leading-tight mb-6">
              Sell your work to collectors who truly appreciate it
            </h2>
            <p class="text-ink-soft text-base leading-relaxed mb-6">
              Chosen Object gives independent makers a dedicated space to showcase and sell their craft.
              No algorithms, no noise &mdash; just a curated community that values what you make.
            </p>
            <p class="text-muted text-sm">
              Free to join. Start listing your pieces today.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Disciplines ── -->
    <section class="py-20 px-6 bg-surface border-t border-b border-hairline">
      <div class="max-w-[var(--container)] mx-auto text-center">
        <p class="font-serif italic text-gold text-sm tracking-widest mb-8">Disciplines</p>
        <div class="flex flex-wrap justify-center gap-3">
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Ceramic</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Sculpture</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Furniture</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Textiles</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Lighting</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Painting</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Watercolour</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Photography</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Decor</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Jewellery</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Glasswork</span>
          <span class="px-5 py-2.5 rounded-full border border-hairline text-ink-soft text-sm font-medium hover:border-muted transition-colors">Printmaking</span>
        </div>
      </div>
    </section>

    <!-- ── Download CTA ── -->
    <section class="py-28 px-6">
      <div class="max-w-lg mx-auto text-center">
        <img src="/logo.svg" alt="CO" class="w-16 h-16 rounded-xl mx-auto mb-8" />
        <h2 class="font-serif text-3xl sm:text-4xl text-ink-strong mb-4">Get the app</h2>
        <p class="text-muted text-sm mb-10 leading-relaxed">
          Download Chosen Object and start exploring a world of handmade craft.
          Available on iOS and Android.
        </p>

        <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
          <!-- App Store -->
          <a
            href="#"
            class="inline-flex items-center gap-3 bg-ink text-bone rounded-xl px-7 py-4 hover:bg-ink-soft transition-colors duration-300"
          >
            <svg class="w-7 h-7" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"
              />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-60">Download on the</div>
              <div class="text-base font-medium leading-tight">App Store</div>
            </div>
          </a>

          <!-- Google Play -->
          <a
            href="#"
            class="inline-flex items-center gap-3 bg-ink text-bone rounded-xl px-7 py-4 hover:bg-ink-soft transition-colors duration-300"
          >
            <svg class="w-7 h-7" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M3.61 1.814L13.793 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .61-.92zm10.895 9.476l2.56-2.56L5.574.587l8.93 10.703zm-8.93 10.703l11.49-6.143-2.56-2.56-8.93 8.703zM21.408 10.9l-2.764-1.478-2.81 2.578 2.81 2.578 2.764-1.478a1.003 1.003 0 0 0 0-1.8v.6z"
              />
            </svg>
            <div class="text-left">
              <div class="text-[10px] leading-none opacity-60">Get it on</div>
              <div class="text-base font-medium leading-tight">Google Play</div>
            </div>
          </a>
        </div>
      </div>
    </section>

    <!-- ── Footer ── -->
    <footer class="border-t border-hairline py-12 px-6 bg-surface">
      <div class="max-w-[var(--container)] mx-auto flex flex-col items-center gap-4">
        <div class="flex items-center gap-3">
          <img src="/logo.svg" alt="CO" class="w-7 h-7 rounded-md" />
          <span class="font-serif text-sm text-ink-soft">Chosen Object</span>
        </div>
        <p class="text-muted-2 text-xs">&copy; 2026 Chosen Object. All rights reserved.</p>
      </div>
    </footer>
  </main>
</template>
