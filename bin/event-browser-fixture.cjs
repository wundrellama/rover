#!/usr/bin/env node
'use strict';

// Drives the M7 T1 "Add event" form in a real browser. The endpoint battery
// proves the write; this proves a person can reach it.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle, station, tag, payment, total, mileage, notes,
  subtypeList
] = process.argv.slice(2);
const subtypes = (subtypeList || '').split(',').filter((name) => name.length > 0);
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
    await form.locator(`#event-tags input[value="${tag}"]`).check();
    // The subtype picker only shows for a service event, and it opens behind a
    // toggle because the catalog is long. A person has to do both of these.
    if (subtypes.length > 0) {
      await form.locator('#event-subtypes').waitFor({state: 'visible'});
      await form.locator('#event-subtypes-toggle').click();
      for (const name of subtypes) {
        await form.locator(`#event-subtypes input[value="${name}"]`).check();
      }
    }
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
    const shown = await page.evaluate(
      (needle) => {
        const card = Array.from(
          document.querySelectorAll('[data-event-kind="service"]')
        ).find((node) => node.textContent.includes(needle));
        if (!card) return '';
        return Array.from(card.querySelectorAll('[data-event-subtype]'))
          .map((node) => node.getAttribute('data-event-subtype'))
          .join(',');
      },
      notes
    );
    console.log(`EVENT_SUBTYPES=${shown}`);

    // Reuse that same Add Event form for a correction. The card carries only
    // the human values needed to prefill it; no database identity crosses the
    // browser boundary.
    const savedCard = page
      .locator('[data-event-kind="service"]')
      .filter({hasText: notes})
      .first();
    const editControl = savedCard.locator('[data-edit-event]');
    const editControlBox = await editControl.boundingBox();
    await editControl.click();
    await form.waitFor({state: 'visible'});
    const formBox = await form.boundingBox();
    const editPrefill = await form.evaluate(
      (node, expected) => {
        const chosen = (name) =>
          Array.from(node.querySelectorAll(`input[name="${name}"]:checked`))
            .map((input) => input.value)
            .sort()
            .join(',');
        return [
          node.elements.vehicle.value,
          node.elements.kind.value,
          node.elements.total.value,
          node.elements.mileage.value,
          node.elements.station.value,
          node.elements.paymentMethod.value,
          node.elements.notes.value,
          chosen('tags'),
          chosen('subtypes'),
          node.elements.kind.disabled ? 'fixed' : 'changeable',
          expected
        ].join('|');
      },
      subtypes.slice().sort().join(',')
    );
    console.log(`EDIT_PREFILL=${editPrefill}`);
    console.log(
      `EDIT_FITS_390=${
        formBox && formBox.x >= 0 && formBox.x + formBox.width <= 390 &&
        editControlBox && editControlBox.height >= 44 &&
        editControlBox.x + editControlBox.width <= 390 ? 'yes' : 'no'
      }`
    );

    await form.locator('[name="total"]').fill('$99.40');
    const responsePromise = page.waitForResponse(
      (response) => response.url().endsWith('/apps/rover/edit-event')
    );
    await form.locator('button[type="submit"]').click();
    const editResponse = await responsePromise;
    console.log(`EDIT_VERDICT=${await editResponse.text()}`);
    await page.waitForFunction(
      (needle) => {
        const card = Array.from(
          document.querySelectorAll('[data-event-kind="service"]')
        ).find((node) => node.textContent.includes(needle));
        return card?.querySelector('[data-event-total]')
          ?.getAttribute('data-event-total') === '$99.40';
      },
      notes,
      {timeout: 30000}
    );
    const correctedCards = await page.evaluate(
      (needle) =>
        Array.from(document.querySelectorAll('[data-event-kind="service"]'))
          .filter((card) => card.textContent.includes(needle)).length,
      notes
    );
    console.log(`EDIT_CARDS=${correctedCards}`);
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
