#!/usr/bin/env python3
"""Check M9 follow-on results through Eyre on a prepared disposable pier."""

import base64
import datetime
import hashlib
import html
import io
import json
import os
import pathlib
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.parse


class Fixture:
    def __init__(self, number, url, jar, pier, stamp):
        self.number = number
        self.url = url
        self.jar = jar
        self.pier = pier
        self.stamp = stamp
        self.vehicle = f"Followon {number} {stamp}"
        self.work = pathlib.Path(__file__).resolve().parent.parent / ".scratch"

    def request(self, route, payload=None, query=None, method="POST"):
        target = self.url + "/apps/rover/" + route
        if query is not None:
            target += "?" + urllib.parse.urlencode(query)
        command = ["curl", "-sS", "--max-time", "120", "-b", self.jar,
                   "-X", method, "-w", "\n%{http_code}", target]
        if payload is not None:
            command += ["-H", "content-type: application/json",
                        "--data-raw", json.dumps(payload)]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        body, status = result.stdout.rsplit("\n", 1)
        return int(status), body

    def create_vehicle(self):
        status, body = self.request("add-vehicle", {
            "label": self.vehicle, "energy": "Gasoline", "additionalEnergy": [],
        })
        assert (status, body) == (201, f"Added vehicle - {self.vehicle}"), (status, body)

    def set_endpoint(self, endpoint):
        assert "'" not in endpoint and "\\" not in endpoint
        script = f"""=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %storage] %storage-action !>([%set-endpoint '{endpoint}']))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))
"""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".hoon", dir=self.work) as source:
            source.write(script)
            source.flush()
            result = subprocess.run(["click", "-k", "-i", source.name, self.pier],
                                    capture_output=True, text=True, check=True)
            assert "%avow 0 %noun" in result.stdout, result.stdout

    def metadata(self):
        content = self.vehicle.encode()
        return {"owner": "vehicle", "vehicle": self.vehicle, "backend": "s3",
                "file": f"followon-{self.number}.jpg", "type": "image/jpeg",
                "hash": hashlib.sha256(content).hexdigest(), "bytes": str(len(content))}

    def view(self):
        status, body = self.request("view", {"page": "0", "vehicle": self.vehicle})
        assert status == 200, (status, body)
        return body

    def set_default(self, vehicle):
        reply = self.request("set-default-vehicle", {"vehicle": vehicle})
        assert reply == (201, "Saved default vehicle"), reply

    def assert_backend(self, expected):
        document = self.view()
        original = re.search(r'id="app-default-data"[^>]*data-vehicle="([^"]*)"', document)
        self.set_default(self.vehicle)
        try:
            document = self.view()
            for form in ("fill", "event", "import"):
                field = re.search(r'<fieldset[^>]*data-photo-field="' + form +
                                  r'".*?</fieldset>', document, re.S)
                assert field, f"The {form} photo field is absent"
                selected = re.findall(r'<option\b(?=[^>]*\bselected)([^>]*)>', field[0])
                values = [re.search(r'value="([^"]*)"', option)[1] for option in selected]
                assert values == [expected], (form, "selected backend", values, "want", expected)
        finally:
            if original:
                self.set_default(html.unescape(original[1]))

    def store_s3(self, expected=201):
        # A real PNG goes to the shared bucket before Rover records its reference.
        content = base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWioAAAAASUVORK5CYII="
        ) + self.vehicle.encode()
        query = self.metadata()
        query.update({"file": self.vehicle + ".png", "type": "image/png",
                      "hash": hashlib.sha256(content).hexdigest(), "bytes": str(len(content))})
        status, body = self.request("attachment-url", query=query)
        assert status == 200, (status, body)
        urls = json.loads(body)
        with tempfile.NamedTemporaryFile(dir=self.work) as photo:
            photo.write(content)
            photo.flush()
            uploaded = subprocess.run([
                "curl", "-sS", "--max-time", "30", "-X", "PUT",
                "-H", "content-type: image/png", "--data-binary", "@" + photo.name,
                "-o", "/dev/null", "-w", "%{http_code}", urls["putUrl"],
            ], capture_output=True, text=True, check=True)
            assert uploaded.stdout == "200", uploaded.stdout
        stored = subprocess.run(["curl", "-fsS", "--max-time", "30", urls["getUrl"]],
                                capture_output=True, check=True).stdout
        assert stored == content, "The bucket returned different photograph bytes"
        status, body = self.request("record-attachment", query=query)
        assert status == expected, (status, body)

    def preferred_s3(self):
        self.create_vehicle()
        self.store_s3()
        self.assert_backend("s3")
        print("A later fill form and event form select S3 after a stored S3 photograph.")

    def fresh_clay(self):
        self.create_vehicle()
        self.assert_backend("clay")
        print("A vehicle with no photograph selects Clay.")

    def unavailable_clay(self):
        self.create_vehicle()
        self.store_s3()
        try:
            self.set_endpoint("")
            status, body = self.request("backends.json", method="GET")
            assert status == 200
            assert not next(b for b in json.loads(body)["backends"] if b["name"] == "s3")["available"]
            self.assert_backend("clay")
            assert '<option value="s3"' not in self.view()
        finally:
            self.set_endpoint("http://localhost:9200")
        self.assert_backend("s3")
        print("Unavailable S3 falls back to Clay. Restored S3 keeps the saved preference.")

    def last_success(self):
        self.create_vehicle()
        self.store_s3()
        query = self.metadata()
        query.update(backend="clay", file=self.vehicle + "-clay.png", type="image/png")
        content = base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWioAAAAASUVORK5CYII="
        )
        target = self.url + "/apps/rover/add-attachment?" + urllib.parse.urlencode(query)
        reply = subprocess.run(["curl", "-sS", "--max-time", "120", "-b", self.jar,
                                "-H", "content-type: image/png", "--data-binary", "@-",
                                "-w", "\n%{http_code}", target], input=content, capture_output=True, check=True)
        assert reply.stdout.endswith(b"\n201"), reply.stdout
        self.assert_backend("clay")
        status, body = self.request("attachment-url", query=self.metadata())
        assert status == 200, (status, body)
        self.assert_backend("clay")
        bad = self.metadata()
        bad["hash"] = "invalid"
        assert self.request("record-attachment", query=bad)[0] == 400
        self.assert_backend("clay")
        self.store_s3(expected=200)
        self.assert_backend("s3")
        print("Clay replaces S3. Presigns and refusals preserve Clay. A repeated S3 store selects S3.")

    def browser_preferences(self):
        self.create_vehicle()
        self.store_s3()
        fresh = self.vehicle + " Fresh"
        saved = self.vehicle
        self.vehicle = fresh
        self.create_vehicle()
        self.vehicle = saved
        env = os.environ.copy()
        env.setdefault("ROVER_PLAYWRIGHT_MODULE", str(pathlib.Path.home() / "git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright"))
        env.setdefault("ROVER_CHROMIUM", str(pathlib.Path.home() / ".cache/ms-playwright/chromium-1217/chrome-linux64/chrome"))
        subprocess.run(["node", "bin/followon-browser-fixture.cjs", self.url, self.jar,
                        saved, fresh], env=env, check=True)
        # The import keeps its report on screen. Later forms must use its result
        # without a reload, including when the vehicle had no saved preference.
        photo = base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWioAAAAASUVORK5CYII="
        )
        name = fresh + ".png"
        document = {
            "rover-import": 1,
            "source": {"app": "rover", "attachments": {"photoCount": 1, "files": [{
                "name": name, "path": "attachments/" + name,
                "hash": hashlib.sha256(photo).hexdigest(), "bytes": str(len(photo)), "mediaType": "image/png",
            }]}},
            "definitions": {"energy": [], "additives": [], "driving-modes": [], "tags": [], "payment-methods": []},
            "places": [], "vehicles": [{"label": fresh, "distanceUnit": "mi", "volumeUnit": "gal",
                "defaultEnergy": "Gasoline", "fills": [], "attachments": [name]}],
        }
        cookie = next(line.split("\t")[5:7] for line in pathlib.Path(self.jar).read_text().splitlines()
                      if "\turbauth-" in line)
        with tempfile.NamedTemporaryFile(suffix=".tar", dir=self.work) as target:
            with tarfile.open(target.name, "w", format=tarfile.USTAR_FORMAT) as archive:
                for member, data in (("rover-import.json", json.dumps(document).encode()), ("attachments/" + name, photo)):
                    info = tarfile.TarInfo(member)
                    info.size = len(data)
                    archive.addfile(info, io.BytesIO(data))
            result = subprocess.run(["node", "bin/import-backend-browser-fixture.cjs", self.url,
                                     *cookie, target.name, "s3", "photos", fresh], env=env)
            assert result.returncode == 0, "The browser import preference fixture failed"

    def preference_persistence(self):
        for number, backend in ((123, "s3"), (124, "clay"), (125, "s3"), (126, "s3")):
            self.vehicle = f"Followon {number} {self.stamp}"
            self.assert_backend(backend)
        print("Saved backend choices and the absent-row Clay default survive the restart.")

    def reminder_sentence(self, mode):
        self.create_vehicle()
        today = datetime.datetime.now(datetime.timezone.utc).date()
        due = today + datetime.timedelta(days=30)
        # Two readings: 45,000 mi then 45,100 mi, exactly 100 days apart.
        # The 5,000 mi interval has a due point of 47,500 mi: 2,400 mi remain.
        # 2,400 * 100 > 30 * 100, so the date leads when both readings exist.
        # With just 45,100 mi, ruling 32a requires distance to lead.
        observations = [(today - datetime.timedelta(days=1), "45100")]
        # Zero repeats 45,100 mi. The distance case advances 10,000 mi in 100 days:
        # 2,400 * 100 < 29 * 10,000, so distance leads even late in the current day.
        if mode != "one":
            first = "45100" if mode == "zero" else ("35100" if mode == "distance" else "45000")
            observations.insert(0, (today - datetime.timedelta(days=101), first))
        if mode == "gap":
            # Only the final reading belongs to the current ownership interval.
            # Including the old reading would put time first, so this tests the bound.
            for days, route, kind in ((110, "add-acquisition-event", ""),
                                      (50, "add-disposal-event", "Sold"),
                                      (2, "add-acquisition-event", "")):
                status, body = self.request(route, {
                    "vehicle": self.vehicle,
                    "observed": (today - datetime.timedelta(days=days)).isoformat() + "T09:00",
                    "zone": "UTC", "total": "", "currency": "usd", "mileage": "",
                    "mileageUnit": "mi", "station": "none", "newStationLabel": "",
                    "newPlaceLabel": "", "newStationKind": "private", "tags": [],
                    "newTag": "", "paymentMethod": "", "subtypes": [],
                    "disposalKind": kind, "notes": "Forecast ownership interval",
                })
                assert status == 201, (status, body)
        for day, reading in observations:
            status, body = self.request("add-odometer", {
                "vehicle": self.vehicle, "reading": reading, "unit": "mi",
                "observed": day.isoformat() + "T12:00", "zone": "UTC",
            })
            assert status == 201, (status, body)
        status, body = self.request("add-reminder", {
            "vehicle": self.vehicle, "subtype": "Engine Oil", "timeInterval": "6",
            "timeUnit": "month", "timeDue": due.isoformat(),
            # The gap fixture starts its countdown in the current interval.
            "distanceInterval": "1000" if mode == "gap" else "5000",
            "distanceDue": "47500", "distanceUnit": "mi",
        })
        assert status == 201, (status, body)
        document = self.view()
        original = re.search(r'id="app-default-data"[^>]*data-vehicle="([^"]*)"', document)
        self.set_default(self.vehicle)
        try:
            document = self.view()
            card = re.search(r'<article class="reminder"[^>]*data-reminder="Engine Oil".*?</article>', document, re.S)
            assert card, "The Engine Oil reminder is absent"
            expected = (f"Due {due} — or in 2,400 mi, whichever comes first." if mode == "time" else
                        f"Due in 2,400 mi — or {due}, whichever comes first.")
            actual = html.unescape(re.search(r'data-reminder-due="([^"]*)"', card[0])[1])
            assert actual == expected, (actual, expected)
            assert 'data-reminder-state="not-due"' in card[0], card[0]
            assert 'data-reminder-detail=""' in card[0], card[0]
            assert "Every " not in card[0], card[0]
            print(expected)
        finally:
            if original:
                self.set_default(html.unescape(original[1]))

    def https_endpoint(self):
        self.create_vehicle()
        # No request goes to this host. Rover only signs these URLs.
        endpoint = "storage.example.test"
        try:
            self.set_endpoint(endpoint)
            status, body = self.request("attachment-url", query=self.metadata())
            assert status == 200, (status, body)
            data = json.loads(body)
            for key in ("putUrl", "getUrl"):
                actual = urllib.parse.urlsplit(data[key])
                assert (actual.scheme, actual.netloc) == ("https", endpoint), (
                    key, actual.scheme, actual.netloc)
            print("Both putUrl and getUrl use https://storage.example.test.")
        finally:
            self.set_endpoint("http://localhost:9200")


if __name__ == "__main__":
    fixture = Fixture(int(sys.argv[1]), *sys.argv[2:])
    {122: fixture.https_endpoint, 123: fixture.preferred_s3, 124: fixture.fresh_clay,
     125: fixture.unavailable_clay, 126: fixture.last_success,
     127: fixture.browser_preferences,
     128: lambda: fixture.reminder_sentence("time"),
     129: lambda: fixture.reminder_sentence("one"),
     130: fixture.preference_persistence,
     131: lambda: fixture.reminder_sentence("zero"),
     132: lambda: fixture.reminder_sentence("gap"),
     133: lambda: fixture.reminder_sentence("distance")}[fixture.number]()
