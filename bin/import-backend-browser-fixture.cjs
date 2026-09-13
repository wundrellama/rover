#!/usr/bin/env node
'use strict';

// Reads the M8 backend control on the import screen, and watches what the
// screen sends.
//
// The owner picks where the photographs in an import are kept, once, for the
// whole batch. This fixture proves the control offers what the ship can really
// do, and that the choice reaches the endpoint on every batch.
//
//   argv: url authName auth documentPath backend mode
//   mode: "send" presses Start import.  "hold" only reads the screen.

const assert = require('node:assert/strict');
const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, documentPath, backend, mode, importedVehicle] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`import-backend-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  const requests = [];
  const photos = [];
  page.on('request', (request) => {
    const path = new URL(request.url()).pathname;
    if (path.endsWith('/attachment-url') || path.endsWith('/record-attachment') ||
        path.endsWith('/add-attachment') || request.method() === 'PUT') {
      photos.push({path: request.method() === 'PUT' ? 'PUT' : path,
        bytes: request.postDataBuffer()?.length || 0});
    }
  });
  page.on('request', (request) => {
    const path = new URL(request.url()).pathname;
    if (path === '/apps/rover/import') {
      requests.push(new URL(request.url()).pathname + new URL(request.url()).search);
    }
  });
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="settings-screen"]').first().click();
    await page.locator('[data-open-screen="import-screen"]').first().click();
    const form = page.locator('#import-form');
    await form.waitFor({state: 'visible'});

    const field = form.locator('[data-photo-field="import"]');
    await field.waitFor({state: 'visible'});
    await page.waitForFunction(
      () =>
        (document.querySelector('#import-form [data-photo-backend]')?.options
          .length || 0) > 0,
      null,
      {timeout: 30000}
    );
    const control = field.locator('[data-photo-backend]');
    console.log(
      `IMPORT_BACKENDS=${await control.evaluate((node) =>
        [...node.options].map((option) => option.value).join(','))}`
    );
    console.log(
      `IMPORT_BACKEND_NOTE=${await field
        .locator('[data-photo-note]')
        .evaluate((node) => (node.hidden ? '' : node.textContent.trim()))}`
    );
    const offered = await control.evaluate((node) =>
      [...node.options].map((option) => option.value)
    );

    if (mode === 'photos') {
      const note = await field.locator('[data-photo-note]').innerText();
      assert.match(note, /public/i);
      assert.match(note, /anyone/i);
      assert.match(note, /Clay/);
    }
    if ((mode === 'send' || mode === 'photos') && offered.includes(backend)) {
      await control.selectOption(backend);
      await form.locator('#import-file').setInputFiles(documentPath);
      await form.locator('#import-batch-size').fill('400');
      await form.locator('#import-submit').click();
      await page.waitForFunction(
        () => {
          const value =
            document.querySelector('#import-outcome')?.value || '';
          return value.length > 0;
        },
        null,
        {timeout: 120000}
      );
      console.log(
        `IMPORT_OUTCOME=${await form
          .locator('#import-outcome')
          .evaluate((node) => node.dataset.importOutcome)}`
      );
    }

    if (mode === 'photos') {
      assert.equal(await form.locator('#import-outcome').getAttribute('data-import-outcome'), 'success');
      assert.match(await form.locator('#import-outcome').evaluate((node) => node.value), /1 photographs attached/);
      assert.deepEqual(photos.map((item) => item.path), [
        '/apps/rover/attachment-url', 'PUT', '/apps/rover/record-attachment'
      ]);
      assert.equal(photos[0].bytes, 0);
      assert.ok(photos[1].bytes > 0);
      assert.equal(photos[2].bytes, 0);
      console.log('IMPORT_PHOTO_FLOW=metadata,PUT,record');
      if (importedVehicle) {
        for (const name of ['fill', 'event']) {
          const entry = page.locator('#' + name + '-form');
          await entry.locator('[name="vehicle"]').selectOption({label: importedVehicle}, {force: true});
          assert.equal(await entry.locator('[data-photo-backend]').inputValue(), backend,
            name + ' after import without a page reload');
        }
        console.log('IMPORT_NEXT_FORMS=' + backend);
      }
    }
    console.log(`IMPORT_REQUEST_COUNT=${requests.length}`);
    const wanted = `/apps/rover/import?backend=${backend}`;
    requests.forEach((request) => {
      console.log(`IMPORT_REQUEST=${request}`);
    });
    console.log(
      `IMPORT_REQUEST_COUNT_DISAGREEING=${
        requests.filter((request) => request !== wanted).length
      }`
    );
  } catch (error) {
    fail(error.message);
  } finally {
    await browser.close();
  }
})();
