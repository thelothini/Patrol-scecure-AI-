require('dotenv').config();
const path = require('path');

const APK_PATH = process.env.APK_PATH || path.resolve(__dirname, '../../app/app-release.apk');
const APP_PACKAGE = process.env.APP_PACKAGE || 'com.company.app';
const APP_ACTIVITY = process.env.APP_ACTIVITY || 'com.company.app.MainActivity';
const APPIUM_HOST = process.env.APPIUM_HOST || '127.0.0.1';
const APPIUM_PORT = parseInt(process.env.APPIUM_PORT || '4723', 10);

module.exports = {
  server: {
    hostname: APPIUM_HOST,
    port: APPIUM_PORT,
    path: '/'
  },
  // Driver Capabilities
  capabilities: {
    flutter: {
      platformName: 'Android',
      'appium:automationName': 'Flutter',
      'appium:deviceName': process.env.DEVICE_NAME || 'Android Emulator',
      'appium:app': APK_PATH,
      'appium:appPackage': APP_PACKAGE,
      'appium:appActivity': APP_ACTIVITY,
      'appium:noReset': false,
      'appium:fullReset': false,
      'appium:newCommandTimeout': 300,
      'appium:gpsEnabled': true,
      'appium:autoGrantPermissions': true
    },
    uiautomator2: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': process.env.DEVICE_NAME || 'Android Emulator',
      'appium:app': APK_PATH,
      'appium:appPackage': APP_PACKAGE,
      'appium:appActivity': APP_ACTIVITY,
      'appium:noReset': false,
      'appium:fullReset': false,
      'appium:newCommandTimeout': 300,
      'appium:gpsEnabled': true,
      'appium:autoGrantPermissions': true,
      'appium:ensureWebviewsHavePages': true,
      'appium:nativeWebScreenshot': true
    }
  },
  timeouts: {
    implicit: 10000,
    elementWait: 15000
  }
};
