'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);
const [url, jar, preferred, fresh] = process.argv.slice(2);

(async () => {
  const browser = await chromium.launch({headless: true, executablePath: process.env.ROVER_CHROMIUM});
  try {
    const context = await browser.newContext({viewport: {width: 390, height: 844}});
    const cookies = fs.readFileSync(jar, 'utf8').split('\n')
      .filter(line => line.includes('\turbauth-'))
      .map(line => { const parts = line.split('\t'); return {name: parts[5], value: parts[6], url}; });
    assert.ok(cookies.length);
    await context.addCookies(cookies);
    const page = await context.newPage();
    await page.goto(url + '/apps/rover', {waitUntil: 'networkidle'});
    for (const name of ['fill', 'event']) {
      const form = page.locator('#' + name + '-form');
      for (const [vehicle, backend] of [[preferred, 's3'], [fresh, 'clay'], [preferred, 's3']]) {
        await form.locator('[name="vehicle"]').selectOption({label: vehicle}, {force: true});
        assert.equal(await form.locator('[data-photo-backend]').inputValue(), backend, name + ' vehicle change');
      }
    }
    console.log('Fill and event forms follow the selected vehicle in the browser.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
