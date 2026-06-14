const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');
const logger = require('./logger');

class ReportGenerator {
  /**
   * Generates the styled Excel report from accumulated test metrics.
   * @param {Object} data The E2E run data containing summary, testCases, failedTests, and logs.
   * @param {string} outputPath Optional output path.
   */
  async generateReport(data, outputPath = null) {
    logger.info('Generating Excel report...');
    const workbook = new ExcelJS.Workbook();
    
    // Setup metadata
    workbook.creator = 'Appium Flutter E2E Framework';
    workbook.created = new Date();

    const reportsDir = path.resolve(__dirname, '../reports');
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }
    const finalPath = outputPath || path.join(reportsDir, 'Flutter_E2E_Report.xlsx');

    // Style Helpers
    const headerStyle = {
      font: { name: 'Arial', bold: true, color: { argb: 'FFFFFF' }, size: 11 },
      fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '0A1628' } },
      alignment: { vertical: 'middle', horizontal: 'center' }
    };

    const borderStyle = {
      top: { style: 'thin', color: { argb: 'CCCCCC' } },
      left: { style: 'thin', color: { argb: 'CCCCCC' } },
      bottom: { style: 'thin', color: { argb: 'CCCCCC' } },
      right: { style: 'thin', color: { argb: 'CCCCCC' } }
    };

    // ────────────────────────────────────────────────────────
    // SHEET 1: Summary
    // ────────────────────────────────────────────────────────
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.views = [{ showGridLines: true }];
    summarySheet.columns = [
      { header: 'Metric', key: 'metric', width: 25 },
      { header: 'Value', key: 'value', width: 35 }
    ];

    const passPercentage = data.summary.totalTests > 0 
      ? Math.round((data.summary.passed / data.summary.totalTests) * 100)
      : 0;

    const summaryData = [
      { metric: 'Execution Date', value: data.summary.executionDate },
      { metric: 'Device Name', value: data.summary.deviceName },
      { metric: 'Android Version', value: data.summary.androidVersion },
      { metric: 'Total Tests', value: data.summary.totalTests },
      { metric: 'Passed', value: data.summary.passed },
      { metric: 'Failed', value: data.summary.failed },
      { metric: 'Skipped', value: data.summary.skipped },
      { metric: 'Pass Percentage', value: `${passPercentage}%` },
      { metric: 'Duration (sec)', value: Math.round(data.summary.duration / 1000) }
    ];

    summarySheet.getRow(1).eachCell((cell) => {
      cell.font = headerStyle.font;
      cell.fill = headerStyle.fill;
      cell.alignment = headerStyle.alignment;
      cell.border = borderStyle;
    });

    summaryData.forEach((rowVal, index) => {
      const row = summarySheet.addRow(rowVal);
      row.getCell(1).font = { name: 'Arial', bold: true };
      row.getCell(1).border = borderStyle;
      
      const valCell = row.getCell(2);
      valCell.border = borderStyle;

      // Color coding metrics
      if (rowVal.metric === 'Passed') {
        valCell.font = { name: 'Arial', bold: true, color: { argb: '008000' } };
      } else if (rowVal.metric === 'Failed') {
        valCell.font = { name: 'Arial', bold: true, color: { argb: 'FF0000' } };
      } else if (rowVal.metric === 'Pass Percentage') {
        valCell.font = { name: 'Arial', bold: true };
        valCell.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: passPercentage >= 80 ? 'E6F4EA' : 'FCE8E6' }
        };
      }
    });

    // ────────────────────────────────────────────────────────
    // SHEET 2: Test Cases
    // ────────────────────────────────────────────────────────
    const casesSheet = workbook.addWorksheet('Test Cases');
    casesSheet.views = [{ showGridLines: true }];
    casesSheet.columns = [
      { header: 'Test ID', key: 'id', width: 12 },
      { header: 'Module', key: 'module', width: 15 },
      { header: 'Scenario', key: 'scenario', width: 45 },
      { header: 'Status', key: 'status', width: 15 },
      { header: 'Device', key: 'device', width: 25 },
      { header: 'Duration (ms)', key: 'duration', width: 15 }
    ];

    casesSheet.getRow(1).eachCell((cell) => {
      cell.font = headerStyle.font;
      cell.fill = headerStyle.fill;
      cell.alignment = headerStyle.alignment;
      cell.border = borderStyle;
    });

    data.testCases.forEach((tc) => {
      const row = casesSheet.addRow(tc);
      row.eachCell((cell) => { cell.border = borderStyle; });
      
      const statusCell = row.getCell(4);
      statusCell.alignment = { horizontal: 'center' };
      if (tc.status === 'Passed') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'E2F0D9' } };
        statusCell.font = { name: 'Arial', color: { argb: '385723' }, bold: true };
      } else if (tc.status === 'Failed') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F8CBAD' } };
        statusCell.font = { name: 'Arial', color: { argb: 'C00000' }, bold: true };
      } else {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2CC' } };
        statusCell.font = { name: 'Arial', color: { argb: '7F6000' }, bold: true };
      }
    });

    // ────────────────────────────────────────────────────────
    // SHEET 3: Failed Tests
    // ────────────────────────────────────────────────────────
    const failedSheet = workbook.addWorksheet('Failed Tests');
    failedSheet.views = [{ showGridLines: true }];
    failedSheet.columns = [
      { header: 'Test Name', key: 'name', width: 35 },
      { header: 'Failure Reason', key: 'reason', width: 45 },
      { header: 'Screenshot Path', key: 'screenshotPath', width: 40 },
      { header: 'Device', key: 'device', width: 20 },
      { header: 'Android Version', key: 'androidVersion', width: 15 }
    ];

    failedSheet.getRow(1).eachCell((cell) => {
      cell.font = headerStyle.font;
      cell.fill = headerStyle.fill;
      cell.alignment = headerStyle.alignment;
      cell.border = borderStyle;
    });

    data.failedTests.forEach((ft) => {
      const row = failedSheet.addRow(ft);
      row.eachCell((cell) => {
        cell.border = borderStyle;
        cell.alignment = { wrapText: true, vertical: 'top' };
      });
      row.getCell(2).font = { name: 'Courier New', color: { argb: 'C00000' }, size: 9 };
      row.getCell(3).font = { name: 'Arial', color: { argb: '0070FF' }, underline: true };
    });

    // ────────────────────────────────────────────────────────
    // SHEET 4: Execution Logs
    // ────────────────────────────────────────────────────────
    const logsSheet = workbook.addWorksheet('Execution Logs');
    logsSheet.views = [{ showGridLines: true }];
    logsSheet.columns = [
      { header: 'Timestamp', key: 'timestamp', width: 25 },
      { header: 'Test Name', key: 'testName', width: 30 },
      { header: 'Step', key: 'step', width: 40 },
      { header: 'Result', key: 'result', width: 12 },
      { header: 'Remarks', key: 'remarks', width: 30 }
    ];

    logsSheet.getRow(1).eachCell((cell) => {
      cell.font = headerStyle.font;
      cell.fill = headerStyle.fill;
      cell.alignment = headerStyle.alignment;
      cell.border = borderStyle;
    });

    data.logs.forEach((log) => {
      const row = logsSheet.addRow(log);
      row.eachCell((cell) => { cell.border = borderStyle; });
      
      const resCell = row.getCell(4);
      resCell.alignment = { horizontal: 'center' };
      if (log.result === 'Pass' || log.result === 'Done') {
        resCell.font = { name: 'Arial', color: { argb: '2E7D32' }, bold: true };
      } else if (log.result === 'Fail' || log.result === 'Error') {
        resCell.font = { name: 'Arial', color: { argb: 'C62828' }, bold: true };
      }
    });

    await workbook.xlsx.writeFile(finalPath);
    logger.info(`Excel Report saved successfully to: ${finalPath}`);
  }
}

module.exports = new ReportGenerator();
