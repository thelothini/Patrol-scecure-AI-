const fs = require('fs');
const path = require('path');
const logger = require('./logger');

class HtmlReporter {
  /**
   * Generates a premium HTML report.
   * @param {Object} data The accumulated test data.
   * @param {string} outputPath Optional output path.
   */
  async generateHtml(data, outputPath = null) {
    logger.info('Generating HTML dashboard report...');
    
    const reportsDir = path.resolve(__dirname, '../reports');
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }
    const finalPath = outputPath || path.join(reportsDir, 'index.html');

    const passPercentage = data.summary.totalTests > 0 
      ? Math.round((data.summary.passed / data.summary.totalTests) * 100)
      : 0;

    const testRowsHtml = data.testCases.map((tc) => {
      const statusClass = tc.status.toLowerCase();
      return `
        <tr class="test-row border-b border-gray-800 hover:bg-gray-900 transition">
          <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-400">${tc.id}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-blue-400">${tc.module}</td>
          <td class="px-6 py-4 text-sm text-gray-200">${tc.scenario}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm">
            <span class="status-badge status-${statusClass} px-3 py-1 rounded-full text-xs font-bold uppercase">
              ${tc.status}
            </span>
          </td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-400">${tc.device}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-400 font-mono">${tc.duration}ms</td>
        </tr>
      `;
    }).join('');

    const failureCardsHtml = data.failedTests.map((ft) => {
      // Relative path from reports/index.html to screenshot
      // E.g., if screenshot path is absolute like C:\...\reports\failures\xxx.png
      // we can map it to relative 'failures/xxx.png' for the HTML report.
      const screenshotFilename = path.basename(ft.screenshotPath);
      const relativeScreenshotPath = `failures/${screenshotFilename}`;
      
      return `
        <div class="failure-card bg-cardGrad border border-red-500/30 rounded-xl p-6 mb-6 shadow-xl">
          <div class="flex flex-col md:flex-row gap-6">
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-3">
                <span class="bg-red-500/20 text-red-400 px-3 py-1 rounded-md text-xs font-bold font-mono">FAIL</span>
                <h3 class="text-lg font-bold text-white">${ft.name}</h3>
              </div>
              <div class="mb-4">
                <span class="text-xs text-gray-400 font-semibold uppercase block mb-1">Failure Reason:</span>
                <pre class="bg-black/40 text-red-300 font-mono text-sm p-4 rounded-lg overflow-x-auto whitespace-pre-wrap max-h-48 border border-red-900/20">${ft.reason}</pre>
              </div>
              <div class="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span class="text-gray-500 block">Device</span>
                  <span class="text-gray-300 font-medium">${ft.device}</span>
                </div>
                <div>
                  <span class="text-gray-500 block">Android Version</span>
                  <span class="text-gray-300 font-medium">Android ${ft.androidVersion}</span>
                </div>
              </div>
            </div>
            <div class="w-full md:w-64 flex flex-col justify-center items-center">
              <span class="text-xs text-gray-400 font-semibold uppercase block mb-2">Failure Screenshot:</span>
              <a href="${relativeScreenshotPath}" target="_blank" class="block border border-gray-700 rounded-lg overflow-hidden hover:border-red-500 transition duration-300">
                <img src="${relativeScreenshotPath}" alt="Failure Screenshot" class="w-full h-auto object-cover max-h-48" onerror="this.src='https://placehold.co/400x600/182235/FFF?text=No+Screenshot'"/>
              </a>
            </div>
          </div>
        </div>
      `;
    }).join('') || '<div class="text-center py-8 text-gray-500 bg-gray-900/30 rounded-xl border border-gray-800">No test failures in this execution.</div>';

    const logsHtml = data.logs.map((log) => {
      const resClass = log.result.toLowerCase() === 'fail' || log.result.toLowerCase() === 'error' ? 'text-red-400 font-bold' : 'text-green-400';
      return `
        <div class="log-item py-2 border-b border-gray-900 text-xs font-mono text-gray-300 flex items-start gap-4">
          <span class="text-gray-500 min-w-[150px]">${log.timestamp}</span>
          <span class="text-blue-400 min-w-[180px] truncate">[${log.testName}]</span>
          <span class="flex-1">${log.step}</span>
          <span class="min-w-[60px] ${resClass} text-center">${log.result}</span>
          <span class="text-gray-500 min-w-[200px] truncate">${log.remarks || ''}</span>
        </div>
      `;
    }).join('');

