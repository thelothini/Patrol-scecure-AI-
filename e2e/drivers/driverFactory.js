const { remote } = require('webdriverio');
const { execSync } = require('child_process');
const config = require('../config/appium.config');
const logger = require('../utils/logger');

class DriverFactory {
  constructor() {
    this.driver = null;
    this.currentMode = null; // 'flutter' or 'uiautomator2'
  }

  /**
   * Auto-detects connected Android devices/emulators via ADB.
   * @returns {string|null} The device UDID or null if none found.
   */
  detectDevice() {
    try {
      logger.info('Auto-detecting connected devices/emulators...');
      const output = execSync('adb devices').toString();
      const lines = output.split('\n');
      const devices = [];
      
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line && !line.startsWith('*') && line.includes('\tdevice')) {
          const udid = line.split('\t')[0].trim();
          devices.push(udid);
        }
      }

      if (devices.length > 0) {
        logger.info(`Detected active device(s): ${devices.join(', ')}`);
        return devices[0];
      }
      logger.warn('No active devices found via ADB. Let Appium handle device selection.');
      return null;
    } catch (error) {
      logger.warn(`Failed to execute ADB devices: ${error.message}. Continuing...`);
      return null;
    }
  }

  /**
   * Forwards the Flutter Observatory VM port to local machine.
   * @param {string} deviceUdid 
   */
  setupPortForwarding(deviceUdid) {
    try {
      logger.info('Setting up port forwarding for Flutter VM Observatory (tcp:9900)...');
      const deviceArg = deviceUdid ? `-s ${deviceUdid}` : '';
      execSync(`adb ${deviceArg} forward tcp:9900 tcp:9900`);
      logger.info('Port forwarding successfully set up.');
    } catch (error) {
      logger.warn(`Port forwarding failed: ${error.message}. Flutter driver might not connect.`);
    }
  }

  /**
   * Starts a mobile automation session.
   * Attempts Flutter Driver first, falling back to UiAutomator2 on failure.
   */
  async createDriver() {
    const activeDevice = this.detectDevice();
    
    // Setup capabilities overrides if device detected
    const flutterCaps = { ...config.capabilities.flutter };
    const uiaCaps = { ...config.capabilities.uiautomator2 };

    if (activeDevice) {
      flutterCaps['appium:udid'] = activeDevice;
      uiaCaps['appium:udid'] = activeDevice;
    }

    // 1. Attempt Flutter Driver session
    try {
      logger.info('Starting Appium session using: Flutter Driver...');
      if (activeDevice) {
        this.setupPortForwarding(activeDevice);
      } else {
        this.setupPortForwarding();
      }

      const options = {
        hostname: config.server.hostname,
        port: config.server.port,
        path: config.server.path,
        capabilities: flutterCaps
      };

      this.driver = await remote(options);
      this.currentMode = 'flutter';
      logger.info('Flutter Driver session established successfully.');
      return this.driver;
    } catch (flutterError) {
      logger.warn(`Failed to start session with Flutter Driver: ${flutterError.message}`);
      logger.info('Initiating fallback mechanism: switching to UiAutomator2...');

      // 2. Fallback to UiAutomator2
      try {
        const options = {
          hostname: config.server.hostname,
          port: config.server.port,
          path: config.server.path,
          capabilities: uiaCaps
        };

        this.driver = await remote(options);
        this.currentMode = 'uiautomator2';
        logger.info('UiAutomator2 fallback session established successfully.');
        return this.driver;
      } catch (uiaError) {
        logger.error(`Failed to start fallback UiAutomator2 session: ${uiaError.message}`);
        throw new Error(`Automation Session Creation Failed: Both Flutter Driver and UiAutomator2 failed. ${uiaError.message}`);
      }
    }
  }

  /**
   * Tears down the current active session.
   */
  async quitDriver() {
    if (this.driver) {
      logger.info('Tearing down Appium session...');
      try {
        await this.driver.deleteSession();
        logger.info('Session ended successfully.');
      } catch (error) {
        logger.error(`Error during session tear down: ${error.message}`);
      } finally {
        this.driver = null;
        this.currentMode = null;
      }
    }
  }

  /**
   * Retrieves active driver context.
   */
  getDriver() {
    return this.driver;
  }

  /**
   * Returns current automation mode ('flutter' or 'uiautomator2').
   */
  getMode() {
    return this.currentMode;
  }
}

module.exports = new DriverFactory();
