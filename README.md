# ReviewFlow AI - Onboard

Welcome to ReviewFlow AI! This repository is your starting point for local development. 
It contains the necessary scripts and configurations to spin up the entire microservices architecture on your machine.

## Prerequisites

- **Node.js** (v18+)
- **Docker Desktop**
- **Git**

## Setup Instructions

To get started with local development, follow these steps:

1. **Clone all repositories** into the same parent folder so they sit side-by-side:
   ```bash
   mkdir business-review-ai
   cd business-review-ai

   git clone https://github.com/business-review-ai/onboard.git
   git clone https://github.com/business-review-ai/frontend.git
   git clone https://github.com/business-review-ai/admin.git
   git clone https://github.com/business-review-ai/backend.git
   git clone https://github.com/business-review-ai/landing.git
   ```

2. **Run the setup script**:
   ```bash
   cd onboard
   ./setup.ps1
   ```
   *Note: If you are not on Windows, you can use `docker-compose up -d --build` directly and run `npm install` in each respective folder.*

3. **Access the services**:
   - Frontend: `http://localhost:3000`
   - Admin: `http://localhost:3001`
   - Backend API: `http://localhost:5000`

## Documentation

- Check out the [Architecture Overview](./architecture.md) to understand how the services communicate.
