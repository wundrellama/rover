#!/usr/bin/env node
'use strict';

const fs = require('fs');
const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [
  mode,
  url,
  authName,
  auth,
  ship,
  firstVehicle,
  secondVehicle,
  importPath,
  importBatchSize
] = process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

const IMPORT_OUTCOMES = ['success', 'incomplete', 'blocked', 'stopped', 'refused'];

function fail(message) {
  console.error(`ui-browser-fixtures: FAIL - ${message}`);
  process.exitCode = 1;
}

async function headerText(page) {
  const locator = page.locator('#rover-designation, .terminal-header .designation').first();
  return (await locator.innerText()).replace(/\s+/g, ' ').trim();
}

async function setDefaultVehicle(page, vehicle) {
  const result = await page.evaluate(async (selected) => {
    const response = await fetch('/apps/rover/set-default-vehicle', {
      method: 'POST',
      credentials: 'same-origin',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({vehicle: selected})
    });
    return {ok: response.ok, status: response.status, body: await response.text()};
  }, vehicle);
  if (!result.ok) {
    throw new Error(
      `set default ${vehicle} returned ${result.status}: ${result.body}`
    );
  }
}

async function testVehicleSettingsLayout(page, vehicle) {
  await page.getByRole('button', {name: 'Vehicles', exact: true}).click();
  await page.locator(
    `[data-open-vehicle-settings][data-vehicle="${vehicle}"]`
  ).click();
  const panel = page.locator(
    `[data-vehicle-settings-panel][data-vehicle="${vehicle}"]`
  );
  await panel.waitFor({state: 'visible'});

  const measurement = await panel.evaluate((root) => {
    const groups = [...root.querySelectorAll(
      '.vehicle-settings-form > [data-settings-group]'
    )];
    const legends = groups.map(
      (group) => group.querySelector(':scope > legend')?.textContent.trim() || ''
    );
    const defToggle = root.querySelector('[data-def-toggle-row]');
    const defTank = root.querySelector('[data-def-tank-row]');
    const fuel = root.querySelector('[data-settings-group="fuel-system"]');
    const energy = root.querySelector('[data-settings-group="energy-sources"]');
    const addEnergy = energy?.querySelector('[data-add-energy-source]');
    const defaultEnergy = energy?.querySelector('[name="defaultEnergy"]');
    const targets = [...root.querySelectorAll(
      'button, input:not([type="hidden"]), select, summary'
    )].filter(
      (control) =>
        !control.disabled &&
        getComputedStyle(control).display !== 'none' &&
        control.getClientRects().length > 0
    );
    const shortTargets = targets.flatMap((control) => {
      const target = control.matches('input[type="checkbox"]')
        ? control.closest('label')
        : control;
      const box = target.getBoundingClientRect();
      return box.height + 0.01 < 44
        ? [`${control.tagName.toLowerCase()}[${control.name || control.type || ''}]=${box.height}`]
        : [];
    });
    return {
      legends,
      defSeparate:
        Boolean(defToggle && defTank) &&
        defToggle !== defTank &&
        defToggle.textContent.trim() === 'Enable DEF' &&
        defTank.textContent.includes('DEF tank size'),
      fuelFields: Boolean(
        fuel?.querySelector('[name="defaultSubtype"]') &&
        fuel?.querySelector('[name="tankSize"]') &&
        fuel?.querySelector('[name="tankUnit"]')
      ),
      defaultInsideEnergy: Boolean(
        energy && addEnergy && defaultEnergy &&
        addEnergy.compareDocumentPosition(defaultEnergy) &
          Node.DOCUMENT_POSITION_FOLLOWING
      ),
      overflow:
        document.documentElement.scrollWidth > document.documentElement.clientWidth,
      shortTargets
    };
  });

  if (
    measurement.legends.slice(0, 4).join('|') !==
      'Fuel System|Energy Sources|Driving Modes|DEF' ||
    !measurement.defSeparate ||
    !measurement.fuelFields ||
    !measurement.defaultInsideEnergy ||
    measurement.overflow ||
    measurement.shortTargets.length
  ) {
    throw new Error(`vehicle settings layout failed: ${JSON.stringify(measurement)}`);
  }

  const defToggle = panel.locator('[name="defEnabled"]');
  const defTankRow = panel.locator('[data-def-tank-row]');
  if (await defToggle.isChecked()) {
    await defToggle.uncheck();
    if (await defTankRow.isVisible()) {
      throw new Error(
        `DEF tank row remains visible after DEF is disabled: ${JSON.stringify(
          await defTankRow.evaluate((row) => ({
            hidden: row.hidden,
            display: getComputedStyle(row).display,
            toggle: row.parentElement.querySelector('[name="defEnabled"]')?.checked
          }))
        )}`
      );
    }
    await defToggle.check();
  }
  if (!await defTankRow.isVisible()) {
    throw new Error('DEF tank row is absent after DEF is enabled');
  }

  console.log(`LAYOUT=${JSON.stringify(measurement)}`);
}

