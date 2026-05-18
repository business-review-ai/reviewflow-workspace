# ReviewFlow AI - Workspace

Welcome to ReviewFlow AI! This repository is your starting point for development. 
It contains the necessary scripts, environment orchestrations, webhook deployments, and documentation to manage the entire microservices architecture.

## Prerequisites

- **Node.js** (v18+)
- **Docker Desktop**
- **Git**

## Setup Instructions

To get started with development, follow these steps:

1. **Clone this workspace repository**:
   ```bash
   git clone https://github.com/business-review-ai/reviewflow-workspace.git
   cd reviewflow-workspace
   ```

2. **Run the setup script**:
   ```bash
   ./clone-and-build.sh local
   ```
   *(Or run `./setup.ps1` on Windows to initialize packages and databases)*
   *Note: If you are not on Windows, you can use `docker-compose up -d --build` directly and run `npm install` in each respective folder.*

3. **Access the services**:
   - Frontend: `http://localhost:3000`
   - Admin: `http://localhost:3001`
   - Backend API: `http://localhost:5000`

## Documentation

- Check out the [Architecture Overview](./architecture.md) to understand how the services communicate.
