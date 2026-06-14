const logger = require('../utils/logger');
const driverFactory = require('../drivers/driverFactory');

class SmartExplorer {
  constructor() {
    this.driver = null;
    this.discoveredWidgets = [];
    this.navigationPaths = [];
    this.coverageMetrics = {
      screensVisited: 0,
      widgetsValidated: 0,
      scenariosExecuted: 0
    };
  }

  setDriver(driver) {
    this.driver = driver;
  }

  /**
   * Captures and parses the active Android layout.
   */
  async analyzeScreen() {
    logger.info('[AI-Explorer] Analyzing current screen...');
    const sourceXml = await this.driver.getPageSource();
    this.detectWidgets(sourceXml);
    return this.discoveredWidgets;
  }

  /**
   * Widget Classifier using layout XML parsing.
   * Extracts fields, buttons, dropdowns, switches.
   */
  detectWidgets(xml) {
    this.discoveredWidgets = [];
    
    // Regex matches for common Android UI components
    const nodeRegex = /<node[^>]*class="([^"]+)"[^>]*text="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*resource-id="([^"]*)"[^>]*clickable="([^"]*)"/g;
    
    let match;
    while ((match = nodeRegex.exec(xml)) !== null) {
      const [_, className, text, contentDesc, resourceId, clickable] = match;
      
      const widget = {
        className,
        text,
        contentDesc,
        resourceId,
        clickable: clickable === 'true',
        type: 'unknown'
      };

      // Classify widget types
      if (className.includes('EditText')) {
        widget.type = 'input';
      } else if (className.includes('Button') || clickable === 'true') {
        widget.type = 'button';
      } else if (className.includes('Spinner') || className.includes('Dropdown')) {
        widget.type = 'dropdown';
      } else if (className.includes('CheckBox')) {
        widget.type = 'checkbox';
      } else if (className.includes('Switch')) {
        widget.type = 'switch';
      } else if (text || contentDesc) {
        widget.type = 'text_label';
      }

      this.discoveredWidgets.push(widget);
    }

    logger.info(`[AI-Explorer] Discovered ${this.discoveredWidgets.length} elements on current viewport.`);
    
    // Log details of interactive components found
    const interactive = this.discoveredWidgets.filter(w => w.type === 'input' || w.type === 'button');
    logger.info(`[AI-Explorer] Interactive widgets detected: ${interactive.length}`);
    interactive.forEach(w => logger.info(`  - [${w.type.toUpperCase()}] Text: "${w.text}", Desc: "${w.contentDesc}", ResourceId: "${w.resourceId}"`));
  }

  /**
   * Dynamically constructs scenarios based on screen analysis
   */
  generateTestScenarios() {
    logger.info('[AI-Explorer] Generating smart test scenarios...');
    const scenarios = [];

    const inputs = this.discoveredWidgets.filter(w => w.type === 'input');
    const buttons = this.discoveredWidgets.filter(w => w.type === 'button');

    if (inputs.length > 0) {
      // 1. Scenario: Empty Fields Validation
      scenarios.push({
        name: 'Empty Fields Check',
        action: async (driver) => {
          logger.info('[AI-Explorer] Running Empty Fields Validation...');
          const submitBtn = buttons.find(b => b.text.toUpperCase().includes('SIGN') || b.text.toUpperCase().includes('CREATE') || b.text.toUpperCase().includes('SUBMIT'));
          if (submitBtn) {
            const selector = submitBtn.text ? `//*[@text="${submitBtn.text}"]` : `~${submitBtn.contentDesc}`;
            const el = await driver.$(selector);
            await el.click();
            logger.info('[AI-Explorer] Form submitted empty. Capturing validation responses...');
          }
        }
      });

      // 2. Scenario: Invalid Value Validation
      scenarios.push({
        name: 'Invalid Data Check',
        action: async (driver) => {
          logger.info('[AI-Explorer] Running Invalid Data Validations...');
          for (const input of inputs) {
            const locatorVal = input.text ? `//*[@text="${input.text}"]` : `//*[@resource-id="${input.resourceId}"]`;
            const el = await driver.$(locatorVal);
            
            const label = (input.text || input.contentDesc || '').toLowerCase();
            if (label.includes('email')) {
              await el.setValue('invalid-email-format');
              logger.info('[AI-Explorer] Typed invalid email format into field.');
            } else if (label.includes('phone')) {
              await el.setValue('123'); // too short phone
              logger.info('[AI-Explorer] Typed short phone format into field.');
            } else if (label.includes('password')) {
              await el.setValue('12'); // too short password
              logger.info('[AI-Explorer] Typed short password format into field.');
            }
          }
        }
      });
    }

    // 3. Scenario: Navigation Explorer
    const navButtons = buttons.filter(b => b.text.toLowerCase().includes('register') || b.text.toLowerCase().includes('sign') || b.text.toLowerCase().includes('back'));
    navButtons.forEach(btn => {
      scenarios.push({
        name: `Navigate to [${btn.text}]`,
        action: async (driver) => {
          logger.info(`[AI-Explorer] Discovered navigation route to "${btn.text}". Navigating...`);
          const selector = `//*[@text="${btn.text}"]`;
          const el = await driver.$(selector);
          await el.click();
        }
      });
    });

    this.coverageMetrics.scenariosExecuted += scenarios.length;
    return scenarios;
  }

  /**
   * Executes AI-assisted test discovery
   */
  async runDiscovery() {
    logger.info('[AI-Explorer] Starting smart discovery suite...');
    this.coverageMetrics.screensVisited = 1;
    
    // Analyze current landing page
    await this.analyzeScreen();
    
    const scenarios = this.generateTestScenarios();
    logger.info(`[AI-Explorer] Generated ${scenarios.length} dynamic tests.`);
    
    for (const scenario of scenarios) {
      try {
        logger.info(`[AI-Explorer] Executing: ${scenario.name}`);
        await scenario.action(this.driver);
        this.coverageMetrics.widgetsValidated += 1;
        
        // Wait 1.5 seconds to settle screen state
        await this.driver.pause(1500);
      } catch (err) {
        logger.warn(`[AI-Explorer] Error running scenario [${scenario.name}]: ${err.message}`);
      }
    }

    logger.info('[AI-Explorer] Smart discovery cycle completed.');
    logger.info(`[AI-Explorer] Coverage metrics: ${JSON.stringify(this.coverageMetrics)}`);
    return this.coverageMetrics;
  }
}

module.exports = new SmartExplorer();
