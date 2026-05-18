# floodboy-astro — Testing

**Researched**: 2026-05-11 17:47 GMT+7 by IOTBOY

## Current state

**Playwright configured, ZERO tests implemented.**

```
package.json scripts:
  test          playwright test
  test:ui       playwright test --ui
  test:headed   playwright test --headed
  test:prod     playwright test --config=playwright.prod.config.ts
```

But:
- ❌ no `playwright.config.ts` in repo
- ❌ no `playwright.prod.config.ts`
- ❌ no `tests/` or `e2e/` dir
- ❌ no `*.test.ts` or `*.spec.ts` files
- ❌ no vitest config
- ❌ CI `.github/workflows/deploy.yml` has NO test step (build + deploy only)

## CI workflow today

`.github/workflows/deploy.yml`:
```yaml
jobs:
  deploy:
    steps:
      - Checkout
      - Setup pnpm
      - Setup Node.js 20
      - Install dependencies
      - pnpm build
      - Deploy to Cloudflare Workers
```
No tests, no coverage, no lint gate.

## Proposed minimal test plan

### Phase 1 — Playwright smoke (week 1)

`playwright.config.ts`:
```ts
import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: { baseURL: 'http://localhost:4321', trace: 'on-first-retry' },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:4321',
    reuseExistingServer: !process.env.CI,
  },
});
```

`tests/e2e/pages.spec.ts`:
```ts
test('homepage loads', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/FloodBoy/);
});
test('blockchain page lists factory', async ({ page }) => {
  await page.goto('/blockchain');
  await expect(page.locator('text=JIBCHAIN')).toBeVisible();
});
test('simulator renders preset buttons', async ({ page }) => {
  await page.goto('/simulator');
  await expect(page.locator('button:has-text("Flooding")')).toBeVisible();
});
```

### Phase 2 — Component tests (week 2)

Add vitest + jsdom + RTL:
```json
{
  "vitest":      "^2.0.0",
  "jsdom":       "^24.0.0",
  "@testing-library/react": "^16.0.0"
}
```

Priority components to unit-test:
- `BlockchainDashboard.tsx` — main UI orchestrator
- `FloodboyVisualization.tsx` — P5.js wrapper
- `ChainSelector` — chain switching logic
- `ErrorDisplay` — RPC failure surfaces
- `LoadingSkeleton` — async state UX

### Phase 3 — Blockchain integration tests (week 3)

Mock Viem clients:
```ts
// tests/mocks/blockchain.ts
export const mockPublicClient = {
  readContract: vi.fn(),
  multicall: vi.fn(),
  getLogs: vi.fn(() => Promise.resolve([])),
};
```

Test the Nanostores `blockchain.store.ts`:
- chain switch updates `$chainId` atom
- block-status computed transitions live → delayed → stale at 3s / 10s thresholds
- `processRecordLogs` filters out malformed entries

### Phase 4 — CI integration (week 4)

Update `deploy.yml`:
```yaml
- run: pnpm install
- run: pnpm test:unit       # vitest
- run: pnpm test            # playwright
- run: pnpm build
- run: pnpm deploy
```

## Priority surface for IoT/Web3 frontend

| Priority | Area | Why |
|----------|------|-----|
| HIGH | Chain switching | most common user error path |
| HIGH | RPC failure UX | external dependency = flaky |
| HIGH | Visualization rendering | P5/Chart memory leaks |
| MED | Mobile responsiveness | playwright viewports |
| MED | Nanostores persistence | localStorage RPC pref |
| LOW | Simulator inputs | mostly cosmetic |

## IOTBOY note

For my Rust muninn-memory work, this maps to:
- E2E tests = integration tests (cargo test + redb integration)
- Smoke tests for MCP server (`muninn_remember` → `muninn_recall` round-trip)
- Mock blockchain client = mock MCP client for testing without GitHub Action runner

floodboy-astro's testing gap = real shipping risk. They deploy directly to prod from `main` with no test gate. Worth a PR to add Phase 1 smoke tests if we contribute upstream.
