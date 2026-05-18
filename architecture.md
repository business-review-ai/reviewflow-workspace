# ReviewFlow AI Architecture

This document describes the high-level architecture of the ReviewFlow AI platform. 
The system is divided into multiple repositories under the `business-review-ai` organization to allow independent scaling, development, and deployment.

## Repositories

1. **[reviewflow-workspace](https://github.com/business-review-ai/reviewflow-workspace)**
   - Contains setup scripts, Docker Compose files, and system-wide documentation.
   - Used for quick onboarding and development of the entire stack.

2. **[frontend](https://github.com/business-review-ai/frontend)**
   - The main consumer-facing application where users submit reviews.
   - Built with React, Vite, TailwindCSS, and Zustand.

3. **[admin](https://github.com/business-review-ai/admin)**
   - The dashboard for business owners to view analytics and manage reviews.
   - Built with React, Vite, TailwindCSS.

4. **[backend](https://github.com/business-review-ai/backend)**
   - The core API server.
   - Built with Node.js, Express, Prisma (ORM), and PostgreSQL.
   - Integrates with OpenCode AI for review analysis and Razorpay for payments.

5. **[landing](https://github.com/business-review-ai/landing)**
   - The marketing and sales landing page.
   - Typically static HTML or a lightweight framework.

## Infrastructure & Deployment

- **Database:** PostgreSQL used for persistent storage.
- **Local Dev:** Handled via Docker Compose in the `reviewflow-workspace` repo.
- **Production:** Recommended to use managed PostgreSQL and deploy services via Docker containers to a cloud provider (e.g., AWS, GCP, Vercel for frontends).

## Communication Flow

1. The **frontend** and **admin** interfaces communicate via REST APIs to the **backend**.
2. The **backend** validates and persists data into the **PostgreSQL** database.
3. For AI-based insights, the **backend** calls the OpenCode AI API.
4. For subscriptions/payments, the **backend** interacts with the Razorpay API.

## Data Models (High-Level)
- **User:** Business owners who sign up for the service.
- **Review:** Feedback submitted by end-users (customers).
- **Settings:** Configuration per business (e.g., Google Review link).
