#!/usr/bin/env node
// Low-RAM visual check: one headless browser, one page; viewport and color scheme are switched in place.
// Measured on a Nuxt web app: ~800 MB peak for ~15 s, freed on exit.
import { createRequire } from 'node:module';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const USAGE = 'Usage: node shotgrid.mjs <url> [out-dir] [--wait <css-selector>] [--dry-run]';
const GRID = [
  { name: 'desktop-light', width: 1440, height: 900, scheme: 'light' },
  { name: 'desktop-dark', width: 1440, height: 900, scheme: 'dark' },
  { name: 'mobile-light', width: 390, height: 844, scheme: 'light' },
  { name: 'mobile-dark', width: 390, height: 844, scheme: 'dark' },
];
const SETTLE_MS = 1500;

function fail(message) {
  console.error(message ? `${message}\n${USAGE}` : USAGE);
  process.exit(2);
}

function parseArgs(argv) {
  const positional = [];
  let wait;
  let dryRun = false;
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      console.log(USAGE);
      process.exit(0);
    } else if (arg === '--dry-run') {
      dryRun = true;
    } else if (arg === '--wait') {
      wait = argv[i + 1];
      if (!wait || wait.startsWith('-')) {
        fail('--wait needs a css selector');
      }
      i += 1;
    } else if (arg.startsWith('-')) {
      fail(`unknown flag ${arg}`);
    } else {
      positional.push(arg);
    }
  }
  const [url, outDir = 'screens', ...extra] = positional;
  if (!/^(https:\/\/|http:\/\/(localhost|127\.0\.0\.1|\[::1\])(:|\/|$))/.test(url ?? '')) {
    fail('url must be https://, or http:// on localhost');
  }
  if (extra.length > 0) {
    fail(`unexpected argument ${extra[0]}`);
  }
  return { url, outDir, wait, dryRun };
}

function playwrightCore(require) {
  if (process.env.PW_CORE) {
    return process.env.PW_CORE;
  }
  for (const name of ['playwright-core', 'playwright']) {
    try {
      return require.resolve(name, { paths: [process.cwd(), dirname(fileURLToPath(import.meta.url))] });
    } catch {
      continue;
    }
  }
  throw new Error('playwright-core not found; install it (npm i -D playwright-core) or set PW_CORE');
}

const { url, outDir, wait, dryRun } = parseArgs(process.argv.slice(2));
if (dryRun) {
  console.log(JSON.stringify({ url, outDir, wait: wait ?? null }));
  process.exit(0);
}
mkdirSync(outDir, { recursive: true });

const require = createRequire(import.meta.url);
const { chromium } = require(playwrightCore(require));
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.PW_EXE || undefined,
  args: ['--disable-gpu', '--disable-dev-shm-usage'],
});
try {
  const page = await browser.newPage();
  const started = Date.now();
  for (const [index, shot] of GRID.entries()) {
    await page.setViewportSize({ width: shot.width, height: shot.height });
    await page.emulateMedia({ colorScheme: shot.scheme });
    if (index === 0) {
      await page.goto(url, { waitUntil: 'load', timeout: 60000 });
      // streaming and tile pages never go idle; settle briefly, then move on
      await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
      if (wait) {
        await page.waitForSelector(wait, { timeout: 30000 });
      }
    }
    await page.waitForTimeout(SETTLE_MS);
    await page.screenshot({ path: join(outDir, `${shot.name}.png`) });
  }
  console.log(JSON.stringify({ url, outDir, shots: GRID.map((shot) => shot.name), seconds: (Date.now() - started) / 1000 }));
} finally {
  await browser.close();
}
