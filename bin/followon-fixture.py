#!/usr/bin/env python3
"""Check M9 follow-on results through Eyre on a prepared disposable pier."""

import base64
import hashlib
import html
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import urllib.parse


class Fixture:
    def __init__(self, number, url, jar, pier, stamp):
        self.number = number
        self.url = url
        self.jar = jar
        self.pier = pier
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
     127: fixture.browser_preferences}[fixture.number]()
