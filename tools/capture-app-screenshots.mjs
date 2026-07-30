import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';

const baseUrl = process.env.APP_URL || 'http://192.168.100.136:8080/#/home?msdd=App.msdd';
const username = process.env.APP_USERNAME;
const password = process.env.APP_PASSWORD;
const outputDir =
  process.env.SCREENSHOT_DIR ||
  path.resolve('manuals/sim300-iolink-modbus-server/versions/v1.0.0/assets/screenshots');

const routes = [
  { slug: 'home', hash: '/home?msdd=App.msdd' },
  { slug: 'modbus-configuration', hash: '/modbus-configuration?msdd=App.msdd' },
  { slug: 'iolink-endpoint-configuration', hash: '/iolink-endpoint-configuration?msdd=App.msdd' },
  { slug: 'application-settings-general', hash: '/application-settings?msdd=App.msdd' },
  { slug: 'log-monitoring', hash: '/log-monitoring?msdd=App.msdd' },
  { slug: 'help', hash: '/help?msdd=App.msdd' },
];

function urlFor(hash) {
  const url = new URL(baseUrl);
  url.hash = hash;
  return url.toString();
}

async function tryLogin(page) {
  if (!username || !password) {
    return false;
  }

  const userInput = page
    .locator('input[name="username"], input[name="user"], input[type="email"], input[type="text"]')
    .locator('visible=true')
    .first();
  const passwordInput = page.locator('input[name="password"], input[type="password"]').locator('visible=true').first();

  if ((await userInput.count()) === 0 || (await passwordInput.count()) === 0) {
    return false;
  }

  await userInput.fill(username);
  await passwordInput.fill(password);

  const adminLogin = page.getByText('Log in as Admin', { exact: true }).first();
  const userLogin = page.getByText('Log in as User', { exact: true }).first();
  const submit = page.locator('button[type="submit"], input[type="submit"], button:has-text("Log in"), button:has-text("Login")').first();

  if ((await adminLogin.count()) > 0) {
    await adminLogin.click();
  } else if ((await userLogin.count()) > 0) {
    await userLogin.click();
  } else if ((await submit.count()) > 0) {
    await submit.click();
  } else {
    await passwordInput.press('Enter');
  }

  await page.waitForLoadState('networkidle').catch(() => undefined);
  return true;
}

async function isAuthenticationPage(page) {
  const title = await page.title();
  const passwordInputs = await page.locator('input[name="password"], input[type="password"]').count();
  return /log in|login|authentication/i.test(title) || passwordInputs > 0;
}

async function capturePage(page, route) {
  await page.goto(urlFor(route.hash), { waitUntil: 'networkidle' });
  await page.waitForTimeout(1200);
  await page.screenshot({
    path: path.join(outputDir, `${route.slug}.png`),
    fullPage: true,
  });
}

async function captureModal(page, routeHash, actionText, slug) {
  await page.goto(urlFor(routeHash), { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  await closeOpenDialog(page);
  const button = page.getByRole('button', { name: actionText }).first();
  if ((await button.count()) === 0) {
    return;
  }

  await button.click();
  await page.waitForTimeout(700);
  await page.screenshot({
    path: path.join(outputDir, `${slug}.png`),
    fullPage: true,
  });
  await closeOpenDialog(page);
}

async function closeOpenDialog(page) {
  const cancelButton = page.getByRole('button', { name: 'Cancel' }).first();
  const closeButton = page.getByRole('button', { name: 'Close' }).first();

  if ((await cancelButton.count()) > 0 && (await cancelButton.isVisible().catch(() => false))) {
    await cancelButton.click();
    await page.waitForTimeout(400);
    return;
  }

  if ((await closeButton.count()) > 0 && (await closeButton.isVisible().catch(() => false))) {
    await closeButton.click();
    await page.waitForTimeout(400);
    return;
  }

  await page.keyboard.press('Escape').catch(() => undefined);
  await page.waitForTimeout(200);
}

await mkdir(outputDir, { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });

await page.goto(baseUrl, { waitUntil: 'networkidle' });

if (await isAuthenticationPage(page)) {
  const loggedIn = await tryLogin(page);
  await page.waitForTimeout(1000);

  if (!loggedIn || (await isAuthenticationPage(page))) {
    await page.screenshot({
      path: path.join(outputDir, 'authentication-required.png'),
      fullPage: true,
    });
    await browser.close();
    console.warn('Authentication page captured. Set APP_USERNAME and APP_PASSWORD to capture application pages.');
    process.exitCode = 2;
    process.exit();
  }
}

if (await isAuthenticationPage(page)) {
  await page.screenshot({
    path: path.join(outputDir, 'authentication-required.png'),
    fullPage: true,
  });
  console.warn('Authentication page captured. Set APP_USERNAME and APP_PASSWORD to capture application pages.');
  await browser.close();
  process.exitCode = 2;
  process.exit();
}

for (const route of routes) {
  await capturePage(page, route);
}

await captureModal(page, '/modbus-configuration?msdd=App.msdd', 'Create Register', 'modal-create-modbus-register');
await captureModal(page, '/modbus-configuration?msdd=App.msdd', 'Reset Registers', 'modal-reset-modbus-registers');
await captureModal(page, '/iolink-endpoint-configuration?msdd=App.msdd', 'Create Endpoint', 'modal-create-iolink-endpoint');
await captureModal(page, '/iolink-endpoint-configuration?msdd=App.msdd', 'Reset Endpoints', 'modal-reset-iolink-endpoints');

await page.goto(urlFor('/application-settings?msdd=App.msdd'), { waitUntil: 'networkidle' });
await page.waitForTimeout(1000);
const networkTab = page.getByRole('tab', { name: 'Network Settings' }).first();
if ((await networkTab.count()) > 0) {
  await networkTab.click();
  await page.waitForTimeout(1500);
  await page.screenshot({
    path: path.join(outputDir, 'application-settings-network.png'),
    fullPage: true,
  });
}

try {
  const reloadButton = page.getByText('Reload Apps', { exact: true }).locator('visible=true').first();
  if ((await reloadButton.count()) > 0) {
    await reloadButton.click({ timeout: 3000 });
    await page.waitForTimeout(700);
    await page.screenshot({
      path: path.join(outputDir, 'modal-reload-apps-confirmation.png'),
      fullPage: true,
    });
  }
} catch {
  console.warn('Skipped Reload Apps confirmation screenshot because the control was not automation-clickable.');
}

await browser.close();
console.log(`Screenshots written to ${outputDir}`);
