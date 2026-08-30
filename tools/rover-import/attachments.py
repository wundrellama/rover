#!/usr/bin/env python3
"""Load an extracted photo tree into Rover through the product endpoint.

The converter writes `attachments.json` and a jpg tree beside the import
document. Nothing consumed them until now. This tool is that consumer.

Every photo goes in through `/apps/rover/add-attachment`, the same endpoint a
browser calls. An import has no privileged path: if this tool could write
something the product endpoint cannot, that would be a defect.

Each photo is read back afterwards and its digest compared with the one the
converter recorded, so a byte that changed anywhere between the camera and the
storage backend fails the load rather than passing quietly.

The corpus is the owner's own data. This tool reports COUNTS. It never prints a
file name, a vehicle label, a date, or a digest from the corpus.
"""

import argparse
import hashlib
import json
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request


OWNERS = {"fill": "fill", "event": "event", "vehicle": "vehicle"}


def load_manifest(path):
    with pathlib.Path(path).open(encoding="utf-8") as source:
        document = json.load(source)
    if isinstance(document, dict):
        entries = document.get("attachments", document)
    else:
        entries = document
    if not isinstance(entries, list):
        raise ValueError("attachments.json does not hold a list of entries")
    return entries


def attach_url(base, entry, backend):
    query = {
        "owner": OWNERS[entry["record-kind"]],
        "vehicle": entry["vehicle"],
        "file": pathlib.PurePosixPath(entry["file"]).name,
        "type": "image/jpeg",
        "backend": backend,
    }
    # A vehicle photo hangs off the vehicle itself and has no moment.
    if entry["record-kind"] != "vehicle":
        query["observed"] = entry["observed-start"]
    return f"{base}/apps/rover/add-attachment?" + urllib.parse.urlencode(query)


def request(url, cookie, data=None, content_type=None):
    headers = {"cookie": cookie}
    if content_type:
        headers["content-type"] = content_type
    call = urllib.request.Request(url, data=data, headers=headers)
    if data is not None:
        call.get_method = lambda: "POST"
    try:
        with urllib.request.urlopen(call) as answer:
            return answer.status, answer.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", help="attachments.json from the converter")
    parser.add_argument("--url", default="http://localhost:8080")
    parser.add_argument("--cookie", required=True, help="urbauth cookie header")
    parser.add_argument("--backend", default="clay", choices=("clay", "s3"))
    parser.add_argument(
        "--photos",
        help="root of the extracted jpg tree (default: beside the manifest)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="read every photo back and compare its digest with the manifest",
    )
    args = parser.parse_args()

    manifest = pathlib.Path(args.manifest)
    entries = load_manifest(manifest)
    root = pathlib.Path(args.photos) if args.photos else manifest.parent

    stored = 0
    already = 0
    refused = 0
    verified = 0
    mismatched = 0
    by_kind = {"fill": 0, "event": 0, "vehicle": 0}
    names = []

    for entry in entries:
        source = root / entry["file"]
        payload = source.read_bytes()
        digest = hashlib.sha256(payload).hexdigest()
        if digest != entry["sha256"]:
            print("the extracted file no longer matches the manifest", file=sys.stderr)
            return 2
        status, body = request(
            attach_url(args.url, entry, args.backend),
            args.cookie,
            payload,
            "image/jpeg",
        )
        # A load that is run again answers 200 "Already attached <name>". That
        # is not a refusal: it is the store saying it already holds this photo
        # under this name, which is what makes a second load add nothing.
        if status not in (201, 200):
            refused += 1
            # The reason is Rover's own words and holds no corpus value.
            print(f"refused with HTTP {status}: {body.decode(errors='replace')}",
                  file=sys.stderr)
            continue
        if status == 201:
            stored += 1
        else:
            already += 1
        by_kind[entry["record-kind"]] += 1
        # Rover answers with the name it kept after resolving any collision.
        # That is the name to read back.
        answer = body.decode().strip()
        for prefix in ("Attached ", "Already attached "):
            answer = answer.removeprefix(prefix)
        names.append((answer.strip(), digest))

    if args.verify:
        for name, digest in names:
            status, body = request(
                f"{args.url}/apps/rover/attachment/{urllib.parse.quote(name, safe='')}",
                args.cookie,
            )
            if status != 200:
                mismatched += 1
                continue
            if hashlib.sha256(body).hexdigest() != digest:
                mismatched += 1
                continue
            verified += 1

    print(f"ATTACHMENTS_IN_MANIFEST={len(entries)}")
    print(f"ATTACHMENTS_STORED={stored}")
    print(f"ATTACHMENTS_ALREADY={already}")
    print(f"ATTACHMENTS_REFUSED={refused}")
    print(f"ATTACHMENTS_FILL={by_kind['fill']}")
    print(f"ATTACHMENTS_EVENT={by_kind['event']}")
    print(f"ATTACHMENTS_VEHICLE={by_kind['vehicle']}")
    print(f"ATTACHMENTS_DISTINCT_DIGESTS={len({d for _, d in names})}")
    if args.verify:
        print(f"ATTACHMENTS_VERIFIED={verified}")
        print(f"ATTACHMENTS_MISMATCHED={mismatched}")
    return 0 if refused == 0 and mismatched == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
