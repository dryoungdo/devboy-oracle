# Floodboy UI Simple - Testing Documentation

**Date**: 2026-05-11  
**Repository**: LarisLabs/floodboy-ui-simple  
**Status**: No existing tests found

---

## Overview

The **Floodboy UI Simple** repository is a static HTML-based web application featuring:
- Interactive IoT sensor visualization demos (p5.html)
- Blockchain integration demo (blockchain.html)
- React 18 components rendered via Babel in the browser
- p5.js canvas drawing for sensor visualization
- Tailwind CSS for styling
- Web3 integration via Viem

**Key Finding**: This project currently has **no automated test infrastructure** — no test files, test runners, configuration files, or CI/CD workflows exist.

---

## Current Test Structure & Conventions

### Existing Tests
**None found.**

The repository contains only:
- 2 HTML files (p5.html, blockchain.html)
- 1 startup script (run.sh)
- 1 README (documentation)
- 1 git history (single initial commit)

### File Structure
```
origin/
├── p5.html                    # 729 lines - IoT sensor visualization
├── blockchain.html            # 2755 lines - Blockchain integration
├── run.sh                      # Server launcher script
├── README.md                   # Project documentation
└── img/
    └── Cat-Lab.png           # Logo/mascot
```

---

## Test Utilities & Helpers

**Status**: None implemented.

For a project transitioning to testing, the following utilities would be needed:

### Recommended Testing Stack

Given the project uses:
- **React 18** — Components rendered in browser
- **p5.js** — Canvas-based visualization
- **Viem** — Web3 library
- **CDN-loaded dependencies** — No build step currently

**Recommended approach**: Browser-based testing with:
1. **Playwright** or **Cypress** — End-to-end testing (recommended for p5.js visualization testing)
2. **Vitest** + **@testing-library/react** — Unit/integration testing if code is refactored into modules
3. **jsdom** or similar — DOM mocking for component testing

---

## Mocking Patterns

### Current Application Mocking

The p5.html file includes **mock data presets** for sensor states:

```javascript
const mockDataPresets = {
    normal: { waterLevel: 0.5, airLevel: 2.0, isOnline: true, isDead: false },
    flooding: { waterLevel: 2.0, airLevel: 0.5, isOnline: true, isDead: false },
    dry: { waterLevel: 0, airLevel: 2.5, isOnline: true, isDead: false },
    offline: { waterLevel: 0.3, airLevel: 2.2, isOnline: false, isDead: false },
    dead: { waterLevel: 1.5, airLevel: 1.0, isOnline: false, isDead: true }
};
```

### Mockable Components

1. **p5.js Canvas** — Would need canvas snapshot testing or pixel comparison
2. **Viem Web3 Client** — Mock createPublicClient to avoid live network calls
3. **React State** — Preset values already exist; could be extracted into fixtures
4. **DOM Elements** — Buttons, sliders, and status displays

### Suggested Mock Strategy

```javascript
// Mock Viem to avoid network calls
jest.mock('https://esm.sh/viem@2.21.19', () => ({
  createPublicClient: jest.fn(() => ({
    getBalance: jest.fn(() => Promise.resolve(1000n))
  }))
}));

// Mock p5.js for unit tests (full p5.js testing in E2E)
jest.mock('p5', () => {
  return jest.fn().mockImplementation(() => ({
    setup: jest.fn(),
    draw: jest.fn(),
    remove: jest.fn()
  }));
});
```

---

## Coverage Approach

### Components Requiring Tests

#### 1. **SensorVisualizationP5 Component** (p5.html, lines 48-428)
   - **Type**: React component with p5.js integration
   - **Critical paths**:
     - Water level rendering (0-5m range)
     - Air distance measurement
     - Sensor status indicators (Online/Offline/Dead)
     - Installation height calibration
     - Mode switching (water ↔ air)
     - Visual animations (ripples, waves, LED pulses)

   **Test coverage needed** (60-70% target):
   - Props validation (waterLevel, airLevel, sensorMode, etc.)
   - State transitions between modes
   - Boundary conditions (water level = installation height)
   - p5.js lifecycle (setup → draw → cleanup)
   - Canvas rendering accuracy