// Drives the real Add Charge form: reveal the itemized group, fill repeatable
// component rows, read the derived preview, and submit through Eyre.
async function testItemizedChargeEntry(page, vehicle) {
  await page.locator('[data-open-screen="add-charge"]').first().click();
  const form = page.locator('#charge-form');
  await form.waitFor({state: 'visible'});
  await form.locator('[name="vehicle"]').selectOption(vehicle);
  const itemized = form.locator('#charge-itemized');
  const receipt = form.locator('#charge-receipt-total');
  if (await itemized.isVisible() || await receipt.isVisible()) {
    throw new Error('a cost group is visible while the cost state is unknown');
  }

  await form.locator('[name="costState"]').selectOption('receipt-total-only');
  if (await itemized.isVisible() || !await receipt.isVisible()) {
    throw new Error('receipt-total-only did not reveal only the receipt group');
  }

  await form.locator('[name="costState"]').selectOption('itemized');
  if (!await itemized.isVisible() || await receipt.isVisible()) {
    throw new Error('itemized did not reveal only the component group');
  }

  const lines = [
    ['energy', '45.678', 'kwh', '0.250', '11.420'],
    ['time', '30', 'minute', '0.100', '3.000'],
    ['session', '1', 'session', '1.500', '1.500'],
    ['idle', '5', 'minute', '0.500', '2.500'],
    ['tax', '1', 'session', '1.000', '1.000'],
    ['discount', '1', 'session', '2.000', '2.000']
  ];
  const rows = form.locator('[data-cost-component-row]');
  for (let index = 0; index < lines.length; index += 1) {
    if (await rows.count() <= index) {
      await form.locator('[data-add-cost-component]').click();
    }
    const [kind, quantity, unit, rate, amount] = lines[index];
    const row = rows.nth(index);
    await row.locator('[name="componentKind"]').selectOption(kind);
    await row.locator('[name="componentQuantity"]').fill(quantity);
    await row.locator('[name="componentUnit"]').selectOption(unit);
    await row.locator('[name="componentRate"]').fill(rate);
    await row.locator('[name="componentAmount"]').fill(amount);
  }
  if (await rows.count() !== lines.length) {
    throw new Error(`component rows are ${await rows.count()}, want ${lines.length}`);
  }
  const preview = await form.locator('#charge-itemized-total')
    .evaluate((node) => node.value);

  const now = new Date();
  const stamp = (offset) => {
    const at = new Date(now.getTime() + offset);
    at.setSeconds(0, 0);
    return new Date(at.getTime() - at.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 16);
  };
  await form.locator('[name="start"]').fill(stamp(0));
  await form.locator('[name="end"]').fill(stamp(45 * 60 * 1000));
  await form.locator('button[type="submit"]').click();
  const verdict = form.locator('#charge-verdict');
  await page.waitForFunction(
    () => {
      const value = document.querySelector('#charge-verdict')?.value || '';
      return value.length > 0 && value !== 'Saving…';
    },
    null,
    {timeout: 30000}
  );
  console.log(`CHARGE_PREVIEW=${preview}`);
  console.log(`CHARGE_VERDICT=${await verdict.evaluate((node) => node.value)}`);
}

