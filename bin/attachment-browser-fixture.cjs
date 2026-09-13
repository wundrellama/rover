#!/usr/bin/env node
'use strict';

// Drives the M8 entry surface in a real browser at 390px.
//
// The endpoint battery already proves the bytes move. This proves a person can
// move them: a file input on Add Fill and on Add Event, a photo on the card
// afterwards, and a way to open it full size. A record with no photo must show
// nothing at all - no empty frame.

const assert = require('node:assert/strict');
const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

// `mode` is "enter" for the whole journey, or "verify" to read a vehicle whose
// records were entered earlier. The verify pass is what fixture 114 runs on the
// far side of a ship restart: the same card, the same address, the same photo.
const [
  url, authName, auth, vehicle, fillPhoto, eventPhoto, eventNote, backend,
  mode, knownFillObserved, knownEventObserved
] = process.argv.slice(2);
const entering = mode !== 'verify';
const executablePath = process.env.ROVER_CHROMIUM;
const WIDTH = 390;

function fail(message) {
  console.error(`attachment-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

function localStamp(offsetMinutes) {
  const now = new Date();
  now.setSeconds(0, 0);
  now.setMinutes(now.getMinutes() + offsetMinutes);
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
}

async function settledVerdict(page, selector) {
  await page.waitForFunction(
    (target) => {
      const value = document.querySelector(target)?.value || '';
      return value.length > 0 && value !== 'Saving…';
    },
    selector,
    {timeout: 60000}
  );
  return page.locator(selector).evaluate((node) => node.value);
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({
    viewport: {width: WIDTH, height: 844}
  });
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  const transfers = [];
  page.on('request', (request) => {
    const parsed = new URL(request.url());
    if (['/apps/rover/attachment-url', '/apps/rover/record-attachment',
         '/apps/rover/add-attachment'].includes(parsed.pathname) ||
        request.method() === 'PUT') {
      transfers.push({path: parsed.pathname, method: request.method(),
        bytes: request.postDataBuffer()?.length || 0, headers: request.headers()});
    }
  });
  if (mode === 'refusal') {
    await page.route('**/attachments/**', async (route) => {
      if (route.request().method() === 'PUT') {
        await route.fulfill({status: 503, headers: {'access-control-allow-origin': '*'}});
      } else await route.continue();
    });
  }
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});

    let fillObserved = knownFillObserved;
    let eventObserved = knownEventObserved;
    if (entering) {
    // ---- Add Fill, with a photo -------------------------------------------
    await page.locator('[data-open-screen="add-fill"]').first().click();
    const fillForm = page.locator('#fill-form');
    await fillForm.waitFor({state: 'visible'});
    await fillForm.locator('[name="vehicle"]').selectOption(vehicle);
    // A fill is a fuel acquisition, so the energy source has to be one this
    // vehicle burns. The control hides itself when the vehicle carries only
    // one source, so the choice is made on the element rather than through it.
    //
    // The option is picked by INDEX. Every vehicle contributes its own
    // "Gasoline" option, so setting the value would select the first one that
    // reads Gasoline, which belongs to another vehicle and is hidden.
    const chosenDefinition = await fillForm
      .locator('[name="definition"]')
      .evaluate((node, owner) => {
        const index = [...node.options].findIndex(
          (candidate) =>
            candidate.dataset.vehicle === owner &&
            candidate.dataset.kind === 'reservoir'
        );
        if (index < 0) return '';
        node.selectedIndex = index;
        node.dispatchEvent(new Event('change', {bubbles: true}));
        return node.value;
      }, vehicle);
    console.log(`FILL_DEFINITION=${chosenDefinition}`);
    await fillForm.locator('[name="price"]').fill('$3.49');
    await fillForm.locator('[name="quantity"]').fill('11.5');

    // The photo control is one fieldset, reused by both forms. Its backend
    // list comes from /apps/rover/backends.json, so what it offers is what
    // the ship can really do.
    const fillField = fillForm.locator('[data-photo-field="fill"]');
    await fillField.waitFor({state: 'visible'});
    await page.waitForFunction(
      () =>
        (document.querySelector('#fill-form [data-photo-backend]')?.options
          .length || 0) > 0,
      null,
      {timeout: 30000}
    );
    const fillBackends = await fillField
      .locator('[data-photo-backend]')
      .evaluate((node) => [...node.options].map((option) => option.value).join(','));
    console.log(`FILL_BACKENDS=${fillBackends}`);
    const fillNote = await fillField
      .locator('[data-photo-note]')
      .evaluate((node) => (node.hidden ? '' : node.textContent.trim()));
    console.log(`FILL_BACKEND_NOTE=${fillNote}`);
    if (backend === 's3') {
      assert.match(fillNote, /public/i);
      assert.match(fillNote, /anyone/i);
      assert.match(fillNote, /Clay/);
    }
    await fillField.locator('[data-photo-input]').setInputFiles(fillPhoto);
    await fillField.locator('[data-photo-backend]').selectOption(backend);

    // The photo field must fit the phone it is used on.
    const fieldOverflow = await fillField.evaluate(
      (node, width) => Math.ceil(node.getBoundingClientRect().right - width),
      WIDTH
    );
    console.log(`FILL_FIELD_OVERFLOW=${fieldOverflow}`);

    fillObserved = await fillForm
      .locator('[name="observed"]')
      .evaluate((node) => node.value);
    console.log(`FILL_OBSERVED=${fillObserved}`);
    await fillForm.locator('button[type="submit"]').click();
    const fillVerdict = await settledVerdict(page, '#fill-verdict');
    console.log(`FILL_VERDICT=${fillVerdict}`);
    if (mode === 'refusal') {
      assert.match(fillVerdict, /503/);
      assert.equal(transfers.filter((item) => item.path.endsWith('/record-attachment')).length, 0);
      assert.equal(transfers.filter((item) => item.method === 'PUT').length, 1);
      console.log('REFUSED_PUT_RECORDED=no');
      return;
    }

    // ---- Add Event, with a photo ------------------------------------------
    // The saved fill reloads the log, which puts the main hub back on screen.
    const addEvent = page.locator('[data-open-screen="add-event"]').first();
    await addEvent.waitFor({state: 'visible', timeout: 60000});
    await addEvent.click();
    const eventForm = page.locator('#event-form');
    await eventForm.waitFor({state: 'visible'});
    await eventForm.locator('[name="vehicle"]').selectOption(vehicle);
    await eventForm.locator('[name="kind"]').selectOption('note');
    await eventForm.locator('[name="notes"]').fill(eventNote);
    eventObserved = localStamp(-3);
    await eventForm.locator('[name="observed"]').fill(eventObserved);
    console.log(`EVENT_OBSERVED=${eventObserved}`);
    const eventField = eventForm.locator('[data-photo-field="event"]');
    await page.waitForFunction(
      () =>
        (document.querySelector('#event-form [data-photo-backend]')?.options
          .length || 0) > 0,
      null,
      {timeout: 30000}
    );
    await eventField.locator('[data-photo-input]').setInputFiles(eventPhoto);
    await eventField.locator('[data-photo-backend]').selectOption(backend);
    await eventForm.locator('button[type="submit"]').click();
    console.log(`EVENT_VERDICT=${await settledVerdict(page, '#event-verdict')}`);
    }
    console.log(`FILL_OBSERVED_READ=${fillObserved}`);
    console.log(`EVENT_OBSERVED_READ=${eventObserved}`);

    // ---- The photo on the card --------------------------------------------
    await page.locator('[data-open-screen="vehicles-screen"]').first().click();
    await page
      .locator(`[data-open-vehicle-settings][data-vehicle="${vehicle}"]`)
      .first()
      .click();
    const fillCard = page.locator(
      `[data-photo-owner="energy"][data-photo-observed="${fillObserved}"]`
    );
    await fillCard.first().waitFor({state: 'visible'});
    await page.waitForFunction(
      (moment) =>
        (document.querySelector(
          `[data-photo-owner="energy"][data-photo-observed="${moment}"] [data-photo-strip] .photo-thumb`
        ) !== null),
      fillObserved,
      {timeout: 30000}
    );
    const fillThumbs = fillCard.first().locator('.photo-thumb');
    console.log(`FILL_CARD_PHOTOS=${await fillThumbs.count()}`);
    console.log(
      `FILL_CARD_PHOTO_NAME=${await fillThumbs
        .first()
        .evaluate((node) => node.dataset.photoName)}`
    );

    const eventCard = page.locator(
      `[data-photo-owner="event"][data-photo-observed="${eventObserved}"]`
    );
    await page.waitForFunction(
      (moment) =>
        (document.querySelector(
          `[data-photo-owner="event"][data-photo-observed="${moment}"] [data-photo-strip] .photo-thumb`
        ) !== null),
      eventObserved,
      {timeout: 30000}
    );
    const eventThumbs = eventCard.first().locator('.photo-thumb');
    console.log(`EVENT_CARD_PHOTOS=${await eventThumbs.count()}`);
    console.log(
      `EVENT_CARD_PHOTO_NAME=${await eventThumbs
        .first()
        .evaluate((node) => node.dataset.photoName)}`
    );

    // Absence is stated by absence. A record with no photo carries no strip
    // at all, so there is no empty frame for a person to wonder about.
    const emptyStrips = await page.evaluate(() =>
      [...document.querySelectorAll('[data-photo-strip]')].filter(
        (strip) => strip.querySelectorAll('.photo-thumb').length === 0
      ).length
    );
    console.log(`EMPTY_PHOTO_STRIPS=${emptyStrips}`);
    const cardsWithoutPhotos = await page.evaluate(() =>
      [...document.querySelectorAll('[data-photo-owner]')].filter(
        (card) => card.querySelector('[data-photo-strip]') === null
      ).length
    );
    console.log(`CARDS_WITHOUT_PHOTOS=${cardsWithoutPhotos}`);

    // ---- Full size ---------------------------------------------------------
    await fillThumbs.first().click();
    const view = page.locator('#photo-view');
    await view.waitFor({state: 'visible'});
    // The decoded size is the proof. A broken link renders 0x0.
    await page.waitForFunction(
      () => {
        const image = document.getElementById('photo-view-image');
        return image.complete && image.naturalWidth > 0;
      },
      null,
      {timeout: 30000}
    );
    const opened = await page.evaluate(() => {
      const image = document.getElementById('photo-view-image');
      return {
        src: image.getAttribute('src'),
        natural: `${image.naturalWidth}x${image.naturalHeight}`,
        rendered: Math.round(image.getBoundingClientRect().width),
        name: document.getElementById('photo-view-name').textContent
      };
    });
    if (backend === 's3') {
      assert.match(opened.src, /^https?:\/\/[^?]+\/attachments\/[a-f0-9]{64}$/);
      if (entering) {
        assert.deepEqual(transfers.map((item) => item.method === 'PUT' ? 'PUT' : item.path), [
          '/apps/rover/attachment-url', 'PUT', '/apps/rover/record-attachment',
          '/apps/rover/attachment-url', 'PUT', '/apps/rover/record-attachment'
        ]);
        for (const transfer of transfers) {
          if (transfer.method === 'PUT') {
            assert.ok(transfer.bytes > 0);
            assert.equal(transfer.headers.cookie, undefined);
            assert.equal(transfer.headers.authorization, undefined);
          } else assert.equal(transfer.bytes, 0);
        }
        console.log('S3_BROWSER_FLOW=metadata,PUT,record; metadata,PUT,record');
      }
    }
    console.log(`PHOTO_VIEW_SRC=${opened.src}`);
    console.log(`PHOTO_VIEW_NATURAL=${opened.natural}`);
    console.log(`PHOTO_VIEW_RENDERED=${opened.rendered}`);
    console.log(`PHOTO_VIEW_NAME=${opened.name}`);

    // ---- 390px -------------------------------------------------------------
    const overflow = await page.evaluate(
      (width) => document.documentElement.scrollWidth - width,
      WIDTH
    );
    console.log(`PAGE_OVERFLOW=${overflow}`);
    await page.locator('#photo-view-close').click();
    console.log(
      `PHOTO_VIEW_CLOSED=${await view.evaluate((node) => (node.hidden ? 'yes' : 'no'))}`
    );
  } catch (error) {
    fail(error.message);
  } finally {
    await browser.close();
  }
})();
