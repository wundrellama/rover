#!/usr/bin/env python3
"""Return HTTP 504 to the legacy upload on the disposable test pier."""
import http.server
import pathlib
import subprocess
import sys
import tempfile
import threading
import urllib.parse

url, jar, pier, vehicle, photo, endpoint, work = sys.argv[1:]


class Refusal(http.server.BaseHTTPRequestHandler):
    def do_PUT(self):
        self.rfile.read(int(self.headers.get("Content-Length", "0")))
        self.send_response(504)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, *args):
        pass


def set_endpoint(value):
    assert "'" not in value and "\\" not in value
    script = f"""=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %storage] %storage-action !>([%set-endpoint '{value}']))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".hoon", dir=work) as source:
        source.write(script)
        source.flush()
        result = subprocess.run(
            ["click", "-k", "-i", source.name, pier], capture_output=True, text=True
        )
        assert result.returncode == 0 and "%avow 0 %noun" in result.stdout


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Refusal)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    set_endpoint(f"http://127.0.0.1:{server.server_port}")
    query = urllib.parse.urlencode({
        "owner": "vehicle", "vehicle": vehicle, "backend": "s3",
        "file": pathlib.Path(photo).name, "type": "image/jpeg",
    })
    response = subprocess.run([
        "curl", "-sS", "--max-time", "45", "-b", jar, "-X", "POST",
        "--data-binary", "@" + photo, "-w", "\n%{http_code}",
        url + "/apps/rover/add-attachment?" + query,
    ], capture_output=True, text=True, check=True).stdout
    assert "504" in response.rsplit("\n", 1)[0], response
    assert response.endswith("\n502"), response
    print("The real upload received HTTP 504 and named 504 in its refusal.")
finally:
    set_endpoint(endpoint)
    server.shutdown()
    server.server_close()
