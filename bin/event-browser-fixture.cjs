#!/usr/bin/env node
'use strict';

// Drives the shared "Add event" form in a real browser. The endpoint battery
// proves the writes; this proves a person can reach every event-family path.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle, station, tag, payment, total, mileage, notes,
  subtypeList, acquisitionNote, disposalNote
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

    const saveOwnership = async (kind, amount, reading, note, disposalKind) => {
      await page.locator('[data-open-screen="add-event"]').first().click();
      await form.waitFor({state: 'visible'});
      await form.locator('[name="vehicle"]').selectOption(vehicle);
      await form.locator('[name="kind"]').selectOption(kind);
      if (kind === 'disposal') {
        const kindControl = form.locator('[name="disposalKind"]');
        await kindControl.waitFor({state: 'visible'});
        await kindControl.selectOption({label: disposalKind});
      }
      await form.locator('[name="total"]').fill(amount);
      await form.locator('[name="mileage"]').fill(reading);
      await form.locator('[name="notes"]').fill(note);

      await form.locator('button[type="submit"]').click();
      await page.waitForFunction(
        () => {
          const value = document.querySelector('#event-verdict')?.value || '';
          return value.length > 0 && value !== 'Saving…';
        },
        null,
        {timeout: 30000}
      );
      const ownershipVerdict = await form
        .locator('#event-verdict')
        .evaluate((node) => node.value);
      console.log(`${kind.toUpperCase()}_VERDICT=${ownershipVerdict}`);
      await page.waitForFunction(
        ({eventKind, needle}) =>
          Array.from(
            document.querySelectorAll(`[data-event-kind="${eventKind}"]`)
          ).some((card) => card.textContent.includes(needle)),
        {eventKind: kind, needle: note},
        {timeout: 30000}
      );
    };

    if (acquisitionNote && disposalNote) {
      await saveOwnership(
        'acquisition', '$22,000.00', '56000', acquisitionNote, ''
      );
      await saveOwnership(
        'disposal', '$19,000.00', '56100', disposalNote, 'Gifted'
      );
      const ownershipCards = await page.evaluate(
        ({acquisitionNeedle, disposalNeedle}) => {
          const cards = Array.from(document.querySelectorAll('.history-card.event'));
          return cards.filter(
            (card) =>
              card.textContent.includes(acquisitionNeedle) ||
              card.textContent.includes(disposalNeedle)
          ).length;
        },
        {acquisitionNeedle: acquisitionNote, disposalNeedle: disposalNote}
      );
      console.log(`OWNERSHIP_CARDS=${ownershipCards}`);
      const gifted = await page.locator(
        `[data-event-kind="disposal"][data-disposal-kind="Gifted"]`
      ).filter({hasText: disposalNote}).count();
      console.log(`GIFTED_CARDS=${gifted}`);
    }
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
