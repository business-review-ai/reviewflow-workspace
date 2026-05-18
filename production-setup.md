# 🚀 Production Deployment & Infrastructure Guide

This guide details the end-to-end steps to deploy the **ReviewFlow AI** platform on your production server. 

### 📋 Deployment Scenario Overview
* **Domain:** `geetrix.com` (Cloudflare DNS)
* **Application URL:** `reviewflow.geetrix.com` (customer/user panel)
* **Admin URL:** `reviewflow.geetrix.com/admin` (admin control panel)
* **API Gateway:** Existing global Nginx reverse proxy (listening on 80/443 with SSL)
* **Docker Network:** `local-docker-net` (external network shared with Nginx & your PostgreSQL)
* **Database:** Existing PostgreSQL instance

---

## 🗺️ Architecture & Request Flow

The following sequence diagram outlines how client requests are routed through Cloudflare and your server's Nginx to reach the appropriate containerized services and database.

```mermaid
graph TD
    Client[Client Browser]
    
    subgraph Cloudflare CDN & DNS
        CF[Cloudflare Edge Servers]
    end

    subgraph Host Server (Docker Host)
        Nginx[Existing Host Nginx Container]
        
        subgraph local-docker-net (Shared Network)
            FE[Frontend Container: Port 80]
            ADM[Admin Container: Port 80]
            BE[Backend Container: Port 5000]
            DB[(Existing PostgreSQL Container)]
        end
    end

    Client -->|DNS: reviewflow.geetrix.com| CF
    CF -->|Port 80/443| Nginx
    
    Nginx -->|/ | FE
    Nginx -->|/admin| ADM
    Nginx -->|/api| BE
    
    BE -->|Prisma Client| DB
```

---

## ⚡ Step-by-Step Deployment Steps

### 1️⃣ Step 1: Cloudflare DNS Configuration

Log into your **Cloudflare Dashboard**, select the `geetrix.com` domain, and navigate to **DNS Settings**. Add the following records:

| Type | Name | Target / Value | TTL | Proxy Status |
| :--- | :--- | :--- | :--- | :--- |
| **A** | `reviewflow` | `YOUR_SERVER_PUBLIC_IP` | Auto | 🟠 Proxied (Active) |
| **A** | `reviewflow.geettrix` *(optional typo fallback)* | `YOUR_SERVER_PUBLIC_IP` | Auto | 🟠 Proxied (Active) |

---

### 2️⃣ Step 2: Configure the Existing Nginx on the Server

You can find the customized configuration file at [nginx.conf](file:///d:/workspace/business-review-ai/onboard/production/nginx.conf). Put this file into your existing Nginx configurations folder (e.g. `/etc/nginx/conf.d/reviewflow.conf`):

```nginx
# Redirect HTTP to HTTPS for ReviewFlow AI
server {
    listen 80;
    server_name reviewflow.geetrix.com reviewflow.geettrix.com;
    return 301 https://$host$request_uri;
}

# ReviewFlow AI Main Server Block
server {
    listen 443 ssl http2;
    server_name reviewflow.geetrix.com reviewflow.geettrix.com;

    ssl_certificate     /etc/nginx/certs/geetrix.crt;
    ssl_certificate_key /etc/nginx/certs/geetrix.key;

    # Dynamic DNS resolution for Docker container names
    resolver 127.0.0.11 valid=30s;

    # 1. Admin Control Panel Routing
    location /admin {
        set $upstream_admin admin:80;
        proxy_pass http://$upstream_admin;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 2. Backend Express API Routing
    location /api {
        set $upstream_backend backend:5000;
        proxy_pass http://$upstream_backend;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # 3. User & Customer Frontend Routing (Root fallback)
    location / {
        set $upstream_frontend frontend:80;
        proxy_pass http://$upstream_frontend;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### 3️⃣ Step 3: Set Up Database & Safe Auto-Deployments

Since you are using an **existing PostgreSQL** database on your `local-docker-net` network:

#### A. Configure Environment Variables
1. Copy `backend/.env.prod.example` to `backend/.env.prod` inside the `backend` folder.
2. Edit `backend/.env.prod` and supply the connection string under `DATABASE_URL`. Because the database is on the same Docker network `local-docker-net`, you can reference it directly via its container name:
   ```env
   DATABASE_URL="postgresql://db_user:db_password@your_postgres_container_name:5432/reviewflow?schema=public"
   ```

#### B. Safe Schema Push Strategy (No Data Loss!)
Your `backend/Dockerfile` has the following startup command:
`CMD ["sh", "-c", "npx prisma db push && npx ts-node src/server.ts"]`

Prisma's `db push` is optimized for rapid auto-deployments. It behaves with **strict safety protocols** regarding database preservation:
- **Additive Changes (Safe):** Creating new tables, adding columns, or creating optional indices are completed seamlessly during auto-deployment without touching existing records.
- **Destructive Changes (Protected):** If you make a schema change that **would cause data loss** (e.g., dropping a column containing records, renaming a column, or adding a non-nullable column without defaults), **Prisma will automatically block the push and raise an error**.
- **Result:** The deployment fails safely *before* any database changes are made, guaranteeing your database remains completely unharmed!

> [!IMPORTANT]
> **How to safely apply destructive schema changes in production:**
> If you deliberately need to perform a destructive operation (like renaming/removing columns):
> 1. Back up your production PostgreSQL database first.
> 2. Access the database container and apply the manual SQL alterations or run `npx prisma db push --accept-data-loss` *only* after confirming the data is backed up or no longer needed.

---

### 4️⃣ Step 4: Run the Automator Deployment Script

Instead of checking out each repository and running individual commands, you can use the master deployment script [clone-and-build.sh](file:///d:/workspace/business-review-ai/onboard/clone-and-build.sh).

This script automatically clones any missing repositories side-by-side, configures missing environmental templates, and starts the container build sequence:

```bash
# 1. Give the script executable permissions
chmod +x clone-and-build.sh

# 2. Run the deployment pipeline
# Options: 'local' (development), 'staging' (pre-prod), 'production' (live server)
./clone-and-build.sh production
```

---

## 🔍 Validation Checklist

- [ ] **Docker Containers Running:** Run `docker ps` to verify `frontend`, `admin`, and `backend` are up and connected to `local-docker-net`.
- [ ] **Frontend Check:** Visit `https://reviewflow.geetrix.com` — The user-facing app should load.
- [ ] **Admin Check:** Visit `https://reviewflow.geetrix.com/admin` — The admin panel should load under `/admin`.
- [ ] **Database Connection Check:** Backend logs (`docker logs backend`) should show successful initialization and database connection.
