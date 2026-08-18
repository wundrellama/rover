#!/usr/bin/env node
'use strict';

// Drives rename, archive, and restore from Settings in a real browser. Every
// operation uses a visible control. The endpoint battery checks the database
// and selectors separately.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, stamp, customField, tag, payment] =
  process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;
const definitions = [
  ['energy', 'Gasoline'],
  ['driving-mode', 'Normal'],
  ['consumable', 'Washer Fluid'],
  ['service-subtype', 'Engine Oil'],
  ['disposal-kind', 'Sold'],
  ['additive', 'Fuel stabilizer'],
  ['tag', tag],
  ['payment-method', payment],
  ['custom-field', customField]
];

function fail(message) {
  console.error(`definition-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

function row(page, family, label) {
  return page.locator(
    `[data-definition-family="${family}"][data-definition-label="${label}"]`
  );
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  let renamed = 0;
  let archived = 0;
  let restored = 0;

  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="settings-screen"]').first().click();
    await page.locator('#settings-screen').waitFor({state: 'visible'});

    for (const [family, original] of definitions) {
      const corrected = `${original} browser ${stamp}`;
      const originalRow = row(page, family, original);
      await originalRow.waitFor({state: 'visible'});
      await originalRow.locator('[data-definition-rename-input]').fill(corrected);
      await originalRow.locator('[data-rename-definition]').click();
      await row(page, family, corrected).waitFor({state: 'visible'});
      renamed += 1;

      const correctedRow = row(page, family, corrected);
      await correctedRow.locator('[data-toggle-definition]').click();
      await page.waitForFunction(
        ([wantedFamily, wantedLabel]) =>
          document.querySelector(
            `[data-definition-family="${wantedFamily}"][data-definition-label="${wantedLabel}"][data-definition-archived="yes"]`
          ) !== null,
        [family, corrected],
        {timeout: 30000}
      );
      archived += 1;

      await row(page, family, corrected)
        .locator('[data-toggle-definition]')
        .click();
      await page.waitForFunction(
        ([wantedFamily, wantedLabel]) =>
          document.querySelector(
            `[data-definition-family="${wantedFamily}"][data-definition-label="${wantedLabel}"][data-definition-archived="no"]`
          ) !== null,
        [family, corrected],
        {timeout: 30000}
      );
      restored += 1;

      const restoredRow = row(page, family, corrected);
      await restoredRow.locator('[data-definition-rename-input]').fill(original);
      await restoredRow.locator('[data-rename-definition]').click();
      await row(page, family, original).waitFor({state: 'visible'});
    }

    console.log(`DEFINITION_FAMILIES=${definitions.length}`);
    console.log(`DEFINITION_RENAMED=${renamed}`);
    console.log(`DEFINITION_ARCHIVED=${archived}`);
    console.log(`DEFINITION_RESTORED=${restored}`);
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
