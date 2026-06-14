const driverFactory = require('../drivers/driverFactory');
const logger = require('../utils/logger');
const gestures = require('../utils/gestures');
const path = require('path');
const fs = require('fs');

class BasePage {
  constructor() {
    this.gestures = gestures;
  }

  /**
   * Getter for active driver.
   */
  get driver() {
    const drv = driverFactory.getDriver();
    if (!drv) {
      throw new Error('Driver session is not initialized. Call driverFactory.createDriver() first.');
    }
    this.gestures.setDriver(drv);
    return drv;
  }

  /**
   * Helper to construct unified locators.
   */
  locator(type, value) {
    return { type, value };
  }

  /**
   * Base64 encoder for Flutter Finders.
   */
  encodeFinder(finderObj) {
    return Buffer.from(JSON.stringify(finderObj)).toString('base64');
  }

  /**
   * Resolves a unified locator to a selector string based on active driver mode.
   * @param {Object} locatorObj 
   */
  resolveLocator(locatorObj) {
    const mode = driverFactory.getMode();
    const { type, value } = locatorObj;

    if (mode === 'flutter') {
      switch (type) {
        case 'key':
          return this.encodeFinder({ finderType: 'ByValueKey', keyValueString: value, keyValueType: 'String' });
        case 'text':
          return this.encodeFinder({ finderType: 'ByText', text: value });
        case 'semantics':
          return this.encodeFinder({ finderType: 'BySemanticsLabel', label: value });
        case 'type':
          return this.encodeFinder({ finderType: 'ByType', type: value });
        default:
          return value; // raw string fallback
      }
    } else {
      // UiAutomator2 fallback mappings
      switch (type) {
        case 'key':
          // In Flutter on Android, keys are often mapped to resource-id or accessibility id
          return `//*[@resource-id="${value}" or @content-desc="${value}"]`;
        case 'text':
          return `//*[@text="${value}"]`;
        case 'semantics':
          return `~${value}`;
        case 'xpath':
          return value;
        default:
          return value;
      }
    }
  }

  /**
   * Finds an element using unified locator.
   */
  async getElement(locatorObj) {
    const selector = this.resolveLocator(locatorObj);
    return await this.driver.$(selector);
  }

  /**
   * Waits for an element to be displayed.
   */
  async waitForDisplayed(locatorObj, timeoutMs = 15000) {
    const el = await this.getElement(locatorObj);
    await el.waitForDisplayed({ timeout: timeoutMs });
    return el;
  }

  /**
   * Clicks on an element.
   */
  async click(locatorObj) {
    logger.info(`Clicking on element [${locatorObj.type}: ${locatorObj.value}]`);
    const el = await this.waitForDisplayed(locatorObj);
    await el.click();
  }

  /**
   * Enters text into a text field.
   */
  async setValue(locatorObj, value) {
    logger.info(`Setting value of element [${locatorObj.type}: ${locatorObj.value}] to: "${value}"`);
    const el = await this.waitForDisplayed(locatorObj);
    await el.setValue(value);
  }

  /**
   * Retrieves text of an element.
   */
  async getText(locatorObj) {
    logger.info(`Getting text of element [${locatorObj.type}: ${locatorObj.value}]`);
    const el = await this.waitForDisplayed(locatorObj);
    return await el.getText();
  }

  /**
   * Verifies if element is displayed on screen.
   */
  async isDisplayed(locatorObj) {
    try {
      const el = await this.getElement(locatorObj);
      return await el.isDisplayed();
    } catch (err) {
      return false;
    }
  }

  /**
   * Captures screen and saves it on test failure.
   * @param {string} testName 
   * @returns {string} The path to the saved screenshot.
   */
  async takeScreenshotOnFailure(testName) {
    try {
      const sanitizedName = testName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      const failDir = path.resolve(__dirname, '../reports/failures');
      if (!fs.existsSync(failDir)) {
        fs.mkdirSync(failDir, { recursive: true });
      }
      const screenshotPath = path.join(failDir, `${sanitizedName}_fail.png`);
      
      // Capture screenshot
      await this.driver.saveScreenshot(screenshotPath);
      logger.info(`Screenshot captured for failed test [${testName}] at: ${screenshotPath}`);
      return screenshotPath;
    } catch (err) {
      logger.error(`Failed to capture failure screenshot: ${err.message}`);
      return '';
    }
  }

  /**
   * Captures device logcat output.
   * @param {string} testName 
   */
  async saveDeviceLogs(testName) {
    try {
      const sanitizedName = testName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      const failDir = path.resolve(__dirname, '../reports/failures');
      const logPath = path.join(failDir, `${sanitizedName}_device.log`);
      
      // Retrieve logs
      const logTypes = await this.driver.getLogTypes();
      if (logTypes.includes('logcat')) {
        const logs = await this.driver.getLogs('logcat');
        const formattedLogs = logs.map(l => `[${new Date(l.timestamp).toISOString()}] [${l.level}]: ${l.message}`).join('\n');
        fs.writeFileSync(logPath, formattedLogs);
        logger.info(`Device logcat successfully dumped at: ${logPath}`);
      }
    } catch (err) {
      logger.warn(`Failed to capture device logcat: ${err.message}`);
    }
  }

  /**
   * Captures Flutter widget diagnostics tree if VM is active.
   */
  async saveWidgetTree(testName) {
    if (driverFactory.getMode() !== 'flutter') return;
    try {
      const sanitizedName = testName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      const failDir = path.resolve(__dirname, '../reports/failures');
      const treePath = path.join(failDir, `${sanitizedName}_widget_tree.json`);
      
      const widgetTree = await this.driver.execute('flutter:getRenderTree');
      fs.writeFileSync(treePath, JSON.stringify(widgetTree, null, 2));
      logger.info(`Flutter widget tree diagnostics successfully dumped at: ${treePath}`);
    } catch (err) {
      logger.warn(`Failed to capture Flutter diagnostics tree: ${err.message}`);
    }
  }
}

module.exports = BasePage;
