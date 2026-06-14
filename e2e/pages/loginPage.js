const BasePage = require('./basePage');

class LoginPage extends BasePage {
  constructor() {
    super();
    // Element definitions
    this.emailField = this.locator('text', 'Email Address');
    this.passwordField = this.locator('text', 'Password');
    this.deviceField = this.locator('text', 'Device Name');
    this.signInButton = this.locator('text', 'SIGN IN');
    this.registerLink = this.locator('text', 'Register Now');
    
    // GPS Status Text
    this.gpsChip = this.locator('xpath', '//*[contains(@text, "Location") or contains(@text, "Fetching")]');

    // Dialog locators
    this.deviceMismatchTitle = this.locator('text', 'Device Mismatch');
    this.locationMismatchTitle = this.locator('text', 'Location Mismatch');
    this.requestAccessButton = this.locator('text', 'Request Access');
    this.cancelDialogButton = this.locator('text', 'Cancel');
  }

  async enterEmail(email) {
    await this.setValue(this.emailField, email);
  }

  async enterPassword(password) {
    await this.setValue(this.passwordField, password);
  }

  async enterDeviceName(deviceName) {
    await this.setValue(this.deviceField, deviceName);
  }

  async clickSignIn() {
    await this.click(this.signInButton);
  }

  async clickRegisterNow() {
    await this.click(this.registerLink);
  }

  async getGPSStatus() {
    try {
      return await this.getText(this.gpsChip);
    } catch (e) {
      return 'Unknown';
    }
  }

  async isMismatchDialogVisible() {
    const isDeviceVisible = await this.isDisplayed(this.deviceMismatchTitle);
    const isLocVisible = await this.isDisplayed(this.locationMismatchTitle);
    return isDeviceVisible || isLocVisible;
  }

  async clickRequestAccess() {
    await this.click(this.requestAccessButton);
  }

  async clickCancelDialog() {
    await this.click(this.cancelDialogButton);
  }

  /**
   * Helper to perform complete login workflow.
   */
  async login(email, password, deviceName = null) {
    await this.enterEmail(email);
    await this.enterPassword(password);
    if (deviceName) {
      await this.enterDeviceName(deviceName);
    }
    await this.clickSignIn();
  }
}

module.exports = new LoginPage();
