import path from "path";
import { fileURLToPath } from "url";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: { ignoreDuringBuilds: true },
  webpack: (config) => {
    config.resolve = config.resolve || {};
    config.resolve.fallback = {
      ...(config.resolve.fallback || {}),
      electron: false,
      fs: false,
      net: false,
      tls: false,
      bufferutil: false,
      "utf-8-validate": false,
    };
    config.resolve.alias = {
      ...(config.resolve.alias || {}),
      websocket: false,
      "websocket/lib/BufferUtil": false,
      "websocket/lib/Validation": false,
    };
    return config;
  },
};

export default nextConfig;
