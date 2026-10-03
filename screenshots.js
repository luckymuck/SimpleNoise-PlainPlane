const puppeteer = require('puppeteer');
const path = require('path');

const htmlPath = path.join(__dirname, 'www', 'index.html');

async function takeScreenshot(width, height, label) {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewport({ width, height });
  await page.goto('file://' + htmlPath, { waitUntil: 'networkidle0' });
  await page.waitForSelector('#pad-wrap');
  const box = await page.$eval('#pad-wrap', el => {
    const r = el.getBoundingClientRect();
    return { x: r.x, y: r.y, w: r.width, h: r.height };
  });
  const cx = box.x + box.w * 0.7;
  const cy = box.y + box.h * 0.4;
  await page.mouse.click(cx, cy);
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(__dirname, label + '.png'), fullPage: false });
  await browser.close();
  console.log('Created ' + label + '.png (' + width + 'x' + height + ')');
}

(async () => {
  await takeScreenshot(720, 1280, 'screenshot-7inch');
  await takeScreenshot(1080, 1920, 'screenshot-10inch');
})();