// Opens Settings, then the import screen, and drives the real file input,
// the validate step, and the submit control. Counts every POST the page makes
// to /apps/rover/import, so a client-side refusal can prove it sent nothing.
async function testImportUpload(page, documentPath, batchSize) {
  let posts = 0;
  page.on('request', (request) => {
    if (
      request.method() === 'POST' &&
      request.url().endsWith('/apps/rover/import')
    ) {
      posts += 1;
    }
  });
  await page.locator('[data-open-screen="settings-screen"]').first().click();
  await page.locator('[data-open-screen="import-screen"]').first().click();
  const form = page.locator('#import-form');
  await form.waitFor({state: 'visible'});
  await page.locator('#import-file').setInputFiles(documentPath);
  await page.locator('#import-batch-size').fill(String(batchSize));
  await page.locator('#import-validate').click();
  await page.waitForFunction(() => {
    const plan = document.querySelector('#import-plan')?.value || '';
    const outcome =
      document.querySelector('#import-outcome')?.dataset.importOutcome || '';
    return (plan !== '' && plan !== '—') || outcome !== '';
  });
  const validated = await page.locator('#import-plan').evaluate(
    (node) => node.value
  );
  await form.locator('button[type="submit"]').click();
  await page.waitForFunction(
    (terminal) => {
      const outcome =
        document.querySelector('#import-outcome')?.dataset.importOutcome || '';
      return terminal.includes(outcome);
    },
    IMPORT_OUTCOMES,
    {timeout: 900_000}
  );
  const result = await page.evaluate(() => {
    const outcome = document.querySelector('#import-outcome');
    return {
      plan: document.querySelector('#import-plan').value,
      progress: document.querySelector('#import-progress').value,
      outcome: outcome.dataset.importOutcome,
      message: outcome.value,
      reports: [...document.querySelectorAll('#import-batch-list li')].map(
        (item) => item.textContent
      ),
      aggregate: document.querySelector('#import-aggregate').value
    };
  });
  console.log(`IMPORT_VALIDATED=${JSON.stringify(validated)}`);
  console.log(`IMPORT_RESULT=${JSON.stringify(result)}`);
  console.log(`IMPORT_POSTS=${posts}`);
}

