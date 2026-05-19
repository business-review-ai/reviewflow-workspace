# 🤖 GitHub Webhook Auto-Deployment Setup Guide

This guide describes how to configure and deploy a secure, automated GitHub Webhook listener on your staging and production servers to achieve **100% automated CI/CD**. 

Whenever you push latest commits to the `main` branch of `frontend`, `admin`, `backend`, `landing`, or `onboard`, the listener will automatically verify the signature, pull the latest files using SSH, and trigger a lightweight `docker-compose` rebuild strictly for the modified container.

---

## 🛠️ Step 1: Install Process Manager (PM2) on Server

Ensure Node.js is installed on your VPS, then install the PM2 package globally to manage the webhook listener as a background daemon:

```bash
# Install PM2 globally
sudo npm install -g pm2

# Generate automatic PM2 startup script to recover services on server reboot
pm2 startup
# (Copy-paste the resulting command outputted by the terminal to register the service)
```

---

## 🔑 Step 2: Configure Webhook Secrets & Variables

Navigate to the webhook folder on your server:
```bash
cd /workspace/business-review-ai/onboard/webhook
```

Open the `ecosystem.config.js` file and replace the `WEBHOOK_SECRET` with your own secure random key:
```javascript
// ecosystem.config.js
PORT: 9000,
WEBHOOK_SECRET: "your_ultra_secure_secret_hash_here", // Change this!
WORKSPACE_DIR: "/workspace/business-review-ai"
```

---

## 🚀 Step 3: Launch Webhook Server under PM2

Start the webhook server in background daemon mode:

### For Production Server:
```bash
pm2 start ecosystem.config.js --env production
```

### For Staging Server:
```bash
pm2 start ecosystem.config.js --env staging
```

Verify that the process is online:
```bash
pm2 status
pm2 logs reviewflow-webhook
```

To ensure PM2 saves this running configuration so it auto-restarts upon VPS reboot:
```bash
pm2 save
```

---

## 🛡️ Step 4: Map Webhook through Nginx Reverse Proxy

To make your webhook accessible securely via your domains, add a location block inside your global server Nginx configuration file:

```nginx
# Add inside your HTTPS server block in Nginx
location /webhook {
    proxy_pass http://127.0.0.1:9000/webhook;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Reload Nginx to apply changes:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📡 Step 5: Configure the Webhook on GitHub

1. Go to your GitHub repositories (e.g. `frontend`, `backend`, `admin`, `landing`, `onboard`).
2. Navigate to **Settings** ➡️ **Webhooks** ➡️ Click **Add webhook**.
3. Configure the fields as follows:
   * **Payload URL:** `https://reviewflow.geetrix.com/webhook` (or your staging domain: `https://staging.reviewflow.geetrix.com/webhook`)
   * **Content type:** `application/json`
   * **Secret:** `your_ultra_secure_secret_hash_here` (The exact key matching `ecosystem.config.js`)
   * **Which events:** Select **Just the push event**.
   * **Active:** Check the checkbox.
4. Click **Add webhook**.

---

## 🔄 Step 6: Test the Integration!

1. Make a small code adjustment on the `main` branch of your repository.
2. Push to GitHub: `git push origin main`.
3. Check the PM2 logs on your server:
   ```bash
   pm2 logs reviewflow-webhook
   ```
4. You will see:
   ```
   📡 Webhook received from repo: 'frontend' on branch: 'refs/heads/main'
   🚀 Starting automated deployment for 'frontend' in 'production' mode...
   🔄 Checking out and pulling main branch...
   🐳 Rebuilding target microservice container in 'production' environment...
   🎉 Deployment for service 'frontend' completed successfully!
   ```

Your automated CI/CD pipeline is now fully operational and bulletproof! 🚀
