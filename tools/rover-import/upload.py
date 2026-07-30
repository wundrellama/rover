#!/usr/bin/env python3
"""Upload a Rover import document in bounded, resumable HTTP batches."""

import argparse
import copy
import json
import pathlib
import re
import sys
import urllib.request


REPORT_PATTERNS = {
    "fills": re.compile(
        r"Fills: imported (\d+), already-imported (\d+), "
        r"conflicts (\d+), failures (\d+)"
    ),
    "definitions": re.compile(r"Definitions: created (\d+), reused (\d+)"),
    "places": re.compile(r"Places: created (\d+), reused (\d+)"),
    "vehicles": re.compile(r"Vehicles: created (\d+), reused (\d+)"),
    "station_none": re.compile(r"Station-none fills: (\d+)"),
    "totals": re.compile(
        r"Total cross-check: exact (\d+), off-by-one (\d+), beyond (\d+)"
    ),
    "unit_mismatches": re.compile(r"Unit mismatches: (\d+)"),
}


def reject_float(value):
    raise ValueError(f"floating-point JSON token is forbidden: {value}")


def load_document(path):
    with pathlib.Path(path).open(encoding="utf-8") as source:
        document = json.load(source, parse_float=reject_float)
    if not isinstance(document, dict) or document.get("rover-import") != 1:
        raise ValueError("document must have rover-import version 1")
    vehicles = document.get("vehicles")
    if not isinstance(vehicles, list):
        raise ValueError("document vehicles must be a list")
    for index, vehicle in enumerate(vehicles):
        if not isinstance(vehicle, dict) or not isinstance(vehicle.get("fills"), list):
            raise ValueError(f"vehicle {index} must have a fills list")
    return document


def batch_documents(document, batch_size):
    if batch_size <= 0:
        raise ValueError("batch size must be positive")

    flattened = [
        (vehicle_index, fill)
        for vehicle_index, vehicle in enumerate(document["vehicles"])
        for fill in vehicle["fills"]
    ]
    starts = range(0, len(flattened), batch_size) if flattened else (0,)
    for start in starts:
        batch = copy.deepcopy(document)
        for vehicle in batch["vehicles"]:
            vehicle["fills"] = []
        for vehicle_index, fill in flattened[start : start + batch_size]:
            batch["vehicles"][vehicle_index]["fills"].append(copy.deepcopy(fill))
        yield batch


def parse_report(report):
    parsed = {}
    for name, pattern in REPORT_PATTERNS.items():
        match = pattern.search(report)
        if match is None:
            label = {
                "fills": "Fills",
                "definitions": "Definitions",
                "places": "Places",
                "vehicles": "Vehicles",
                "station_none": "Station-none fills",
                "totals": "Total cross-check",
                "unit_mismatches": "Unit mismatches",
            }[name]
            raise ValueError(f"import response omitted {label}")
        values = [int(value) for value in match.groups()]
        parsed[name] = values if len(values) > 1 else values[0]
    return parsed


def aggregate_reports(reports):
    aggregate = {
        "fills": [0, 0, 0, 0],
        "definitions": [0, 0],
        "places": [0, 0],
        "vehicles": [0, 0],
        "station_none": 0,
        "totals": [0, 0, 0],
        "unit_mismatches": 0,
    }
    for report in reports:
        parsed = parse_report(report)
        for name in ("fills", "definitions", "places", "vehicles", "totals"):
            aggregate[name] = [
                previous + current
                for previous, current in zip(aggregate[name], parsed[name])
            ]
        aggregate["station_none"] += parsed["station_none"]
        aggregate["unit_mismatches"] += parsed["unit_mismatches"]
    return aggregate