// Runs the shipped client-side validation and batch split over a document's
// text without sending anything, so a fixture can compare the browser batches
// against the ones tools/rover-import/upload.py builds for the same file.
async function testImportPrepare(page, documentPath, batchSize) {
  let posts = 0;
  page.on('request', (request) => {
    if (
      request.method() === 'POST' &&
      request.url().endsWith('/apps/rover/import')
    ) {
      posts += 1;
    }
  });
  const source = fs.readFileSync(documentPath, 'utf8');
  const prepared = await page.evaluate(
    ({text, size}) => {
      const result = importPrepare(text, size);
      return {
        ok: result.ok,
        verdict: result.verdict,
        fills: result.fills ?? null,
        batches: result.batches ?? null
      };
    },
    {text: source, size: String(batchSize)}
  );
  console.log(`IMPORT_PREPARED=${JSON.stringify(prepared)}`);
  console.log(`IMPORT_POSTS=${posts}`);
}

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  if (mode === 'bootstrap-status-normal' || mode === 'bootstrap-status-performed') {
    await context.addInitScript(() => {
      const nativeFetch = window.fetch.bind(window);
      window.__roverStatuses = [];
      window.__roverBootstrapMarkers = [];
      window.fetch = async (...args) => {
        const response = await nativeFetch(...args);
        const requestUrl = String(args[0]);
        if (!requestUrl.endsWith('/apps/rover/view')) return response;
        window.__roverBootstrapMarkers.push(
          response.headers.get('x-rover-bootstrap')
        );
        return {
          ok: response.ok,
          headers: response.headers,
          text: async () => {
            await new Promise((resolve) => setTimeout(resolve, 250));
            return response.text();
          }
        };
      };
      window.addEventListener('DOMContentLoaded', () => {
        const status = document.querySelector('#status');
        if (!status) return;
        const record = () => window.__roverStatuses.push(status.textContent);
        record();
        new MutationObserver(record).observe(status, {
          childList: true,
          characterData: true,
          subtree: true
        });
      });
    });
  }
  const page = await context.newPage();

  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'domcontentloaded'});
    await page.waitForSelector('#app-default-data', {state: 'attached'});

    if (mode === 'bootstrap-status-normal' || mode === 'bootstrap-status-performed') {
      const observation = await page.evaluate(() => ({
        statuses: window.__roverStatuses,
        markers: window.__roverBootstrapMarkers,
        gasoline: [...document.querySelectorAll('option')].some(
          (option) => option.textContent === 'Gasoline'
        ),
        diesel: [...document.querySelectorAll('option')].some(
          (option) => option.textContent === 'Diesel'
        ),
        emptyState: document.body.textContent.includes(
          'Add a fill to begin tracking'
        )
      }));
      const performed = mode === 'bootstrap-status-performed';
      if (!observation.statuses.includes('Loading…')) {
        throw new Error(`first paint did not say Loading…: ${JSON.stringify(observation)}`);
      }
      if (performed) {
        if (
          !observation.statuses.includes('Setting up the database…') ||
          observation.markers[0] !== 'performed'
        ) {
          throw new Error(`bootstrap response was not echoed: ${JSON.stringify(observation)}`);
        }
      } else if (
        observation.statuses.includes('Setting up the database…') ||
        observation.markers[0] !== null
      ) {
        throw new Error(`normal response claimed bootstrap: ${JSON.stringify(observation)}`);
      }
      console.log(`BOOTSTRAP_STATUS=${JSON.stringify(observation)}`);
    } else if (mode === 'header-current') {
      await page.waitForFunction(
        ({ship, vehicle}) => {
          const text =
            (document.querySelector('#rover-designation')?.textContent || '').toUpperCase();
          return text.includes(ship.toUpperCase()) && text.includes(vehicle.toUpperCase());
        },
        {ship, vehicle: firstVehicle},
        {timeout: 3_000}
      );
      const actual = await headerText(page);
      if (actual.includes('UNIT 01') || actual.includes('UA 571-C')) {
        throw new Error(`placeholder segment remains: ${actual}`);
      }
      console.log(`HEADER=${actual}`);
    } else if (mode === 'header-scenarios') {
      const initial = await headerText(page);
      if (
        !initial.includes(ship.toUpperCase()) ||
        !initial.includes('NO DEFAULT VEHICLE')
      ) {
        throw new Error(`no-default header is not explicit: ${initial}`);
      }
      console.log(`HEADER_NONE=${initial}`);

      await setDefaultVehicle(page, firstVehicle);
      await page.evaluate(() => loadView());
      await page.waitForFunction(
        (expected) =>
          (document.querySelector('#header-vehicle')?.textContent || '') === expected,
        firstVehicle
      );
      const first = await headerText(page);
      if (
        first.includes('UNIT 01') ||
        first.includes('UA 571-C') ||
        !first.includes(ship.toUpperCase()) ||
        !first.includes(firstVehicle.toUpperCase())
      ) {
        throw new Error(`first default header is wrong: ${first}`);
      }
      console.log(`HEADER_FIRST=${first}`);

      await setDefaultVehicle(page, secondVehicle);
      await page.evaluate(() => loadView());
      await page.waitForFunction(
        (expected) =>
          (document.querySelector('#header-vehicle')?.textContent || '') === expected,
        secondVehicle
      );
      const second = await headerText(page);
      if (
        !second.includes(secondVehicle.toUpperCase()) ||
        second.includes(firstVehicle.toUpperCase())
      ) {
        throw new Error(`changed default header is stale: ${second}`);
      }
      console.log(`HEADER_SECOND=${second}`);

      //  The import screen carries a back control to Settings, so name the hub
      //  button rather than every control that opens the screen.
      await page.locator('[data-open-screen="settings-screen"]').first().click();
      const slider = page.locator(
        '[data-settings-section="theme"] input[type="range"][data-glow-intensity]'
      );
      if (await slider.count() !== 1) {
        throw new Error('settings glow intensity slider is missing');
      }
      const bounds = await slider.evaluate((control) => ({
        min: control.min,
        max: control.max,
        step: control.step
      }));
      if (bounds.min !== '0' || bounds.max !== '100' || bounds.step !== '1') {
        throw new Error(`glow slider bounds are ${JSON.stringify(bounds)}`);
      }
      const initialGlow = await page.evaluate(() => {
        const root = getComputedStyle(document.documentElement);
        return {
          slider: document.querySelector('[data-glow-intensity]')?.value,
          alpha: root.getPropertyValue('--rv-glow-alpha').trim(),
          blur: root.getPropertyValue('--rv-glow-blur').trim()
        };
      });
      if (
        initialGlow.slider !== '32' ||
        Number(initialGlow.alpha) !== 0.32 ||
        initialGlow.blur !== '0.320rem'
      ) {
        throw new Error(
          `legacy 0.32 glow is not mapped to its honest index: ${JSON.stringify(initialGlow)}`
        );
      }

      const toggle = page.locator('#glow-toggle');
      if (await toggle.getAttribute('aria-pressed') === 'true') {
        await toggle.click();
      }
      if (!await slider.isDisabled()) {
        throw new Error('glow slider remains enabled while glow is off');
      }
      await toggle.click();
      await slider.fill('100');
      await slider.dispatchEvent('input');
      const maximum = await page.evaluate(() => {
        const root = getComputedStyle(document.documentElement);
        return {
          stored: localStorage.getItem('rover-glow-intensity'),
          intensity: root.getPropertyValue('--rv-glow-intensity').trim(),
          shadow: getComputedStyle(document.body).textShadow
        };
      });
      const alphaMatch = maximum.shadow.match(
        /rgba?\([^)]*[, /]([0-9.]+)\)$/
      );
      const alpha = alphaMatch ? Number(alphaMatch[1]) : 1;
      if (
        maximum.stored !== '100' ||
        !maximum.intensity ||
        !(alpha > 0.32)
      ) {
        throw new Error(
          `maximum glow did not persist or exceed alpha 0.32: ${JSON.stringify(maximum)}`
        );
      }
      //  The control states a percentage, so the rendered alpha must equal it.
      //  A slider that reads 45% while rendering 0.72 is a lying boundary.
      if (alpha !== 1) {
        throw new Error(
          `slider at 100 did not render alpha 1: ${JSON.stringify(maximum)}`
        );
      }
      for (const probe of ['45', '10', '80']) {
        await slider.fill(probe);
        await slider.dispatchEvent('input');
        const honest = await page.evaluate(() => {
          const root = getComputedStyle(document.documentElement);
          return {
            alpha: root.getPropertyValue('--rv-glow-alpha').trim(),
            blur: root.getPropertyValue('--rv-glow-blur').trim(),
            output: document
              .querySelector('[data-glow-intensity-output]')
              ?.textContent
          };
        });
        const want = (Number(probe) / 100).toFixed(3);
        if (
          honest.alpha !== want ||
          honest.blur !== `${want}rem` ||
          honest.output !== `${probe}%`
        ) {
          throw new Error(
            `slider ${probe}% does not render alpha ${want}: ${JSON.stringify(honest)}`
          );
        }
      }
      await slider.fill('100');
      await slider.dispatchEvent('input');

      await page.reload({waitUntil: 'domcontentloaded'});
      await page.waitForSelector(
        '[data-settings-section="theme"] input[data-glow-intensity]',
        {state: 'attached'}
      );
      const reloaded = page.locator('input[data-glow-intensity]');
      if (
        await reloaded.inputValue() !== '100' ||
        await reloaded.isDisabled()
      ) {
        throw new Error('maximum glow did not survive a reload while enabled');
      }
      console.log(
        `GLOW=${maximum.intensity}|${maximum.shadow}|stored=${maximum.stored}`
      );
      await testVehicleSettingsLayout(page, secondVehicle);
    } else if (mode === 'charge-cost') {
      await testItemizedChargeEntry(page, firstVehicle);
    } else if (mode === 'import-upload') {
      await testImportUpload(page, importPath, importBatchSize);
    } else if (mode === 'import-prepare') {
      await testImportPrepare(page, importPath, importBatchSize);
    } else if (mode === 'layout-current') {
      await testVehicleSettingsLayout(page, firstVehicle);
    } else if (mode === 'capture-current') {
      console.log(
        `HEADER_HTML=${await page.locator('.terminal-header').evaluate(
          (header) => header.outerHTML
        )}`
      );
      await page.getByRole('button', {name: 'Vehicles', exact: true}).click();
      await page.locator(
        `[data-open-vehicle-settings][data-vehicle="${firstVehicle}"]`
      ).click();
      const panel = page.locator(
        `[data-vehicle-settings-panel][data-vehicle="${firstVehicle}"]`
      );
      await panel.waitFor({state: 'visible'});
      console.log(
        `SETTINGS_HTML=${await panel.evaluate((article) => article.outerHTML)}`
      );
    } else {
      throw new Error(`unknown mode: ${mode}`);
    }
  } catch (error) {
    fail(`${error.message}; header=${await headerText(page).catch(() => '<missing>')}`);
  } finally {
    await browser.close();
  }
})().catch((error) => fail(error.stack || error.message));
