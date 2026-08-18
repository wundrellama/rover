#!/usr/bin/env node
'use strict';

// Drives every T7 vehicle field through the settings form a person uses. The
// endpoint fixtures prove the rows; this proves the controls are reachable,
// correctly named, and return in the rendered vehicle description.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle, vin, plate, make, model, subModel, year,
  color, bodyType, engine, transmission, driveType, bedType, notes
] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`vehicle-specification-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
  await page.getByRole('button', {name: 'Vehicles', exact: true}).click();
  await page.locator(
    `[data-open-vehicle-settings][data-vehicle="${vehicle}"]`
  ).click();
  let panel = page.locator(
    `[data-vehicle-settings-panel][data-vehicle="${vehicle}"]`
  );
  await panel.waitFor({state: 'visible'});
  const form = panel.locator('.vehicle-settings-form');

  const values = {
    vin, licensePlate: plate, make, model, subModel, year, color, bodyType,
    engine, transmission, driveType, bedType, notes
  };
  for (const [name, value] of Object.entries(values)) {
    const control = form.locator(`[name="${name}"]`);
    if (await control.count() !== 1) {
      throw new Error(`expected one settings control named ${name}`);
    }
    await control.fill(value);
  }

  await form.locator('button[type="submit"]').click();
  await page.waitForFunction(
    () => {
      const value = document.querySelector(
        '[data-vehicle-settings-panel]:not([hidden]) .vehicle-settings-form output'
      )?.value || '';
      return value.length > 0 && value !== 'Saving…';
    },
    null,
    {timeout: 30000}
  );
  const verdict = await form.locator('output').evaluate((node) => node.value);
  console.log(`SPECIFICATION_VERDICT=${verdict}`);

  await page.waitForFunction(
    ([wantedVehicle, wantedVin]) => {
      const found = document.querySelector(
        `[data-vehicle-settings-panel][data-vehicle="${wantedVehicle}"] [data-vehicle-vin]`
      );
      return found?.textContent.includes(wantedVin) || false;
    },
    [vehicle, vin],
    {timeout: 30000}
  );
  panel = page.locator(
    `[data-vehicle-settings-panel][data-vehicle="${vehicle}"]`
  );
  const rendered = await panel.locator('[data-vehicle-description]').innerText();
  for (const value of Object.values(values)) {
    if (!rendered.includes(value)) {
      throw new Error(`reloaded vehicle description omits ${value}`);
    }
  }
  console.log('SPECIFICATION_FIELDS=13');
  console.log(`SPECIFICATION_DESCRIPTION=${rendered.replace(/\s+/g, ' ').trim()}`);

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