def render_aggregate(aggregate):
    imported, already, conflicts, failures = aggregate["fills"]
    definitions_created, definitions_reused = aggregate["definitions"]
    places_created, places_reused = aggregate["places"]
    vehicles_created, vehicles_reused = aggregate["vehicles"]
    exact, off_by_one, beyond = aggregate["totals"]
    return "\n".join(
        (
            f"Fills: imported {imported}, already-imported {already}, "
            f"conflicts {conflicts}, failures {failures}",
            f"Definitions: created {definitions_created}, reused {definitions_reused}",
            f"Places: created {places_created}, reused {places_reused}",
            f"Vehicles: created {vehicles_created}, reused {vehicles_reused}",
            f"Station-none fills: {aggregate['station_none']}",
            f"Total cross-check: exact {exact}, off-by-one {off_by_one}, "
            f"beyond {beyond}",
            f"Unit mismatches: {aggregate['unit_mismatches']}",
        )
    )


def cookie_header(cookie_path):
    cookies = []
    with pathlib.Path(cookie_path).open(encoding="utf-8") as source:
        for raw_line in source:
            line = raw_line.rstrip("\n")
            if line.startswith("#HttpOnly_"):
                line = line.removeprefix("#HttpOnly_")
            elif line.startswith("#") or not line:
                continue
            fields = line.split("\t")
            if len(fields) != 7:
                continue
            name, value = fields[5:7]
            if name.startswith("urbauth-"):
                cookies.append(f"{name}={value}")
    if not cookies:
        raise ValueError("cookie file contains no urbauth cookie")
    return "; ".join(cookies)


def cookie_opener(cookie_path):
    opener = urllib.request.build_opener()
    opener.addheaders = [("Cookie", cookie_header(cookie_path))]
    return opener


def post_batch(opener, endpoint, document, timeout):
    body = json.dumps(
        document, ensure_ascii=False, separators=(",", ":"), sort_keys=True
    ).encode("utf-8")
    request = urllib.request.Request(
        endpoint,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with opener.open(request, timeout=timeout) as response:
        return response.read().decode("utf-8")


def fill_count(document):
    return sum(len(vehicle["fills"]) for vehicle in document["vehicles"])


def parser():
    result = argparse.ArgumentParser(
        description="Upload Rover import JSON in provenance-resumable batches."
    )
    result.add_argument("document", type=pathlib.Path)
    result.add_argument("--url", help="full /apps/rover/import endpoint")
    result.add_argument("--cookie-file", type=pathlib.Path)
    result.add_argument("--batch-size", type=int, default=50)
    result.add_argument("--timeout", type=int, default=120)
    result.add_argument(
        "--aggregate-only",
        action="store_true",
        help="suppress per-batch reports, including record-level conflict details",
    )
    result.add_argument(
        "--dry-run",
        action="store_true",
        help="validate and report the planned batch count without sending",
    )
    return result


def main(argv=None):
    arguments = parser().parse_args(argv)
    document = load_document(arguments.document)
    batches = list(batch_documents(document, arguments.batch_size))
    total = fill_count(document)
    batched_total = sum(fill_count(batch) for batch in batches)
    if total != batched_total:
        raise RuntimeError(f"batching changed fill count from {total} to {batched_total}")

    if arguments.dry_run:
        print(f"Validated {total} fills in {len(batches)} batch(es); nothing sent.")
        return 0
    if not arguments.url or not arguments.cookie_file:
        parser().error("--url and --cookie-file are required unless --dry-run is used")

    opener = cookie_opener(arguments.cookie_file)
    reports = []
    for index, batch in enumerate(batches, 1):
        report = post_batch(opener, arguments.url, batch, arguments.timeout)
        parsed = parse_report(report)
        reports.append(report)
        if arguments.aggregate_only:
            imported, already, conflicts, failures = parsed["fills"]
            print(
                f"Batch {index}/{len(batches)} complete: imported {imported}, "
                f"already-imported {already}, conflicts {conflicts}, "
                f"failures {failures}",
                file=sys.stderr,
                flush=True,
            )
        else:
            print(f"Batch {index}/{len(batches)}")
            print(report.rstrip())

    aggregate = aggregate_reports(reports)
    print("Aggregate")
    print(render_aggregate(aggregate))
    conflicts = aggregate["fills"][2]
    failures = aggregate["fills"][3]
    return 1 if conflicts or failures else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"rover-import: {error}", file=sys.stderr)
        raise SystemExit(2)
