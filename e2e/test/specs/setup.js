const driverFactory = require('../../drivers/driverFactory');
const reportGenerator = require('../../utils/reportGenerator');
const htmlReporter = require('../../utils/htmlReporter');
const logger = require('../../utils/logger');
const loginPage = require('../../pages/loginPage');

// Initialize global accumulator
global.testResults = {
  summary: {
    executionDate: new Date().toLocaleDateString() + ' ' + new Date().toLocaleTimeString(),
    deviceName: process.env.DEVICE_NAME || 'Android Emulator',
    androidVersion: process.env.ANDROID_VERSION || '12.0',
    totalTests: 0,
    passed: 0,
    failed: 0,
    skipped: 0,
    duration: 0
  },
  testCases: [],
  failedTests: [],
  logs: []
};

// Global step logger helper
global.logStep = (testName, step, result, remarks = '') => {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  global.testResults.logs.push({
    timestamp,
    testName,
    step,
    result,
    remarks
  });
  logger.info(`[Step] [${testName}] - ${step} - [${result}] - ${remarks}`);
};

let suiteStartTime;

before(async function() {
  this.timeout(180000);
  suiteStartTime = Date.now();
  logger.info('Global before hook: Starting Appium automation driver...');
  await driverFactory.createDriver();
  
  // Update actual device properties dynamically if driver is available
  const driverObj = driverFactory.getDriver();
  if (driverObj) {
    try {
      const caps = await driverObj.getCapabilities();
      global.testResults.summary.deviceName = caps.deviceName || caps.deviceModel || process.env.DEVICE_NAME || 'Android Emulator';
      global.testResults.summary.androidVersion = caps.platformVersion || process.env.ANDROID_VERSION || '12.0';
    } catch (e) {
      logger.warn(`Failed to query active session capabilities: ${e.message}`);
    }
  }
});

let testStartTime;

beforeEach(function() {
  testStartTime = Date.now();
});

afterEach(async function() {
  const duration = Date.now() - testStartTime;
  const state = this.currentTest.state || 'skipped';
  const testName = this.currentTest.title;
  const testId = 'TC_' + String(global.testResults.testCases.length + 1).padStart(3, '0');
  const moduleName = this.currentTest.parent.title || 'General';

  global.testResults.summary.totalTests += 1;

  if (state === 'passed') {
    global.testResults.summary.passed += 1;
    global.testResults.testCases.push({
      id: testId,
      module: moduleName,
      scenario: testName,
      status: 'Passed',
      device: global.testResults.summary.deviceName,
      duration
    });
    global.logStep(testName, 'Test Execution', 'Pass', 'Executed successfully');
  } else if (state === 'failed') {
    global.testResults.summary.failed += 1;
    global.testResults.testCases.push({
      id: testId,
      module: moduleName,
      scenario: testName,
      status: 'Failed',
      device: global.testResults.summary.deviceName,
      duration
    });

    const errorMsg = this.currentTest.err ? this.currentTest.err.stack || this.currentTest.err.message : 'Unknown Error';
    global.logStep(testName, 'Test Execution', 'Fail', errorMsg);

    // Save Failure Artifacts
    const screenshotPath = await loginPage.takeScreenshotOnFailure(testName);
    await loginPage.saveDeviceLogs(testName);
    await loginPage.saveWidgetTree(testName);

    global.testResults.failedTests.push({
      name: testName,
      reason: errorMsg,
      screenshotPath: screenshotPath,
      device: global.testResults.summary.deviceName,
      androidVersion: global.testResults.summary.androidVersion
    });
  } else {
    global.testResults.summary.skipped += 1;
    global.testResults.testCases.push({
      id: testId,
      module: moduleName,
      scenario: testName,
      status: 'Skipped',
      device: global.testResults.summary.deviceName,
      duration: 0
    });
    global.logStep(testName, 'Test Execution', 'Skip', 'Test skipped');
  }
});

after(async function() {
  this.timeout(60000);
  global.testResults.summary.duration = Date.now() - suiteStartTime;
  
  logger.info('Global after hook: shutting down driver...');
  await driverFactory.quitDriver();

  // Generate Reports
  try {
    await reportGenerator.generateReport(global.testResults);
    await htmlReporter.generateHtml(global.testResults);
  } catch (err) {
    logger.error(`Failed to compile E2E execution reports: ${err.message}`);
  }
});
