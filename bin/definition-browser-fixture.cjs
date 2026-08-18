#!/usr/bin/env node
'use strict';

// Drives the M7 T8 definition lifecycle through the Settings screen in a real
// browser: rename, archive, restore. The endpoint battery proves the writes;
// this proves a person can reach all three without curl.
//
// Both controls raise a browser dialog - rename asks for the new label and
// archive asks for confirmation - so the dialogs are answered here the way a
// person answers them.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, family, label, renamed] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`definition-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  // The next dialog answer. A prompt takes the text, a confirm takes accept.
  let promptAnswer = null;
  page.on('dialog', async (dialog) => {
    if (dialog.type() === 'prompt') await dialog.accept(promptAnswer ?? '');
    else await dialog.accept();
  });

  // Reach the settings screen from a known starting point. The app hides one
  // screen and shows another rather than navigating, so the Settings button is
  // itself hidden while the settings screen is the one on display.
  const openSettings = async () => {
    if (await page.locator('#settings-screen').isVisible().catch(() => false)) return;
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="settings-screen"]').first().click();
    await page.locator('#settings-screen').waitFor({state: 'visible'});
  };

  const entry = () =>
    page.locator(
      `[data-definition-entry][data-definition-family="${family}"]` +
      `[data-definition-label="${currentLabel}"]`
    );

  // The verdict output is cleared before each write, so the wait below reads
  // this write's answer rather than the one before it. Every write reloads
  // the served view, so the settings screen is re-opened before each click
  // rather than once at the start.
  const clickAndWait = async (makeControl) => {
    await openSettings();
    await page.evaluate(() => {
      const output = document.querySelector('#definition-verdict');
      if (output) output.value = '';
    });
    await makeControl().click();
    await page.waitForFunction(
      () => (document.querySelector('#definition-verdict')?.value || '').length > 0,
      null,
      {timeout: 30000}
    );
    return page.locator('#definition-verdict').evaluate((node) => node.value);
  };

  // Is this label offered in the Add Fill tag list - a selector a person
  // picks from, not the settings list that manages the definition?
  const offeredOnAddFill = async (wanted) => {
    // Load the app fresh, so this reads the served document rather than
    // whatever screen the last write left on the display.
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    await page.locator('[data-open-screen="add-fill"]').first().click();
    await page.locator('#add-fill').waitFor({state: 'visible'});
    const count = await page
      .locator(`#add-fill input[name="tags"][value="${wanted}"]`)
      .count();
    return count > 0 ? 'present' : 'absent';
  };

  await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
  await openSettings();

  let currentLabel = label;
  console.log(
    `DEF_PANEL=${
      (await page.locator('[data-settings-section="definitions"]').count()) > 0
        ? 'present'
        : 'absent'
    }`
  );
  if ((await entry().count()) === 0) {
    fail(`the definitions panel does not list ${label}`);
    await browser.close();
    return;
  }

  promptAnswer = renamed;
  const renameVerdict = await clickAndWait(() => entry().locator('[data-rename-definition]'));
  console.log(`DEF_RENAME_VERDICT=${renameVerdict}`);
  await page.waitForFunction(
    (wanted) =>
      document.querySelector(`[data-definition-label="${wanted}"]`) !== null,
    renamed,
    {timeout: 30000}
  );
  currentLabel = renamed;
  console.log(`DEF_RENAMED_ENTRY=${await entry().getAttribute('data-definition-label')}`);

  const archiveVerdict = await clickAndWait(() => entry().locator('[data-archive-definition]'));
  console.log(`DEF_ARCHIVE_VERDICT=${archiveVerdict}`);
  await page.waitForFunction(
    (wanted) =>
      document
        .querySelector(`[data-definition-label="${wanted}"]`)
        ?.hasAttribute('data-definition-archived') === true,
    renamed,
    {timeout: 30000}
  );
  console.log(
    `DEF_ARCHIVED_FLAG=${
      (await entry().getAttribute('data-definition-archived')) === null ? 'no' : 'yes'
    }`
  );
  console.log(`DEF_SELECTOR_WHILE_ARCHIVED=${await offeredOnAddFill(renamed)}`);

  const restoreVerdict = await clickAndWait(() => entry().locator('[data-restore-definition]'));
  console.log(`DEF_RESTORE_VERDICT=${restoreVerdict}`);
  await page.waitForFunction(
    (wanted) =>
      document
        .querySelector(`[data-definition-label="${wanted}"]`)
        ?.hasAttribute('data-definition-archived') === false,
    renamed,
    {timeout: 30000}
  );
  console.log(
    `DEF_ARCHIVED_FLAG_AFTER_RESTORE=${
      (await entry().getAttribute('data-definition-archived')) === null ? 'no' : 'yes'
    }`
  );
  console.log(`DEF_SELECTOR_AFTER_RESTORE=${await offeredOnAddFill(renamed)}`);

  await browser.close();
})().catch((error) => {
  fail(error.message);
  process.exit(1);
});
