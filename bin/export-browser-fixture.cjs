#!/usr/bin/env node
'use strict';

// Presses the complete-export control in the same browser surface an owner uses.

const fs = require('node:fs');
const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`export-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
  await page.locator('[data-open-screen="settings-screen"]').first().click();
  await page.locator('#settings-screen').waitFor({state: 'visible'});
  const control = page.locator('[data-rover-export-download]');
  if ((await control.count()) !== 1) {
    fail('the Settings screen does not have exactly one complete-export control');
    await browser.close();
    return;
  }

  const downloadPromise = page.waitForEvent('download');
  await control.click();
  const download = await downloadPromise;
  const downloadPath = await download.path();
  if (downloadPath === null) {
    fail('the browser did not retain the downloaded file');
    await browser.close();
    return;
  }
  const document = JSON.parse(fs.readFileSync(downloadPath, 'utf8'));
  console.log(`EXPORT_FILENAME=${download.suggestedFilename()}`);
  console.log(`EXPORT_FORMAT=${document['rover-import']}`);
  console.log(`EXPORT_SOURCE=${document.source?.app || ''}`);
  console.log(`EXPORT_VEHICLES=${document.vehicles?.length ?? -1}`);
  console.log(`EXPORT_ATTACHMENTS_INCLUDED=${document.source?.attachments?.included}`);

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
