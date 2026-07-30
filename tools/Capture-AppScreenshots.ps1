param(
    [string]$AppUrl = "http://192.168.100.136:8080/#/home?msdd=App.msdd",
    [string]$ScreenshotDir = "manuals/sim300-iolink-modbus-server/versions/v1.0.0/assets/screenshots",
    [string]$Username = "",
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "node_modules/playwright")) {
    npm install
}

npx playwright install chromium

$env:APP_URL = $AppUrl
$env:SCREENSHOT_DIR = $ScreenshotDir

if (-not [string]::IsNullOrWhiteSpace($Username)) {
    $env:APP_USERNAME = $Username
}

if (-not [string]::IsNullOrWhiteSpace($Password)) {
    $env:APP_PASSWORD = $Password
}

node tools/capture-app-screenshots.mjs
