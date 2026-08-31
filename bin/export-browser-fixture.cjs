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
  // The complete export is an uncompressed tar. It is walked here the way a
  // tar reader walks one: forward, 512 bytes at a time, reading the name and
  // the ASCII-octal size out of each header. There is no index to seek to.
  const archive = fs.readFileSync(downloadPath);
  const members = [];
  for (let at = 0; at + 512 <= archive.length; ) {
    const name = archive.subarray(at, at + 100).toString('ascii').replace(/\0.*$/, '');
    if (name === '') break;
    const size = parseInt(archive.subarray(at + 124, at + 135).toString('ascii').replace(/\0.*$/, '').trim(), 8);
    members.push({name, at: at + 512, size});
    at += 512 + Math.ceil(size / 512) * 512;
  }
  const first = members[0];
  if (!first || first.name !== 'rover-import.json') {
    fail(`the first member of the archive is ${first ? first.name : 'absent'}`);
    await browser.close();
    return;
  }
  const document = JSON.parse(archive.subarray(first.at, first.at + first.size).toString('utf8'));
  console.log(`EXPORT_FILENAME=${download.suggestedFilename()}`);
  console.log(`EXPORT_FIRST_MEMBER=${first.name}`);
  console.log(`EXPORT_MEMBERS=${members.length}`);
  console.log(`EXPORT_PHOTO_MEMBERS=${members.filter((m) => m.name.startsWith('attachments/')).length}`);
  console.log(`EXPORT_FORMAT=${document['rover-import']}`);
  console.log(`EXPORT_SOURCE=${document.source?.app || ''}`);
  console.log(`EXPORT_VEHICLES=${document.vehicles?.length ?? -1}`);
  console.log(`EXPORT_ATTACHMENTS_INCLUDED=${document.source?.attachments?.included}`);
  console.log(`EXPORT_PHOTO_COUNT=${document.source?.attachments?.photoCount}`);

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
