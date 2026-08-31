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

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, documentPath, backend, mode] = process.argv.slice(2);
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

    if (mode === 'send' && offered.includes(backend)) {
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
