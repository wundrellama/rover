#!/usr/bin/env node
'use strict';

// Drives the M7 T12 correction in a real browser at 390px. The endpoint
// battery proves the write; this proves a person can reach it: open the card,
// press Edit, change a value, save, and see one corrected card.

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [url, authName, auth, vehicle, notes, correctedTotal, removeTag] =
  process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

function fail(message) {
  console.error(`correction-browser-fixture: FAIL - ${message}`);
  process.exitCode = 1;
}

// The card a person is looking at: the one on this vehicle's panel that
// carries this run's note.
function cardHandle(page, needle) {
  return page.locator('article.history-card.event', {hasText: needle}).first();
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();
  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'networkidle'});
    // A person reaches an event card through the vehicle it belongs to: open
    // the fleet, pick the vehicle, read its history.
    await page.locator('[data-open-screen="vehicles-screen"]').first().click();
    await page
      .locator(`[data-open-vehicle-settings][data-vehicle="${vehicle}"]`)
      .first()
      .click();
    const panel = page.locator(
      `[data-vehicle-settings-panel][data-vehicle="${vehicle}"]`
    );
    await panel.waitFor({state: 'visible'});

    const card = cardHandle(panel, notes);
    await card.waitFor({state: 'visible', timeout: 30000});

    // The control has to be reachable with a pointer inside 390px, not merely
    // present in the document.
    const edit = card.locator('[data-edit-event]');
    await edit.waitFor({state: 'visible'});
    const box = await edit.boundingBox();
    if (!box) fail('the edit control has no box');
    else {
      console.log(`EDIT_RIGHT_EDGE=${Math.round(box.x + box.width)}`);
      console.log(`EDIT_VISIBLE=${box.width > 0 && box.height > 0 ? 'yes' : 'no'}`);
    }

    await edit.click();

    const form = page.locator('#event-form');
    await form.waitFor({state: 'visible'});
    // The form opened pre-filled. These are read before anything is typed.
    console.log(
      `FORM_VEHICLE=${await form.locator('[name="vehicle"]').inputValue()}`
    );
    console.log(`FORM_KIND=${await form.locator('[name="kind"]').inputValue()}`);
    console.log(`FORM_TOTAL=${await form.locator('[name="total"]').inputValue()}`);
    console.log(`FORM_NOTES=${await form.locator('[name="notes"]').inputValue()}`);
    console.log(
      `FORM_MILEAGE=${await form.locator('[name="mileage"]').inputValue()}`
    );
    console.log(
      `FORM_ORIGINAL=${await form.locator('[name="originalObserved"]').inputValue()}`
    );
    // textContent, not innerText: the theme uppercases the button, and the
    // assertion is about what the form says, not how it is painted.
    console.log(
      `FORM_SUBMIT=${await form
        .locator('button[type="submit"]')
        .evaluate((node) => node.textContent)}`
    );
    const checkedTags = await form.evaluate((node) =>
      Array.from(node.querySelectorAll('input[name="tags"]:checked'))
        .map((box) => box.value)
        .join(',')
    );
    console.log(`FORM_TAGS=${checkedTags}`);

    // The form must fit the viewport it is used on. A control wider than the
    // screen is a control a person cannot press.
    const overflow = await page.evaluate(() => {
      const root = document.querySelector('#add-event');
      if (!root) return -1;
      return Math.round(root.scrollWidth - document.documentElement.clientWidth);
    });
    console.log(`FORM_OVERFLOW=${overflow}`);

    // The correction itself: a new total, and one tag unchecked.
    await form.locator('[name="total"]').fill(correctedTotal);
    if (removeTag) {
      const box = form.locator(`#event-tags input[value="${removeTag}"]`);
      if (await box.isChecked()) await box.uncheck();
    }
    await form.locator('button[type="submit"]').click();
    await page.waitForFunction(
      () => {
        const value = document.querySelector('#event-verdict')?.value || '';
        return value.length > 0 && value !== 'Saving…';
      },
      null,
      {timeout: 30000}
    );
    console.log(
      `EDIT_VERDICT=${await form.locator('#event-verdict').evaluate((n) => n.value)}`
    );

    // The verdict lands before the reload finishes, so wait for the corrected
    // figure rather than reading the document the instant the text changes.
    await page.waitForFunction(
      ([needle, want]) =>
        Array.from(document.querySelectorAll('article.history-card.event')).some(
          (node) =>
            node.textContent.includes(needle) &&
            node.querySelector(`[data-event-total="${want}"]`)
        ),
      [notes, correctedTotal],
      {timeout: 30000}
    );
    const after = await page.evaluate(
      ([needle, want]) => {
        const cards = Array.from(
          document.querySelectorAll('article.history-card.event')
        ).filter((node) => node.textContent.includes(needle));
        return {
          count: cards.length,
          total: cards[0]?.querySelector('[data-event-total]')
            ?.getAttribute('data-event-total') || '',
          tags: Array.from(cards[0]?.querySelectorAll('[data-event-tag]') || [])
            .map((node) => node.getAttribute('data-event-tag'))
            .join(','),
          matched: cards.filter((node) =>
            node.querySelector(`[data-event-total="${want}"]`)
          ).length
        };
      },
      [notes, correctedTotal]
    );
    console.log(`EDIT_CARDS=${after.count}`);
    console.log(`EDIT_CARD_TOTAL=${after.total}`);
    console.log(`EDIT_CARD_TAGS=${after.tags}`);
    console.log(`EDIT_CARDS_CORRECTED=${after.matched}`);

    // Leaving the correction and opening Add Event again gives an empty form.
    // The correction target must not outlive the screen. Saving reloads the
    // view, so which screen shows afterwards is not fixed, and a person leaves
    // by whichever way out is in front of them.
    const back = page.locator('#add-event [data-open-screen="main-hub"]').first();
    const cancel = page.locator('#event-form [data-close-screen]').first();
    if (await back.isVisible()) await back.click();
    else if (await cancel.isVisible()) await cancel.click();
    await page.locator('[data-open-screen="add-event"]').first().click();
    await form.waitFor({state: 'visible'});
    console.log(
      `RESET_ORIGINAL=${await form.locator('[name="originalObserved"]').inputValue()}`
    );
    console.log(`RESET_TOTAL=${await form.locator('[name="total"]').inputValue()}`);
    console.log(
      `RESET_SUBMIT=${await form
        .locator('button[type="submit"]')
        .evaluate((node) => node.textContent)}`
    );
  } catch (error) {
    fail(error.stack || error.message);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
