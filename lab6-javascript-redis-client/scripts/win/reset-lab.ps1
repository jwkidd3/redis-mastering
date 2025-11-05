# Reset Lab 6 Environment
# PowerShell version for Windows

Write-Host "🔄 Resetting Lab 6 Environment" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Confirm reset
$confirmation = Read-Host "⚠️  This will remove all local changes. Continue? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Reset cancelled."
    exit 1
}

Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow

# Remove generated files
if (Test-Path "node_modules") { Remove-Item -Recurse -Force "node_modules" }
if (Test-Path "package-lock.json") { Remove-Item -Force "package-lock.json" }

# Remove any test data files
Get-ChildItem -Filter "*.log" | Remove-Item -Force
Get-ChildItem -Filter "*.tmp" | Remove-Item -Force

# Remove environment file (keep template)
if (Test-Path ".env") { Remove-Item -Force ".env" }

Write-Host "📦 Reinstalling dependencies..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    npm install
} else {
    Write-Host "⚠️  package.json not found. Run setup first." -ForegroundColor Yellow
}

Write-Host "🔧 Recreating environment file..." -ForegroundColor Yellow
if (Test-Path ".env.template") {
    Copy-Item ".env.template" ".env"
    Write-Host "✅ Environment template copied to .env" -ForegroundColor Green
    Write-Host "⚠️  Remember to update Redis server details!" -ForegroundColor Yellow
} else {
    Write-Host "❌ .env.template not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Lab 6 environment reset complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Update .env with Redis server details"
Write-Host "2. Run: npm test"
Write-Host "3. Start development: npm run dev"
