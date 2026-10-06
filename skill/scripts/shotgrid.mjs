#!/usr/bin/env node
// Low-RAM visual check: one headless browser, one page; viewport and color scheme are switched in place.
// Measured on a Nuxt map app: ~800 MB peak for ~15 s, freed on exit.
// Usage: node shotgrid.mjs <https-url> [out-dir] [--wait <css-selector>]
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const GRID = [
  { name: 'desktop-light', width: 1440, height: 900, scheme: 'light' },
  { name: 'desktop-dark', width: 1440, height: 900, scheme: 'dark' },
  { name: 'mobile-light', width: 390, height: 844, scheme: 'light' },
  { name: 'mobile-dark', width: 390, height: 844, scheme: 'dark' },
];
const SETTLE_MS = 1500;

function newestMatch(root, pattern, leaf) {
  if (!existsSync(root)) {
    return null;
  }
  const hits = readdirSync(root)
    .filter((name) => pattern.test(name))
    .map((name) => join(root, name, leaf))
    .filter((path) => existsSync(path))
    .sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
  return hits[0] ?? null;
}

function playwrightCore(require) {
  if (process.env.PW_CORE) {
    return process.env.PW_CORE;
  }
  for (const name of ['playwright-core', 'playwright']) {
    try {
      return require.resolve(name);
    } catch {
      // not installed under this name; try the next one
    }
  }
  const found = newestMatch(join(homedir(), '.npm/_npx'), /.+/, 'node_modules/playwright-core');
  if (!found) {
    throw new Error('playwright-core not found; install it or set PW_CORE.');
  }
  return found;
}

function headlessShell() {
  if (process.env.PW_EXE) {
    return process.env.PW_EXE;
  }
  return newestMatch(join(homedir(), '.cache/ms-playwright'), /^chromium_headless_shell-/,
    'chrome-headless-shell-linux64/chrome-headless-shell');
}

const [url, outDir = 'screens', flag, selector] = process.argv.slice(2);
if (!url?.startsWith('https://')) {
  console.error('Usage: node shotgrid.mjs <https-url> [out-dir] [--wait <css-selector>]');
  process.exit(2);
}
mkdirSync(outDir, { recursive: true });

const require = createRequire(import.meta.url);
const { chromium } = require(playwrightCore(require));
const browser = await chromium.launch({
  headless: true,
  executablePath: headlessShell() ?? undefined,
  args: ['--disable-gpu', '--disable-dev-shm-usage'],
});
try {
  const page = await browser.newPage();
  const started = Date.now();
  for (const [index, shot] of GRID.entries()) {
    await page.setViewportSize({ width: shot.width, height: shot.height });
    await page.emulateMedia({ colorScheme: shot.scheme });
    if (index === 0) {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
      if (flag === '--wait' && selector) {
        await page.waitForSelector(selector, { timeout: 30000 });
      }
    }
    await page.waitForTimeout(SETTLE_MS);
    await page.screenshot({ path: join(outDir, `${shot.name}.png`) });
  }
  console.log(JSON.stringify({ url, outDir, shots: GRID.map((shot) => shot.name), seconds: (Date.now() - started) / 1000 }));
} finally {
  await browser.close();
}
