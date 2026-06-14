const BasePage = require('./basePage');

class SignupPage extends BasePage {
  constructor() {
    super();
    // Element definitions
    this.nameField = this.locator('text', 'Full Name');
    this.idField = this.locator('text', 'Teacher ID');
    this.emailField = this.locator('text', 'Email Address');
    this.phoneField = this.locator('text', 'Phone Number');
    this.departmentDropdown = this.locator('text', 'Department');
    this.deviceField = this.locator('text', 'Device Name');
    this.passwordField = this.locator('text', 'Password');
    this.confirmPasswordField = this.locator('text', 'Confirm Password');
    this.createAccountButton = this.locator('text', 'CREATE ACCOUNT');
    this.signInLink = this.locator('text', 'Sign In');
  }

  async enterName(name) {
    await this.setValue(this.nameField, name);
  }

  async enterTeacherId(id) {
    await this.setValue(this.idField, id);
  }

  async enterEmail(email) {
    await this.setValue(this.emailField, email);
  }

  async enterPhone(phone) {
    await this.setValue(this.phoneField, phone);
  }

  async selectDepartment(dept) {
    await this.click(this.departmentDropdown);
    // Locate the department option in the dropdown popup
    const deptOption = this.locator('text', dept);
    await this.click(deptOption);
  }

  async enterDeviceName(device) {
    await this.setValue(this.deviceField, device);
  }

  async enterPassword(password) {
    await this.setValue(this.passwordField, password);
  }

  async enterConfirmPassword(password) {
    await this.setValue(this.confirmPasswordField, password);
  }

  async clickCreateAccount() {
    await this.click(this.createAccountButton);
  }

  async clickSignIn() {
    await this.click(this.signInLink);
  }

  /**
   * Helper to execute a complete signup action
   */
  async register(details) {
    if (details.name) await this.enterName(details.name);
    if (details.id) await this.enterTeacherId(details.id);
    if (details.email) await this.enterEmail(details.email);
    if (details.phone) await this.enterPhone(details.phone);
    if (details.dept) await this.selectDepartment(details.dept);
    if (details.deviceName) await this.enterDeviceName(details.deviceName);
    if (details.password) await this.enterPassword(details.password);
    if (details.confirmPassword) await this.enterConfirmPassword(details.confirmPassword);
    await this.clickCreateAccount();
  }
}

module.exports = new SignupPage();
