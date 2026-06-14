# PatrolSecure - Appium E2E Automation Framework

This directory houses the complete, enterprise-grade E2E mobile automation framework for testing the **PatrolSecure** Campus Discipline Management application on Android.

---

## Architecture Overview

The framework follows the industry-standard **Page Object Model (POM)** design pattern to cleanly segregate page identifiers and interaction workflows from test assertions.

```
e2e/
├── config/
│   └── appium.config.js         # Port mapping, timeouts, and device capabilities
├── drivers/
│   └── driverFactory.js         # Driver setup, ADB port forwarding, and fallback handling
├── utils/
│   ├── logger.js                # Winston console and file logger
│   ├── gestures.js              # W3C pointer actions and gestures mapping
│   ├── reportGenerator.js       # ExcelJS test suite compiler
│   └── htmlReporter.js          # Standalone dark-themed dashboard builder
├── pages/
│   ├── basePage.js              # Base Page Object with locator resolvers
│   ├── loginPage.js             # LoginPage POM
│   ├── signupPage.js            # SignupPage POM
│   └── reportPage.js            # Incident Report POM
├── ai/
│   └── smartExplorer.js         # Smart AI-assisted layout explorer
├── test/
│   └── specs/
│       ├── setup.js             # Mocha lifecycle hooks and failure listener
│       ├── auth.spec.js         # Authentication validation tests
│       ├── form.spec.js         # UI widgets and validation checks
│       └── aiExplorer.spec.js   # Smart AI exploration tests
└── package.json                 # Node dependencies and runner scripts
```

---

## Core Features

1. **Dual-Mode Automation Engine:** 
   - Uses `appium-flutter-driver` for key and text-based widget queries (for debug/profile builds).
   - Automatically falls back to `UiAutomator2` for testing release APK builds using accessibility IDs, semantic values, and screen text mappings.
2. **Dynamic UI/Gesture Handler:** Emulates taps, double-taps, drags, swipes, pinch-to-zoom, and scrolls through unified W3C pointer action flows.
3. **Smart AI Testing Explorer:** Automatically crawls viewports, classifies input fields, applies mock validations (emails, passwords, sizes), and maps routes dynamically.
4. **Rich Multi-Format Reporting:**
   - Generates a compiled Excel workbook (`reports/Flutter_E2E_Report.xlsx`) with 4 distinct sheets (Summary, Test Cases, Failures, Steps).
   - Compiles a modern dark-themed HTML report dashboard (`reports/index.html`) featuring interactive graphs and embedded failure screenshots.
5. **Robust Failure Hook Diagnostics:** Captures screenshots, device `logcat` streams, and Flutter VM widget render trees automatically on assertion failures.

---

## Prerequisites

- **Node.js** (v16+)
- **Android SDK** (with ADB added to your environment `PATH`)
- **Appium 2.x** installed globally:
  ```bash
  npm install -g appium
  appium driver install uiautomator2
  appium driver install --source=npm appium-flutter-driver
  ```
- **Java JDK 11+**
- Active Android emulator or connected device.

---

## Quickstart

1. **Install Dependencies:**
   ```bash
   cd e2e
   npm install
   ```

2. **Configure Environment:**
   Create an `e2e/.env` file to customize properties (optional):
   ```env
   APK_PATH=../app/app-release.apk
   APP_PACKAGE=com.example.patrol_secure
   APP_ACTIVITY=.MainActivity
   DEVICE_NAME=My_Android_Emulator
   ```

3. **Compile Test APK (Optional):**
   ```bash
   flutter build apk --debug
   mkdir -p ../app
   cp ../build/app/outputs/flutter-apk/app-debug.apk ../app/app-release.apk
   ```

4. **Run Automation Tests:**
   Start your emulator, then run:
   ```bash
   # Run primary test specs (Auth & Forms)
   npm test
   
   # Run AI Explorer suite
   npm run test:ai
   ```

5. **Review Reports:**
   Open the reports inside a browser:
   - `e2e/reports/index.html`
   - `e2e/reports/Flutter_E2E_Report.xlsx`
   - Failure artifacts (if any): `e2e/reports/failures/`
