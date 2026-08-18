#!/usr/bin/env node
'use strict';

// Drives the M7 T6 reminder form in a real browser. Endpoint fixtures prove
// the storage and derivation; this proves a person can reach the same path.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, vehicle, subtype] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`reminder-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="add-reminder"]').click();
    const form = page.locator('#reminder-form');
    await form.waitFor({state: 'visible'});
    await form.locator('[name="vehicle"]').selectOption(vehicle);
    await form.locator('[name="subtype"]').selectOption(subtype);
    await form.locator('[name="timeInterval"]').fill('6');
    await form.locator('[name="timeUnit"]').selectOption('months');
    await form.locator('[name="timeDue"]').fill('2098-01-01');
    await form.locator('button[type="submit"]').click();
    await page.waitForFunction(
      () => {
        const value = document.querySelector('#reminder-verdict')?.value || '';
        return value.length > 0 && value !== 'Saving…';
      },
      null,
      {timeout: 30000}
    );
    const verdict = await form.locator('#reminder-verdict').evaluate((node) => node.value);
    console.log(`REMINDER_VERDICT=${verdict}`);
    await page.waitForFunction(
      ([vehicleName, subtypeName]) => {
        const selected = document.querySelector('#app-default-data')?.dataset.vehicle;
        if (selected !== vehicleName) return false;
        return Array.from(document.querySelectorAll('[data-reminder]'))
          .some((card) => card.dataset.reminder === subtypeName);
      },
      [vehicle, subtype],
      {timeout: 30000}
    );
    const state = await page.locator(`[data-reminder="${subtype}"]`).getAttribute('data-reminder-state');
    console.log(`REMINDER_STATE=${state}`);
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
