#!/usr/bin/env node
'use strict';

// Drives the M8 entry surface in a real browser at 390px.
//
// The endpoint battery already proves the bytes move. This proves a person can
// move them: a file input on Add Fill and on Add Event, a photo on the card
// afterwards, and a way to open it full size. A record with no photo must show
// nothing at all - no empty frame.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  url, authName, auth, vehicle, fillPhoto, eventPhoto, eventNote, backend
] = process.argv.slice(2);
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
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});

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
    await fillField.locator('[data-photo-input]').setInputFiles(fillPhoto);
    await fillField.locator('[data-photo-backend]').selectOption(backend);

    // The photo field must fit the phone it is used on.
    const fieldOverflow = await fillField.evaluate(
      (node, width) => Math.ceil(node.getBoundingClientRect().right - width),
      WIDTH
    );
    console.log(`FILL_FIELD_OVERFLOW=${fieldOverflow}`);

    const fillObserved = await fillForm
      .locator('[name="observed"]')
      .evaluate((node) => node.value);
    console.log(`FILL_OBSERVED=${fillObserved}`);
    await fillForm.locator('button[type="submit"]').click();
    console.log(`FILL_VERDICT=${await settledVerdict(page, '#fill-verdict')}`);

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
    const eventObserved = localStamp(-3);
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