    const htmlContent = `
<!DOCTYPE html>
<html lang="en" class="h-full bg-gray-950">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PatrolSecure E2E Test Execution Dashboard</title>
  <!-- Google Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&family=Rajdhani:wght@500;700&display=swap" rel="stylesheet">
  <!-- Tailwind CSS via CDN -->
  <script src="https://cdn.tailwindcss.com"></script>
  <!-- Chart.js via CDN -->
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: {
            sans: ['Outfit', 'sans-serif'],
            title: ['Rajdhani', 'sans-serif'],
          },
          colors: {
            primary: '#0A1628',
            cardBg: '#142035',
            accent: '#00C2FF',
            gold: '#FFFFB800',
            success: '#00E096',
            error: '#FF4D6A',
          },
          backgroundImage: {
            'cardGrad': 'linear-gradient(135deg, #142035 0%, #0F2040 100%)',
          }
        }
      }
    }
  </script>
  <style>
    .status-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }
    .status-passed {
      background-color: rgba(0, 224, 150, 0.15);
      color: #00E096;
      border: 1px solid rgba(0, 224, 150, 0.3);
    }
    .status-failed {
      background-color: rgba(255, 77, 106, 0.15);
      color: #FF4D6A;
      border: 1px solid rgba(255, 77, 106, 0.3);
    }
    .status-skipped {
      background-color: rgba(255, 184, 0, 0.15);
      color: #FFB800;
      border: 1px solid rgba(255, 184, 0, 0.3);
    }
    ::-webkit-scrollbar {
      width: 8px;
      height: 8px;
    }
    ::-webkit-scrollbar-track {
      background: #0A1628;
    }
    ::-webkit-scrollbar-thumb {
      background: #1E3555;
      border-radius: 4px;
    }
    ::-webkit-scrollbar-thumb:hover {
      background: #00C2FF;
    }
  </style>
</head>
<body class="text-gray-100 bg-gray-950 font-sans min-h-screen flex flex-col">

  <!-- Header -->
  <header class="border-b border-gray-900 bg-primary/80 backdrop-blur-md sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex flex-col md:flex-row justify-between items-center gap-4">
      <div class="flex items-center gap-3">
        <div class="h-10 w-10 rounded-lg bg-gradient-to-br from-accent to-blue-700 flex items-center justify-center shadow-lg shadow-accent/20">
          <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
          </svg>
        </div>
        <div>
          <h1 class="text-xl font-extrabold tracking-wider text-white font-title">PatrolSecure E2E Report</h1>
          <p class="text-xs text-accent font-semibold tracking-widest font-title uppercase">Mobile Test Automation Dashboard</p>
        </div>
      </div>
      <div class="flex items-center gap-4 text-xs font-mono bg-gray-900/50 px-4 py-2 rounded-lg border border-gray-800">
        <div>
          <span class="text-gray-500">RUN DATE:</span>
          <span class="text-gray-200 font-bold">${data.summary.executionDate}</span>
        </div>
        <div class="h-4 w-[1px] bg-gray-800"></div>
        <div>
          <span class="text-gray-500">EXCEL REPORT:</span>
          <span class="text-green-400 font-bold">Generated</span>
        </div>
      </div>
    </div>
  </header>

  <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
    
    <!-- Row 1: Metrics Cards & Chart -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
      
      <!-- Statistics Cards -->
      <div class="grid grid-cols-2 gap-4 lg:col-span-2">
        <div class="bg-cardGrad p-6 rounded-2xl border border-gray-800/80 shadow-lg flex flex-col justify-between">
          <span class="text-gray-400 text-sm font-semibold tracking-wider uppercase">Device Info</span>
          <div class="mt-4">
            <span class="text-white text-lg font-bold block truncate">${data.summary.deviceName}</span>
            <span class="text-xs text-gray-500 font-mono">Android Version: ${data.summary.androidVersion}</span>
          </div>
        </div>

        <div class="bg-cardGrad p-6 rounded-2xl border border-gray-800/80 shadow-lg flex flex-col justify-between">
          <span class="text-gray-400 text-sm font-semibold tracking-wider uppercase">Execution Duration</span>
          <div class="mt-4">
            <span class="text-accent text-3xl font-extrabold font-title">${Math.round(data.summary.duration / 1000)}s</span>
            <span class="text-xs text-gray-500 font-mono block">Total milliseconds: ${data.summary.duration}ms</span>
          </div>
        </div>

        <div class="bg-cardGrad p-6 rounded-2xl border border-gray-800/80 shadow-lg flex flex-col justify-between">
          <span class="text-gray-400 text-sm font-semibold tracking-wider uppercase">Test Results</span>
          <div class="grid grid-cols-3 gap-2 mt-4 text-center">
            <div class="bg-green-500/10 p-2 rounded-lg border border-green-500/20">
              <span class="text-xs text-green-400 block font-semibold">PASS</span>
              <span class="text-xl font-extrabold text-green-400 font-title">${data.summary.passed}</span>
            </div>
            <div class="bg-red-500/10 p-2 rounded-lg border border-red-500/20">
              <span class="text-xs text-red-400 block font-semibold">FAIL</span>
              <span class="text-xl font-extrabold text-red-400 font-title">${data.summary.failed}</span>
            </div>
            <div class="bg-yellow-500/10 p-2 rounded-lg border border-yellow-500/20">
              <span class="text-xs text-yellow-400 block font-semibold">SKIP</span>
              <span class="text-xl font-extrabold text-yellow-400 font-title">${data.summary.skipped}</span>
            </div>
          </div>
        </div>

        <div class="bg-cardGrad p-6 rounded-2xl border border-gray-800/80 shadow-lg flex flex-col justify-between">
          <span class="text-gray-400 text-sm font-semibold tracking-wider uppercase">Success Rate</span>
          <div class="mt-4 flex items-end justify-between">
            <span class="text-5xl font-black font-title tracking-tight ${passPercentage >= 80 ? 'text-success' : 'text-error'}">${passPercentage}%</span>
            <span class="text-xs text-gray-500 font-mono pb-1">${data.summary.passed}/${data.summary.totalTests} Passed</span>
          </div>
        </div>
      </div>

      <!-- Pie Chart Card -->
      <div class="bg-cardGrad p-6 rounded-2xl border border-gray-800/80 shadow-lg flex flex-col items-center justify-center">
        <h3 class="text-gray-400 text-sm font-semibold tracking-wider uppercase mb-4 self-start">Visual Metrics</h3>
        <div class="w-full max-w-[200px] aspect-square">
          <canvas id="resultChart"></canvas>
        </div>
      </div>

    </div>

    <!-- Row 2: Test Cases List -->
    <div class="bg-cardGrad rounded-2xl border border-gray-800/80 shadow-lg overflow-hidden mb-8">
      <div class="px-6 py-5 border-b border-gray-800 flex justify-between items-center">
        <h2 class="text-lg font-bold text-white font-title tracking-wider uppercase">Executed Test Scenarios</h2>
        <span class="text-xs font-mono text-gray-400">Total Scenarios: ${data.testCases.length}</span>
      </div>
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-800">
          <thead class="bg-black/20">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Test ID</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Module</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Scenario</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Device</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Duration</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-800 bg-transparent">
            ${testRowsHtml}
          </tbody>
        </table>
      </div>
    </div>

    <!-- Row 3: Failure Analysis -->
    <div class="mb-8">
      <h2 class="text-xl font-bold text-white font-title tracking-wider uppercase mb-4 flex items-center gap-2">
        <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
        </svg>
        Failure Diagnostics & Analysis
      </h2>
      ${failureCardsHtml}
    </div>

    <!-- Row 4: Detailed Step Logs -->
    <div class="bg-cardGrad rounded-2xl border border-gray-800/80 shadow-lg overflow-hidden">
      <div class="px-6 py-5 border-b border-gray-800">
        <h2 class="text-lg font-bold text-white font-title tracking-wider uppercase">E2E Execution Stream Logs</h2>
      </div>
      <div class="p-6 bg-black/30 max-h-96 overflow-y-auto flex flex-col">
        ${logsHtml || '<div class="text-center py-4 text-gray-600 text-sm">No action logs found.</div>'}
      </div>
    </div>

  </main>

  <footer class="border-t border-gray-900 py-6 bg-black/20 text-center text-xs text-gray-500">
    <p>© 2026 PatrolSecure Campus Discipline Management App - Enterprise E2E QA Automation Framework</p>
  </footer>

  <!-- Chart rendering script -->
  <script>
    const ctx = document.getElementById('resultChart').getContext('2d');
    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Passed', 'Failed', 'Skipped'],
        datasets: [{
          data: [${data.summary.passed}, ${data.summary.failed}, ${data.summary.skipped}],
          backgroundColor: ['#00E096', '#FF4D6A', '#FFB800'],
          borderColor: '#142035',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            display: false
          }
        },
        cutout: '75%'
      }
    });
  </script>
</body>
</html>
    `;

    fs.writeFileSync(finalPath, htmlContent);
    logger.info(`HTML Report successfully created at: ${finalPath}`);
  }
}

module.exports = new HtmlReporter();
