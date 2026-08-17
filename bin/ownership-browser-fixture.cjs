#!/usr/bin/env node
'use strict';

// Drives the M7 T4 purchase and sale through the "Add event" form in a real
// browser. The endpoint battery proves the write; this proves a person can
// reach it, and that the disposal-kind picker shows only where it belongs.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle,
  buyTotal, buyMileage, buyNotes,
  sellTotal, sellMileage, sellNotes, disposalKind
] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`ownership-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

function localStamp(minutesAgo) {
  const now = new Date(Date.now() - minutesAgo * 60000);
  now.setSeconds(0, 0);
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  // One pass of the form. `kind` selects the route, so the two passes differ
  // only in what a person picks from the Kind control.
  const record = async (kind, total, mileage, notes, observed) => {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="add-event"]').first().click();
    const form = page.locator('#event-form');
    await form.waitFor({state: 'visible'});
    await form.locator('[name="vehicle"]').selectOption(vehicle);
    await form.locator('[name="kind"]').selectOption(kind);
    await form.locator('[name="total"]').fill(total);
    await form.locator('[name="mileage"]').fill(mileage);
    if (kind === 'disposal') {
      await form.locator('#event-disposal-kind').waitFor({state: 'visible'});
      await form.locator('[name="disposalKind"]').selectOption(disposalKind);
    } else {
      const shown = await page.evaluate(
        () => !document.querySelector('#event-disposal-kind')?.hidden
      );
      console.log(`KIND_FIELD_ON_ACQUISITION=${shown ? 'shown' : 'hidden'}`);
    }
    await form.locator('[name="notes"]').fill(notes);
    await form.locator('[name="observed"]').fill(observed);
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
    console.log(`${kind.toUpperCase()}_VERDICT=${verdict}`);

    // The verdict lands before the view reload finishes, so wait for the card
    // rather than reading the document the instant the text changes.
    await page.waitForFunction(
      ([wanted, needle]) =>
        Array.from(
          document.querySelectorAll(`[data-event-kind="${wanted}"]`)
        ).some((card) => card.textContent.includes(needle)),
      [kind, notes],
      {timeout: 30000}
    );
    const cards = await page.evaluate(
      ([wanted, needle]) =>
        Array.from(
          document.querySelectorAll(`[data-event-kind="${wanted}"]`)
        ).filter((card) => card.textContent.includes(needle)).length,
      [kind, notes]
    );
    console.log(`${kind.toUpperCase()}_CARDS=${cards}`);
    if (kind === 'disposal') {
      const shown = await page.evaluate(
        (needle) => {
          const card = Array.from(
            document.querySelectorAll('[data-event-kind="disposal"]')
          ).find((node) => node.textContent.includes(needle));
          if (!card) return '';
          return (
            card
              .querySelector('[data-event-disposal-kind]')
              ?.getAttribute('data-event-disposal-kind') || ''
          );
        },
        notes
      );
      console.log(`DISPOSAL_KIND=${shown}`);
    }
  };

  try {
    await record('acquisition', buyTotal, buyMileage, buyNotes, localStamp(120));
    await record('disposal', sellTotal, sellMileage, sellNotes, localStamp(60));
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
