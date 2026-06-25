import { defineConfig } from 'vite'

// Relative base ('./') so the same build runs as a Tauri desktop bundle,
// a plain web deploy, AND under a GitHub Pages / Netlify subpath unchanged.
export default defineConfig({
  base: './',
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true
  },
  build: {
    target: 'es2021',
    outDir: 'dist',
    emptyOutDir: true
  }
})
