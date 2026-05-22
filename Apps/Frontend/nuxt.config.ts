export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },
  modules: [
    '@nuxt/ui',
    '@nuxtjs/seo',
    '@nuxt/eslint'
  ],
  css: ['~/assets/css/main.css'],
  postcss: {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  },
  runtimeConfig: {
    public: {
      apiBase: '/api'
    }
  },
  site: {
    url: 'http://localhost:3000',
    name: 'No Food Waste'
  }
})

