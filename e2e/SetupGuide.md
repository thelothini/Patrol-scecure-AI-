# E2E Automation Setup & Execution Guide

Follow this detailed setup guide to configure your machine, install required drivers, compile the app, and run the E2E test suite.

---

## 1. Environment Setup

### A. Java Development Kit (JDK)
1. Download and install **JDK 17** (or 11) from [Oracle](https://www.oracle.com/java/technologies/downloads/) or [Adoptium](https://adoptium.net/).
2. Add Java to your system environment variables:
   - Variable Name: `JAVA_HOME`
   - Variable Value: `C:\Program Files\Eclipse Foundation\jdk-17.x.x` (or your JDK installation path)
3. Add `%JAVA_HOME%\bin` (or `$JAVA_HOME/bin` on Mac/Linux) to your system path.

### B. Android SDK & Command Line Tools
1. Install **Android Studio**.
2. Open Android Studio SDK Manager, download:
   - Android SDK Platform (API Level 30 or above recommended)
   - Android SDK Build-Tools
   - Android SDK Platform-Tools (contains `adb.exe`)
3. Set Android Environment Variables:
   - Variable Name: `ANDROID_HOME`
   - Variable Value: `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`
4. Add the following to your system path:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\emulator`
   - `%ANDROID_HOME%\tools\bin`

### C. Node.js
1. Download and install **Node.js** (v18+ recommended) from [nodejs.org](https://nodejs.org/).
2. Verify:
   ```bash
   node -v
   npm -v
   ```

---

## 2. Appium 2.x Configuration

1. Install **Appium 2.x** globally:
   ```bash
   npm install -g appium@next
   ```
2. Install the **UiAutomator2** driver:
   ```bash
   appium driver install uiautomator2
   ```
3. Install the **Flutter Driver**:
   ```bash
   appium driver install --source=npm appium-flutter-driver
   ```
4. Check installed drivers:
   ```bash
   appium driver list
   ```

---

## 3. Building the PatrolSecure Test APK

For the Flutter Driver to operate correctly, the APK must be built in **Debug** or **Profile** mode, as Release mode strips the VM service/Observatory endpoint required for widget element lookup.

1. Navigate to the root directory of the Flutter project.
2. Compile a debug build:
   ```bash
   flutter build apk --debug
   ```
3. Create an `app` folder in the project root (if not exists) and copy the built APK:
   ```bash
   mkdir app
   cp build/app/outputs/flutter-apk/app-debug.apk ./app/app-release.apk
   ```

---

## 4. Launching the Emulator & Test Run

1. Open Android Studio AVD Manager and launch an emulator (API 30+ recommended).
2. Verify the emulator is active via ADB:
   ```bash
   adb devices
   ```
3. Start the Appium server in a terminal window:
   ```bash
   appium
   ```
4. In a separate terminal window, run the tests:
   ```bash
   cd e2e
   npm install
   
   # Run the primary E2E tests (Auth & Forms)
   npm test
   
   # Run the AI-assisted explorer tests
   npm run test:ai
   ```

---

## 5. Troubleshooting & Tips

- **Port Forwarding Error:** The Driver Factory runs `adb forward tcp:9900 tcp:9900` automatically. If you see a port-in-use error, clear the port forward:
  ```bash
  adb forward --remove-all
  ```
- **Flutter Driver Timeout:** If the Flutter driver times out connecting to the VM Observatory, make sure the app was compiled with `--debug` or `--profile` and that the emulator has active internet access.
- **Inspect Layouts:** You can use **Appium Inspector** to inspect layouts. To inspect Flutter elements in Appium Inspector, set your capability `automationName` to `Flutter`. To inspect native accessibility nodes, set `automationName` to `UiAutomator2`.
