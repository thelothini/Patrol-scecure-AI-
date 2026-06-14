const logger = require('./logger');

class Gestures {
  constructor() {
    this.driver = null;
  }

  setDriver(driver) {
    this.driver = driver;
  }

  /**
   * Executes a tap on coordinates or on an element.
   * @param {number} x 
   * @param {number} y 
   */
  async tap(x, y) {
    logger.info(`Performing gesture: Tap at (${x}, ${y})`);
    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  /**
   * Performs a double-tap at the given coordinates.
   */
  async doubleTap(x, y) {
    logger.info(`Performing gesture: Double Tap at (${x}, ${y})`);
    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerUp', button: 0 },
          { type: 'pause', duration: 100 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  /**
   * Performs a long press on coordinates.
   */
  async longPress(x, y, durationMs = 1500) {
    logger.info(`Performing gesture: Long Press at (${x}, ${y}) for ${durationMs}ms`);
    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: durationMs },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  /**
   * Performs a swipe gesture.
   */
  async swipe(startX, startY, endX, endY, durationMs = 800) {
    logger.info(`Performing gesture: Swipe from (${startX}, ${startY}) to (${endX}, ${endY})`);
    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(startX), y: Math.round(startY) },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: durationMs, x: Math.round(endX), y: Math.round(endY) },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  /**
   * Performs a drag and drop from source to destination coordinates.
   */
  async dragAndDrop(startX, startY, endX, endY) {
    logger.info(`Performing gesture: Drag and Drop from (${startX}, ${startY}) to (${endX}, ${endY})`);
    await this.swipe(startX, startY, endX, endY, 1500);
  }

  /**
   * Performs a scroll down gesture based on device screen size.
   */
  async scrollDown() {
    logger.info('Performing gesture: Scroll Down');
    const size = await this.driver.getWindowSize();
    const startX = size.width / 2;
    const startY = size.height * 0.8;
    const endY = size.height * 0.2;
    await this.swipe(startX, startY, startX, endY, 1000);
  }

  /**
   * Performs a scroll up gesture.
   */
  async scrollUp() {
    logger.info('Performing gesture: Scroll Up');
    const size = await this.driver.getWindowSize();
    const startX = size.width / 2;
    const startY = size.height * 0.2;
    const endY = size.height * 0.8;
    await this.swipe(startX, startY, startX, endY, 1000);
  }

  /**
   * Performs a pinch gesture (zoom out).
   */
  async pinch() {
    logger.info('Performing gesture: Pinch (Zoom Out)');
    const size = await this.driver.getWindowSize();
    const centerX = size.width / 2;
    const centerY = size.height / 2;

    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - 100, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX - 10, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + 100, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX + 10, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  /**
   * Performs a zoom gesture (zoom in).
   */
  async zoom() {
    logger.info('Performing gesture: Zoom (Zoom In)');
    const size = await this.driver.getWindowSize();
    const centerX = size.width / 2;
    const centerY = size.height / 2;

    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - 10, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX - 200, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + 10, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX + 200, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }
}

module.exports = new Gestures();
