#!/usr/bin/env node
'use strict';

// Drives the M7 T1 "Add event" form in a real browser. The endpoint battery
// proves the write; this proves a person can reach it.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, vehicle, station, tag, payment, total, mileage, notes] =
  process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`event-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="add-event"]').first().click();
    const form = page.locator('#event-form');
    await form.waitFor({state: 'visible'});
    await form.locator('[name="vehicle"]').selectOption(vehicle);
    await form.locator('[name="kind"]').selectOption('service');
    await form.locator('[name="total"]').fill(total);
    await form.locator('[name="mileage"]').fill(mileage);
    await form.locator('[name="station"]').selectOption(station);
    for (const subtype of ['Engine Oil', 'Brake Fluid', 'Tire Rotation']) {
      await form
        .locator(`#event-service-subtypes input[value="${subtype}"]`)
        .check();
    }
    await form.locator(`#event-tags input[value="${tag}"]`).check();
    await form.locator('[name="paymentMethod"]').selectOption(payment);
    await form.locator('[name="notes"]').fill(notes);

    const now = new Date();
    now.setSeconds(0, 0);
    const stamp = new Date(now.getTime() - now.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 16);
    await form.locator('[name="observed"]').fill(stamp);

    await form.locator('button[type="submit"]').click();
    await page.waitForFunction(
      () => {
        const value = document.querySelector('#event-verdict')?.value || '';
        return value.length > 0 && value !== 'Saving…';
      },
      null,
      {timeout: 30000}
    );
    const verdict = await form
      .locator('#event-verdict')
      .evaluate((node) => node.value);
    console.log(`EVENT_VERDICT=${verdict}`);

    // The verdict lands before the view reload finishes, so wait for the card
    // rather than reading the document the instant the text changes.
    await page.waitForFunction(
      (needle) =>
        Array.from(
          document.querySelectorAll('[data-event-kind="service"]')
        ).some((card) => card.textContent.includes(needle)),
      notes,
      {timeout: 30000}
    );
    const cards = await page.evaluate(
      (needle) =>
        Array.from(
          document.querySelectorAll('[data-event-kind="service"]')
        ).filter((card) => card.textContent.includes(needle)).length,
      notes
    );
    console.log(`EVENT_CARDS=${cards}`);
    const subtypeCount = await page.evaluate(
      (needle) => {
        const card = Array.from(
          document.querySelectorAll('[data-event-kind="service"]')
        ).find((item) => item.textContent.includes(needle));
        return card?.querySelectorAll('[data-event-subtype]').length || 0;
      },
      notes
    );
    console.log(`EVENT_SUBTYPES=${subtypeCount}`);
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
