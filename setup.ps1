# ReviewFlow AI Setup Script for Windows
# This script automates the installation and environment setup.

Write-Host "🚀 Starting ReviewFlow AI Setup..." -ForegroundColor Cyan

# 1. Check for Dependencies
Write-Host "🔍 Checking dependencies..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Node.js is not installed. Please install it from https://nodejs.org/"
    exit
}
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Docker is not installed. Please install Docker Desktop."
    exit
}

# 2. Install Dependencies
Write-Host "📦 Installing Frontend dependencies..." -ForegroundColor Yellow
if (Test-Path "./frontend") {
    cd ./frontend
    npm install
    cd ..
} else {
    Write-Host "⚠️ Frontend repository not found." -ForegroundColor Red
}

Write-Host "📦 Installing Admin dependencies..." -ForegroundColor Yellow
if (Test-Path "./admin") {
    cd ./admin
    npm install
    cd ..
} else {
    Write-Host "⚠️ Admin repository not found." -ForegroundColor Red
}

Write-Host "📦 Installing Backend dependencies..." -ForegroundColor Yellow
if (Test-Path "./backend") {
    cd ./backend
    npm install
    cd ..
} else {
    Write-Host "⚠️ Backend repository not found." -ForegroundColor Red
}

# 3. Setup Environment Variables
if (!(Test-Path "./local/.env")) {
    Write-Host "📝 Creating default local/.env file..." -ForegroundColor Yellow
    $envContent = @"
# =========================================================================
# REVIEWFLOW AI - LOCAL ENVIRONMENT CONFIGURATION
# =========================================================================

PORT=5000
NODE_ENV=local
DATABASE_URL="postgresql://postgres:postgres@db:5432/reviewflow?schema=public"
JWT_SECRET="supersecretjwtkey_localdefaultsecret"

# OpenCode AI API Configuration
OPENAI_API_KEY="sk-xZBhP6XSw5QjM8ZrIwhcR2tOZ4cFw0U2ZGKARYTXfO6xTJYWOzEtlFC9HK0LDc2Y"
OPENAI_BASE_URL="https://api.opencode.ai/v1"
OPENAI_MODEL="MiniMax M2.5 Free"

# Razorpay Test Keys
RAZORPAY_KEY_ID="rzp_test_placeholder"
RAZORPAY_KEY_SECRET="secret_placeholder"

# VAPID Keys for Push Notifications
VAPID_PUBLIC_KEY="BNP0BCNJRETiut5WhyZlv1cJ1TaH30bntlL1i89XnU4m5dq67ZWlAmf7qVvn-JrEB9qJKHGC79B3B35W74AQZtA"
VAPID_PRIVATE_KEY="oEokC_dJ_etRzmA6w9SMQtFDvmnx4Frx9m1MJnHGf9Q"
"@
    $envContent | Out-File -FilePath "./local/.env" -Encoding utf8
}

# Copy to backend/.env as a host convenience for IDE/Prisma tooling
if (!(Test-Path "./backend/.env")) {
    Copy-Item "./local/.env" "./backend/.env"
}

# 4. Start Docker Containers
Write-Host "🐳 Starting Docker containers..." -ForegroundColor Yellow
docker-compose -f ./local/docker-compose.yml down -v
docker-compose -f ./local/docker-compose.yml up -d --build

Write-Host "⏳ Waiting for database to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 5. Initialize Database
Write-Host "🗄️ Initializing database schema..." -ForegroundColor Yellow
if (Test-Path "./backend") {
    cd ./backend
    npx prisma db push
    cd ..
}

Write-Host "`n✅ Setup Complete!" -ForegroundColor Green
Write-Host "🌐 Frontend: http://localhost:3000"
Write-Host "🛡️ Admin: http://localhost:3001"
Write-Host "🔌 Backend: http://localhost:5000"
Write-Host "📊 Database: localhost:5432"
Write-Host "`nTo start coding, run 'npm run dev' inside the respective folders or keep Docker running." -ForegroundColor Cyan
