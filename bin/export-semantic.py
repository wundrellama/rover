#!/usr/bin/env python3
"""Order-independent checks for Rover export fixtures."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


def normalize(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: normalize(child) for key, child in sorted(value.items())}
    if isinstance(value, list):
        children = [normalize(child) for child in value]
        return sorted(
            children,
            key=lambda child: json.dumps(
                child, sort_keys=True, separators=(",", ":"), ensure_ascii=False
            ),
        )
    return value


def canonical(document: Any) -> bytes:
    return json.dumps(
        normalize(document), sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode()


def digest(document: Any) -> str:
    return hashlib.sha256(canonical(document)).hexdigest()


def load(path: str) -> Any:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def section(source: str, arm: str) -> str:
    start = source.index(f"++  {arm}")
    match = re.search(r"^\+\+  ", source[start + 1 :], re.MULTILINE)
    if match is None:
        return source[start:]
    return source[start : start + 1 + match.start()]


def hoon_strings(block: str) -> list[str]:
    values: list[str] = []
    for line in block.splitlines():
        token = line.strip()
        if not (token.startswith('"') and token.endswith('"')):
            continue
        value = json.loads(token)
        if value.lstrip().startswith("FROM "):
            values.append(value.strip())
    return values


def export_queries(path: str) -> list[str]:
    source = Path(path).read_text(encoding="utf-8")
    queries = hoon_strings(section(source, "export-view"))
    spec_rows = re.findall(
        r"\[%([a-z0-9-]+) %([a-z0-9-]+)\]",
        section(source, "spec-view-order"),
    )
    queries.extend(
        f"FROM {relation} S SELECT S.vehicle-id, S.{column};"
        for relation, column in spec_rows
    )
    if len(queries) != 101:
        raise SystemExit(f"export-semantic: found {len(queries)} export queries, want 101")
    return queries


def primary_keys(*paths: str) -> dict[str, list[str]]:
    keys: dict[str, list[str]] = {}
    for path in paths:
        source = Path(path).read_text(encoding="utf-8")
        declarations = re.findall(
            r"CREATE TABLE rover\.\.([a-z0-9-]+).*?PRIMARY KEY \(([^)]+)\)",
            source,
            re.DOTALL,
        )
        for relation, columns in declarations:
            key = [column.strip() for column in columns.split(",")]
            if relation in keys and keys[relation] != key:
                raise SystemExit(f"export-semantic: conflicting keys for {relation}")
            keys[relation] = key
    return keys


def count_queries(rover_act: str, schema: str) -> list[str]:
    keys = primary_keys(rover_act, schema)
    queries: list[str] = []
    for query in export_queries(rover_act):
        relation = relation_name(query)
        if relation not in keys:
            raise SystemExit(f"export-semantic: {relation} has no declared primary key")
        selection = ", ".join(f"X.{column}" for column in keys[relation])
        queries.append(f"FROM {relation} X SELECT {selection};")
    return queries


def relation_name(query: str) -> str:
    match = re.match(r"FROM ([a-z0-9-]+) ", query)
    if match is None:
        raise SystemExit(f"export-semantic: cannot read relation from {query!r}")
    return match.group(1)


def summary(document: dict[str, Any]) -> dict[str, int]:
    vehicles = document["vehicles"]
    keys = (
        "fills",
        "chargingSessions",
        "consumableAcquisitions",
        "serviceEvents",
        "expenseEvents",
        "noteEvents",
        "acquisitionEvents",
        "disposalEvents",
        "reminders",
        "odometerReadings",
    )
    result = {
        "vehicles": len(vehicles),
        "places": len(document["places"]),
        "stations": sum(len(place.get("stations", [])) for place in document["places"]),
        "definitions": sum(len(rows) for rows in document["definitions"].values()),
    }
    for key in keys:
        result[key] = sum(len(vehicle.get(key, [])) for vehicle in vehicles)
    return result


def command_compare(before_path: str, after_path: str) -> int:
    before = load(before_path)
    after = load(after_path)
    before_digest = digest(before)
    after_digest = digest(after)
    print(f"SEMANTIC_SHA_BEFORE={before_digest}")
    print(f"SEMANTIC_SHA_AFTER={after_digest}")
    print(f"SUMMARY_BEFORE={json.dumps(summary(before), sort_keys=True, separators=(',', ':'))}")
    print(f"SUMMARY_AFTER={json.dumps(summary(after), sort_keys=True, separators=(',', ':'))}")
    if canonical(before) != canonical(after):
        print("SEMANTIC_EQUAL=no")
        return 1
    print("SEMANTIC_EQUAL=yes")
    return 0


def command_history() -> int:
    document = sys.stdin.read()
    cards = re.findall(
        r'<article\b[^>]*class="[^"]*history-card[^"]*".*?</article>',
        document,
        re.DOTALL,
    )
    normalized = sorted(re.sub(r"\s+", " ", card).strip() for card in cards)
    for card in normalized:
        print(card)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    compare_parser = subparsers.add_parser("compare")
    compare_parser.add_argument("before")
    compare_parser.add_argument("after")
    sql_parser = subparsers.add_parser("sql")
    sql_parser.add_argument("rover_act")
    sql_parser.add_argument("--chunk-size", type=int)
    count_sql_parser = subparsers.add_parser("count-sql")
    count_sql_parser.add_argument("rover_act")
    count_sql_parser.add_argument("schema")
    count_sql_parser.add_argument("--chunk-size", type=int)
    relation_parser = subparsers.add_parser("relations")
    relation_parser.add_argument("rover_act")
    subparsers.add_parser("history")
    args = parser.parse_args()

    if args.command == "compare":
        return command_compare(args.before, args.after)
    if args.command in ("sql", "count-sql"):
        queries = (
            export_queries(args.rover_act)
            if args.command == "sql"
            else count_queries(args.rover_act, args.schema)
        )
        if args.chunk_size is None:
            print(" ".join(queries))
            return 0
        if args.chunk_size < 1:
            raise SystemExit("export-semantic: chunk size must be positive")
        for start in range(0, len(queries), args.chunk_size):
            print(" ".join(queries[start : start + args.chunk_size]))
        return 0
    if args.command == "relations":
        for query in export_queries(args.rover_act):
            print(relation_name(query))
        return 0
    return command_history()


if __name__ == "__main__":
    raise SystemExit(main())
