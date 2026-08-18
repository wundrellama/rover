#!/usr/bin/env node
'use strict';

// Drives the M7 T7 specification fields through the vehicle settings form in a
// real browser. The endpoint battery proves the write; this proves a person can
// reach it, and that the vehicle screen then reads like a description.
//
// Every VIN and plate this file receives is synthetic. The caller supplies
// them, and bin/event-test.sh asserts their shape before it does.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle,
  vin, plate, year, make, model, subModel, bodyType, color,
  engine, transmission, driveType, bedType, notes
] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`spec-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
  // The settings panels live behind the vehicles screen, so a person reaches
  // them the same way: open the fleet, then pick the vehicle.
  await page.locator('[data-open-screen="vehicles-screen"]').first().click();
  await page
    .locator(`[data-open-vehicle-settings][data-vehicle="${vehicle}"]`)
    .first()
    .click();
  const panel = page.locator(`[data-vehicle-settings-panel][data-vehicle="${vehicle}"]`);
  await panel.waitFor({state: 'visible'});
  const form = panel.locator('.vehicle-settings-form');

  const group = form.locator('[data-settings-group="specification"]');
  console.log(`SPEC_FIELDSET=${(await group.count()) > 0 ? 'present' : 'absent'}`);

  const fields = {
    specVin: vin,
    specPlate: plate,
    specYear: year,
    specMake: make,
    specModel: model,
    specSubModel: subModel,
    specBodyType: bodyType,
    specColor: color,
    specEngine: engine,
    specTransmission: transmission,
    specDriveType: driveType,
    specBedType: bedType,
    specNotes: notes
  };
  for (const [name, value] of Object.entries(fields)) {
    const control = form.locator(`[name="${name}"]`);
    if ((await control.count()) === 0) {
      fail(`the settings form has no ${name} control`);
      await browser.close();
      return;
    }
    await control.fill(value);
  }

  await form.locator('button[type="submit"]').click();
  await page.waitForFunction(
    (wanted) => {
      const panel = document.querySelector(
        `[data-vehicle-settings-panel][data-vehicle="${wanted}"]`
      );
      const value = panel?.querySelector('.form-verdict')?.value || '';
      return value.length > 0 && value !== 'Saving…';
    },
    vehicle,
    {timeout: 30000}
  );
  const verdict = await form
    .locator('.form-verdict')
    .evaluate((node) => node.value);
  console.log(`SPEC_VERDICT=${verdict}`);

  // The verdict lands before the view reload finishes, so wait for the
  // rendered description rather than reading the document at once.
  await page.waitForFunction(
    (wanted) =>
      document.querySelector(
        `[data-vehicle-settings-panel][data-vehicle="${wanted}"] [data-vehicle-spec="headline"]`
      ) !== null,
    vehicle,
    {timeout: 30000}
  );
  const description = await page.evaluate((wanted) => {
    const panel = document.querySelector(
      `[data-vehicle-settings-panel][data-vehicle="${wanted}"]`
    );
    const read = (part) =>
      panel.querySelector(`[data-vehicle-spec="${part}"]`)?.textContent || '';
    return {
      headline: read('headline'),
      detail: read('detail'),
      vin: read('vin'),
      plate: read('plate'),
      note: read('note')
    };
  }, vehicle);
  console.log(`SPEC_HEADLINE=${description.headline}`);
  console.log(`SPEC_DETAIL=${description.detail}`);
  console.log(`SPEC_VIN_LINE=${description.vin}`);
  console.log(`SPEC_PLATE_LINE=${description.plate}`);
  console.log(`SPEC_NOTE_LINE=${description.note}`);

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
