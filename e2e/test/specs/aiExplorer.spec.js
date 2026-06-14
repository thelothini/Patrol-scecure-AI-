const { expect } = require('chai');
const smartExplorer = require('../../ai/smartExplorer');
const driverFactory = require('../../drivers/driverFactory');

describe('Smart AI-Assisted Testing Suite', function() {
  
  it('Should dynamically scan layout, detect form inputs, buttons and explore coverage', async function() {
    this.timeout(300000);
    global.logStep(this.test.title, 'Step 1', 'Info', 'Initializing Smart AI-Assisted Testing engine...');
    
    const driver = driverFactory.getDriver();
    smartExplorer.setDriver(driver);

    global.logStep(this.test.title, 'Step 2', 'Info', 'Starting screen crawling, field detection, and path validation...');
    const metrics = await smartExplorer.runDiscovery();

    global.logStep(this.test.title, 'Step 3', 'Info', 'Evaluating discovery coverage metrics...');
    expect(metrics.screensVisited).to.be.greaterThan(0);
    expect(metrics.widgetsValidated).to.be.greaterThan(0);
    expect(metrics.scenariosExecuted).to.be.greaterThan(0);

    global.logStep(this.test.title, 'AI Discovery Summary', 'Pass', 
      `Total Screens Visited: ${metrics.screensVisited}, Interactive Widgets Scanned: ${metrics.widgetsValidated}, Scenarios Executed: ${metrics.scenariosExecuted}`
    );
  });

});
