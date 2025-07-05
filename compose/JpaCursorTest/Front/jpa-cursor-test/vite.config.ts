import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    proxy: {
      "/api": {
        target: "http://app:8080",
        changeOrigin: true,
        rewrite: (path) =>
          path.replace(/^\/api/, "/jpacursortest/webapi/resource"),
      },
    },
  },
});
