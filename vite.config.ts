import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ command }) => ({
  plugins: [react()],
  server: { port: 5173, strictPort: true },
  // GitHub Pages serves the site under /lazim/ — only adjust production builds
  base: command === 'build' ? '/lazim/' : '/',
}))
