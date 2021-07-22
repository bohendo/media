import path from "path";

export type Env = {
  authPassword: string;
  authUsername: string;
  mediaDir: string;
  ipfsUrl: string;
  maxUploadSize: string;
  logLevel: string;
  port: number;
}

export const env: Env = {
  authPassword: process?.env?.BLOG_AUTH_PASSWORD || "abc123",
  authUsername: process?.env?.BLOG_AUTH_USERNAME || "admin",
  mediaDir: path.normalize(process?.env?.BLOG_INTERNAL_DIR || "/media"),
  ipfsUrl: process?.env?.IPFS_URL || "http://ipfs:5001",
  maxUploadSize: process?.env?.BLOG_MAX_UPLOAD_SIZE || "100mb",
  logLevel: process?.env?.BLOG_LOG_LEVEL || "info",
  port: parseInt(process?.env?.BLOG_PORT || "8080", 10),
};
