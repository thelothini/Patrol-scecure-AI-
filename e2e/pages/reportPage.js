const BasePage = require('./basePage');

class ReportPage extends BasePage {
  constructor() {
    super();
    // HomeScreen quick navigation actions
    this.addReportShortcut = this.locator('text', 'Add Patrol\nReport');
    this.logoutShortcut = this.locator('text', 'Logout');
    
    // Add Patrol Report Fields
    this.studentNameField = this.locator('text', 'Student Name');
    this.registerNumberField = this.locator('text', 'Register Number');
    this.departmentDropdown = this.locator('text', 'Department');
    this.yearSectionDropdown = this.locator('text', 'Year / Section');
    this.locationField = this.locator('text', 'Location');
    
    // DateTime picker trigger
    this.datePickerContainer = this.locator('xpath', '//android.widget.ScrollView/android.view.View[5] | //*[contains(@text, "/")]');
    this.dialogOkButton = this.locator('text', 'OK');
    
    this.remarksField = this.locator('text', 'Remarks');
    this.submitButton = this.locator('text', 'SUBMIT REPORT');
    
    // Success Dialog
    this.successDialogDoneButton = this.locator('text', 'DONE');
    
    // Logout Dialog
    this.logoutConfirmButton = this.locator('text', 'Logout');
  }

  async navigateToAddReport() {
    await this.click(this.addReportShortcut);
  }

  async selectIssueType(issueType) {
    const issueElement = this.locator('text', issueType);
    await this.click(issueElement);
  }

  async enterStudentName(name) {
    await this.setValue(this.studentNameField, name);
  }

  async enterRegisterNumber(regNo) {
    await this.setValue(this.registerNumberField, regNo);
  }

  async selectDepartment(dept) {
    await this.click(this.departmentDropdown);
    const option = this.locator('text', dept);
    await this.click(option);
  }

  async selectYearSection(yearSec) {
    await this.click(this.yearSectionDropdown);
    const option = this.locator('text', yearSec);
    await this.click(option);
  }

  async enterLocation(loc) {
    await this.setValue(this.locationField, loc);
  }

  async pickIncidentDateTime() {
    // Click date picker container
    await this.click(this.datePickerContainer);
    // Click OK on date picker dialog
    await this.click(this.dialogOkButton);
    // Click OK on time picker dialog
    await this.click(this.dialogOkButton);
  }

  async enterRemarks(remarks) {
    await this.setValue(this.remarksField, remarks);
  }

  async clickSubmit() {
    await this.click(this.submitButton);
  }

  async clickDoneOnSuccess() {
    await this.click(this.successDialogDoneButton);
  }

  async logout() {
    await this.click(this.logoutShortcut);
    await this.click(this.logoutConfirmButton);
  }

  /**
   * Complete patrol report submission workflow
   */
  async submitReport(data) {
    if (data.issueType) await this.selectIssueType(data.issueType);
    if (data.studentName) await this.enterStudentName(data.studentName);
    if (data.registerNumber) await this.enterRegisterNumber(data.registerNumber);
    if (data.department) await this.selectDepartment(data.department);
    if (data.yearSection) await this.selectYearSection(data.yearSection);
    if (data.location) await this.enterLocation(data.location);
    if (data.pickDate) await this.pickIncidentDateTime();
    if (data.remarks) await this.enterRemarks(data.remarks);
    await this.clickSubmit();
  }
}

module.exports = new ReportPage();
