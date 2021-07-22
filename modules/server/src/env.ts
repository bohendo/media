export const env = {
  adminToken: process.env.VM_ADMIN_TOKEN || "abc123",
  logLevel: process.env.VM_LOG_LEVEL || "info",
  port: parseInt(process.env.VM_PORT || "8080", 10),
};
