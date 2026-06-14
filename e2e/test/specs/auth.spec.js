const { expect } = require('chai');
const loginPage = require('../../pages/loginPage');
const reportPage = require('../../pages/reportPage');

describe('Authentication Testing', function() {
  
  it('Should validate empty login fields', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Opening Login Screen');
    
    // Attempt login with empty fields
    global.logStep(this.test.title, 'Step 2', 'Info', 'Submitting empty login form');
    await loginPage.clickSignIn();

    // Verify field validation error texts are displayed
    global.logStep(this.test.title, 'Step 3', 'Info', 'Checking validation error messages');
    const emailErr = loginPage.locator('text', 'Email required');
    const passErr = loginPage.locator('text', 'Password required');
    
    expect(await loginPage.isDisplayed(emailErr)).to.be.true;
    expect(await loginPage.isDisplayed(passErr)).to.be.true;
    
    global.logStep(this.test.title, 'Validation Check', 'Pass', 'Required fields validation messages appeared successfully');
  });

  it('Should validate error on invalid credentials login', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Entering incorrect login credentials');
    await loginPage.enterEmail('wrong-teacher@college.edu');
    await loginPage.enterPassword('invalid_password');
    await loginPage.enterDeviceName('E2E Emulator S24');

    global.logStep(this.test.title, 'Step 2', 'Info', 'Submitting login request');
    await loginPage.clickSignIn();

    // Verify error feedback is triggered (either server connectivity message or invalid credentials notification)
    global.logStep(this.test.title, 'Step 3', 'Info', 'Waiting for validation snackbar or alert dialog');
    const errorText = loginPage.locator('xpath', '//*[contains(@text, "Login failed") or contains(@text, "server") or contains(@text, "Network")]');
    const errorDisplayed = await loginPage.isDisplayed(errorText);
    
    // For local test setups, we expect the connection fallback or validation prompt to surface
    expect(errorDisplayed).to.be.true;
    global.logStep(this.test.title, 'Feedback Check', 'Pass', 'Error message display validated');
  });

  it('Should display and handle device/location mismatch dialog', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Simulating device mismatch login trigger');
    // We enter credentials designed to cause device verification mismatch (triggers 403 status code)
    await loginPage.enterEmail('mismatch-device@college.edu');
    await loginPage.enterPassword('Password123');
    await loginPage.clickSignIn();

    global.logStep(this.test.title, 'Step 2', 'Info', 'Checking for verification dialog popup');
    const isDialogShown = await loginPage.isMismatchDialogVisible();
    expect(isDialogShown).to.be.true;

    global.logStep(this.test.title, 'Step 3', 'Info', 'Submitting device access request from dialog');
    await loginPage.clickRequestAccess();

    const successSnackbar = loginPage.locator('xpath', '//*[contains(@text, "submitted") or contains(@text, "admin")]');
    expect(await loginPage.isDisplayed(successSnackbar)).to.be.true;
    global.logStep(this.test.title, 'Request Check', 'Pass', 'Access request successfully raised from mismatch dialog');
  });

  it('Should successfully login with valid credentials', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Entering authorized teacher account credentials');
    await loginPage.enterEmail('admin@college.edu');
    await loginPage.enterPassword('AdminSecurePass!');
    await loginPage.enterDeviceName('Samsung Galaxy S23');
    
    global.logStep(this.test.title, 'Step 2', 'Info', 'Clicking Sign In button');
    await loginPage.clickSignIn();

    global.logStep(this.test.title, 'Step 3', 'Info', 'Verifying navigation to dashboard screen');
    const homeHeader = loginPage.locator('text', 'QUICK ACTIONS');
    const isDashboardLoaded = await loginPage.isDisplayed(homeHeader);
    
    expect(isDashboardLoaded).to.be.true;
    global.logStep(this.test.title, 'Navigation Check', 'Pass', 'Successfully navigated to HomeScreen dashboard');
  });

  it('Should successfully logout and clear active session', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Triggering logout sequence from dashboard');
    await reportPage.logout();

    global.logStep(this.test.title, 'Step 2', 'Info', 'Confirming redirection to Login screen');
    const loginTitle = loginPage.locator('text', 'Welcome\nBack');
    expect(await loginPage.isDisplayed(loginTitle)).to.be.true;
    
    global.logStep(this.test.title, 'Session Check', 'Pass', 'User session terminated and redirected to login gateway');
  });

});
