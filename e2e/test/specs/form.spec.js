const { expect } = require('chai');
const loginPage = require('../../pages/loginPage');
const signupPage = require('../../pages/signupPage');
const reportPage = require('../../pages/reportPage');

describe('Form Validation and UI Component Testing', function() {

  it('Should validate required fields on Registration Screen', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Navigating to registration view');
    await loginPage.clickRegisterNow();

    global.logStep(this.test.title, 'Step 2', 'Info', 'Submitting empty registration form');
    await signupPage.clickCreateAccount();

    global.logStep(this.test.title, 'Step 3', 'Info', 'Verifying required field validation warnings');
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Name required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Teacher ID required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Email required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Phone required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Device name required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Password required'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Confirm password required'))).to.be.true;

    global.logStep(this.test.title, 'Required Checks', 'Pass', 'Registration screen empty field constraints verified successfully');
  });

  it('Should validate email and phone format constraints', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Entering malformed email and phone strings');
    await signupPage.enterEmail('malformedEmailString');
    await signupPage.enterPhone('12345'); // shorter than 10 digits
    await signupPage.clickCreateAccount();

    global.logStep(this.test.title, 'Step 2', 'Info', 'Validating email and phone warning banners');
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Enter valid email'))).to.be.true;
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Enter valid phone number'))).to.be.true;
    
    global.logStep(this.test.title, 'Format Checks', 'Pass', 'Constraint formats checked and blocked correctly');
  });

  it('Should validate password length limits and matching validations', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Entering too short password');
    await signupPage.enterPassword('123');
    await signupPage.clickCreateAccount();
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Minimum 6 characters'))).to.be.true;

    global.logStep(this.test.title, 'Step 2', 'Info', 'Entering mismatching confirm passwords');
    await signupPage.enterPassword('PassSecret123');
    await signupPage.enterConfirmPassword('MismatchSecret321');
    await signupPage.clickCreateAccount();
    expect(await signupPage.isDisplayed(signupPage.locator('text', 'Passwords do not match'))).to.be.true;

    global.logStep(this.test.title, 'Password Checks', 'Pass', 'Password rules and comparisons validated');
  });

  it('Should successfully complete registration via form submit', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Filling complete valid registration credentials');
    await signupPage.enterName('Teacher E2E Test');
    await signupPage.enterTeacherId('T-E2E-100');
    await signupPage.enterEmail('e2e-teacher@college.edu');
    await signupPage.enterPhone('9876543210');
    
    global.logStep(this.test.title, 'Step 2', 'Info', 'Selecting department from dropdown component');
    await signupPage.selectDepartment('CSE');
    
    await signupPage.enterDeviceName('Samsung Galaxy S23');
    await signupPage.enterPassword('SecureE2EPass');
    await signupPage.enterConfirmPassword('SecureE2EPass');
    
    global.logStep(this.test.title, 'Step 3', 'Info', 'Submitting registration details');
    await signupPage.clickCreateAccount();

    global.logStep(this.test.title, 'Step 4', 'Info', 'Verifying redirect to Login portal with success notification');
    const snackbar = signupPage.locator('xpath', '//*[contains(@text, "successful") or contains(@text, "log in")]');
    expect(await signupPage.isDisplayed(snackbar)).to.be.true;

    global.logStep(this.test.title, 'Signup Submit', 'Pass', 'Registration process finished successfully');
  });

  it('Should validate required fields on Add Patrol Report form', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Logging into account');
    await loginPage.login('admin@college.edu', 'AdminSecurePass!');

    global.logStep(this.test.title, 'Step 2', 'Info', 'Opening Add Patrol Report page');
    await reportPage.navigateToAddReport();

    global.logStep(this.test.title, 'Step 3', 'Info', 'Clicking submit on empty report form');
    await reportPage.clickSubmit();

    global.logStep(this.test.title, 'Step 4', 'Info', 'Checking validation warnings across report form');
    // Expecting "Please fill all required fields" snackbar or field alerts
    const emptyWarning = reportPage.locator('xpath', '//*[contains(@text, "required") or contains(@text, "fill")]');
    expect(await reportPage.isDisplayed(emptyWarning)).to.be.true;

    global.logStep(this.test.title, 'Report Field Warnings', 'Pass', 'Report empty fields correctly caught by app');
  });

  it('Should successfully submit an Incident Patrol Report', async function() {
    global.logStep(this.test.title, 'Step 1', 'Info', 'Filling out patrol report details');
    await reportPage.selectIssueType('Late Coming');
    await reportPage.enterStudentName('Alex Mercer');
    await reportPage.enterRegisterNumber('22CS089');
    
    global.logStep(this.test.title, 'Step 2', 'Info', 'Selecting nested dropdown options');
    await reportPage.selectDepartment('CSE');
    await reportPage.selectYearSection('III - A');
    
    await reportPage.enterLocation('Block B - Seminar Hall');
    
    global.logStep(this.test.title, 'Step 3', 'Info', 'Selecting incident Date & Time using pickers');
    await reportPage.pickIncidentDateTime();
    
    await reportPage.enterRemarks('Student arrived 45 minutes late for internal laboratory assessment.');

    global.logStep(this.test.title, 'Step 4', 'Info', 'Submitting report form');
    await reportPage.clickSubmit();

    global.logStep(this.test.title, 'Step 5', 'Info', 'Confirming report submission alert dialog');
    expect(await reportPage.isDisplayed(signupPage.locator('text', 'Report Submitted!'))).to.be.true;
    await reportPage.clickDoneOnSuccess();
    
    global.logStep(this.test.title, 'Report Submission', 'Pass', 'Incident report registered and confirmed successfully');
    
    // Cleanup: logout session
    global.logStep(this.test.title, 'Step 6', 'Info', 'Logging out');
    await reportPage.logout();
  });

});
