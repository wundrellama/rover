#!/usr/bin/env node
'use strict';

// Drives one M7 T6 reminder through the "Add reminder" form in a real browser.
// The endpoint battery proves the write; this proves a person can reach it,
// and that what is due comes back on the hub without a further step.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle, subtype,
  distanceInterval, distanceDue
] = process.argv.slice(2);
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

  await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
  await page.locator('[data-open-screen="add-reminder"]').first().click();
  const form = page.locator('#reminder-form');
  await form.waitFor({state: 'visible'});
  await form.locator('[name="vehicle"]').selectOption(vehicle);
  await form.locator('[name="subtype"]').selectOption(subtype);
  await form.locator('[name="distanceInterval"]').fill(distanceInterval);
  await form.locator('[name="distanceDue"]').fill(distanceDue);
  await form.locator('button[type="submit"]').click();
  await page.waitForFunction(
    () => {
      const value = document.querySelector('#reminder-verdict')?.value || '';
      return value.length > 0 && value !== 'Saving…';
    },
    null,
    {timeout: 30000}
  );
  const verdict = await form
    .locator('#reminder-verdict')
    .evaluate((node) => node.value);
  console.log(`REMINDER_VERDICT=${verdict}`);

  // The verdict lands before the view reload finishes, so wait for the card
  // rather than reading the document the instant the text changes.
  await page.waitForFunction(
    (wanted) =>
      document.querySelector(`[data-reminder="${wanted}"]`) !== null,
    subtype,
    {timeout: 30000}
  );
  const card = await page.evaluate((wanted) => {
    const found = document.querySelector(`[data-reminder="${wanted}"]`);
    return found
      ? {
          state: found.getAttribute('data-reminder-state'),
          due: found.getAttribute('data-reminder-due'),
          text: found.textContent
        }
      : null;
  }, subtype);
  if (!card) {
    fail('the saved reminder is not on the reloaded hub');
  } else {
    console.log(`REMINDER_STATE=${card.state}`);
    console.log(`REMINDER_DUE=${card.due}`);
    console.log(`REMINDER_TEXT=${card.text}`);
  }

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