#### 2. **App Component** (p5.html, lines 431-729)
   - **Type**: Main React component with state management
   - **State variables**: 7 (waterLevel, airLevel, sensorMode, installationHeight, showMeasurement, isOnline, isDead)
   - **Critical paths**:
     - Preset button interactions (5 presets)
     - Water level slider (0-5m)
     - Air level slider (0-3m)
     - Installation height adjuster (0.5-5m)
     - Mode toggle buttons

   **Test coverage needed** (70-80% target):
   - State initialization
   - Preset application logic
   - Slider boundary behavior
     - Water level clamped to installation height
     - Air level bounds enforcement
   - UI button responsiveness
   - Show/hide measurement toggle

#### 3. **Blockchain Demo** (blockchain.html)
   - **Type**: Complex interactive visualization
   - **Size**: 2755 lines (too large for quick analysis without full read)
   - **Estimated coverage**: 40-50% initially

---

## CI Workflow

### Current Status
**No CI/CD pipeline exists** — No `.github/workflows/` directory.

### Recommended CI Setup

#### Basic GitHub Actions Workflow
```yaml
# .github/workflows/test.yml
name: Test & Build

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm install
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/coverage-final.json
```

#### Recommended Scripts (package.json additions)
```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "serve": "python3 -m http.server 3000"
  },
  "devDependencies": {
    "vitest": "^2.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/dom": "^10.0.0",
    "playwright": "^1.40.0",
    "@vitest/coverage-v8": "^2.0.0"
  }
}
```

---

## Minimal Test Plan

For this project to have basic test coverage, implement tests in this order:

### Phase 1: Unit Tests (Week 1)
**Focus**: Core logic, not visualization

1. **App Component State Management**
   - Test initial state values
   - Test preset application (5 scenarios)
   - Test water level clamping (when water > installation height)
   - Test slider boundary conditions
   - **Target**: 10-12 test cases

2. **Sensor Visualization Props Handling**
   - Test prop validation and defaults
   - Test mode switching logic (water ↔ air)
   - Test LED indicator color selection based on status
   - **Target**: 8-10 test cases

### Phase 2: Integration Tests (Week 2)
**Focus**: Component interaction and state flow

1. **User Interaction Flow**
   - Click preset button → state updates correctly
   - Drag slider → state clamps appropriately
   - Toggle mode → visualization updates
   - **Target**: 8-10 test cases

2. **Component Lifecycle**
   - p5 instance creation and cleanup
   - Re-renders on prop changes
   - Memory leak prevention
   - **Target**: 5-6 test cases

### Phase 3: E2E Tests (Week 3)
**Focus**: Full user workflows in real browser

1. **Sensor Visualization Rendering**
   - Visual regression testing (screenshot comparison)
   - Canvas contains expected elements (sensor, base, arm)
   - LED indicators animate correctly
   - **Target**: 4-5 test scenarios

2. **User Workflows**
   - Open page → visualize default state
   - Click "Flooding" preset → water fills to 80%
   - Switch to Air mode → air measurement displays
   - Adjust installation height → water level adjusts
   - **Target**: 4-5 test scenarios

### Phase 4: Coverage Targets
- **Unit tests**: Aim for 70%+ coverage
- **Integration tests**: Aim for 80%+ coverage
- **E2E tests**: 5-7 critical user workflows

---

## Implementation Recommendations

### Short-term (Quick Win)
1. Add `package.json` to project
2. Set up Vitest + @testing-library/react
3. Create `src/` directory and extract components
4. Write 10-15 unit tests for App component state

### Medium-term (Maintainability)
5. Refactor p5.js sketch into a custom hook (useP5Sketch)
6. Extract mock data into a separate constants file
7. Add E2E tests with Playwright for critical workflows
8. Set up GitHub Actions CI pipeline

### Long-term (Best Practices)
9. Add TypeScript support for type safety
10. Document test patterns and mock strategies
11. Implement visual regression testing
12. Achieve 80%+ code coverage

---

## Summary

| Aspect | Status | Notes |
|--------|--------|-------|
| **Test Framework** | None | Recommend: Vitest + Playwright |
| **Test Files** | 0 | No .test.js, .spec.js files |
| **Test Utilities** | None | Mock data presets exist; good foundation |
| **Mocking Patterns** | Ad-hoc | Presets in component; needs centralization |
| **Coverage Tool** | None | Recommend: @vitest/coverage-v8 |
| **CI/CD** | None | No .github/workflows/ found |
| **Testable Code** | Low | HTML+JS mixed; refactoring needed |

### Next Steps
1. Choose testing stack (Vitest + Playwright recommended)
2. Create testing documentation and setup guide
3. Extract mock data and utilities
4. Implement Phase 1 unit tests
5. Set up CI/CD pipeline

