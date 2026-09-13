#!/usr/bin/env python3
"""Check M9 follow-on results through Eyre on a prepared disposable pier."""

import hashlib
import json
import pathlib
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
    {122: fixture.https_endpoint}[fixture.number]()
