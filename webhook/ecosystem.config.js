module.exports = {
  apps: [
    {
      name: "reviewflow-webhook",
      script: "./webhook-server.js",
      watch: false,
      max_memory_restart: "150M",
      env: {
        NODE_ENV: "production",
        PORT: 9000,
        WEBHOOK_SECRET: "reviewflow_secure_webhook_secret_key",
        DEPLOY_ENV: "production",
        WORKSPACE_DIR: "/workspace/business-review-ai"
      },
      env_staging: {
        NODE_ENV: "staging",
        PORT: 9000,
        WEBHOOK_SECRET: "reviewflow_secure_webhook_secret_key",
        DEPLOY_ENV: "staging",
        WORKSPACE_DIR: "/workspace/business-review-ai"
      }
    }
  ]
};
