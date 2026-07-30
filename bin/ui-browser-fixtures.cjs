#!/usr/bin/env node
'use strict';

const {chromium} = require(process.env.ROVER_PLAYWRIGHT_MODULE);

const [mode, url, authName, auth, ship, firstVehicle, secondVehicle] =
  process.argv.slice(2);
const executablePath = process.env.ROVER_CHROMIUM;

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

(async () => {
  const browser = await chromium.launch({headless: true, executablePath});
  const context = await browser.newContext({viewport: {width: 390, height: 844}});
  await context.addCookies([{name: authName, value: auth, url}]);
  const page = await context.newPage();

  try {
    await page.goto(`${url}/apps/rover`, {waitUntil: 'domcontentloaded'});
    await page.waitForSelector('#app-default-data', {state: 'attached'});

    if (mode === 'header-current') {
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

      await page.locator('[data-open-screen="settings-screen"]').click();
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
