#!/usr/bin/env python3
"""Synthetic-only tests for the Rover batch uploader."""

import importlib.util
import json
import pathlib
import tempfile
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("upload.py")
SPEC = importlib.util.spec_from_file_location("rover_import_upload", MODULE_PATH)
upload = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(upload)


def synthetic_document(fill_count=7):
    return {
        "rover-import": 1,
        "source": {"app": "synthetic"},
        "definitions": {
            "energy": [{"label": "Synthetic Gasoline"}],
            "additives": [],
            "driving-modes": [],
            "tags": [],
            "payment-methods": [],
        },
        "places": [{"label": "Synthetic Station"}],
        "vehicles": [
            {
                "label": "Synthetic One",
                "distanceUnit": "mi",
                "volumeUnit": "gal",
                "defaultEnergy": "Synthetic Gasoline",
                "energy": ["Synthetic Gasoline"],
                "fills": [
                    {"sourceRecordId": f"one-{index}"}
                    for index in range(fill_count - 2)
                ],
            },
            {
                "label": "Synthetic Two",
                "distanceUnit": "mi",
                "volumeUnit": "gal",
                "defaultEnergy": "Synthetic Gasoline",
                "energy": ["Synthetic Gasoline"],
                "fills": [
                    {"sourceRecordId": f"two-{index}"} for index in range(2)
                ],
            },
        ],
    }


class BatchTests(unittest.TestCase):
    def test_batches_preserve_order_support_records_and_all_fills(self):
        document = synthetic_document()
        batches = list(upload.batch_documents(document, 3))

        self.assertEqual(len(batches), 3)
        self.assertTrue(all(batch["definitions"] == document["definitions"] for batch in batches))
        self.assertTrue(all(batch["places"] == document["places"] for batch in batches))
        self.assertTrue(all(len(batch["vehicles"]) == 2 for batch in batches))
        identifiers = [
            fill["sourceRecordId"]
            for batch in batches
            for vehicle in batch["vehicles"]
            for fill in vehicle["fills"]
        ]
        self.assertEqual(
            identifiers,
            ["one-0", "one-1", "one-2", "one-3", "one-4", "two-0", "two-1"],
        )

    def test_batch_size_must_be_positive(self):
        with self.assertRaisesRegex(ValueError, "batch size"):
            list(upload.batch_documents(synthetic_document(), 0))

    def test_json_loader_rejects_floating_point_tokens(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "bad.json"
            path.write_text('{"rover-import":1,"bad":1.25}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "floating-point"):
                upload.load_document(path)


class ReportTests(unittest.TestCase):
    def test_aggregate_sums_all_batch_counters(self):
        reports = [
            """Fills: imported 3, already-imported 0, conflicts 0, failures 0
Definitions: created 4, reused 0
Places: created 2, reused 0
Vehicles: created 2, reused 0
Station-none fills: 1
Total cross-check: exact 3, off-by-one 0, beyond 0
Unit mismatches: 0""",
            """Fills: imported 1, already-imported 2, conflicts 0, failures 0
Definitions: created 0, reused 4
Places: created 0, reused 2
Vehicles: created 0, reused 2
Station-none fills: 2
Total cross-check: exact 3, off-by-one 0, beyond 0
Unit mismatches: 0""",
        ]

        aggregate = upload.aggregate_reports(reports)

        self.assertEqual(aggregate["fills"], [4, 2, 0, 0])
        self.assertEqual(aggregate["definitions"], [4, 4])
        self.assertEqual(aggregate["places"], [2, 2])
        self.assertEqual(aggregate["vehicles"], [2, 2])
        self.assertEqual(aggregate["station_none"], 3)
        self.assertEqual(aggregate["totals"], [6, 0, 0])
        self.assertEqual(aggregate["unit_mismatches"], 0)

    def test_missing_report_line_is_a_hard_error(self):
        with self.assertRaisesRegex(ValueError, "Fills"):
            upload.aggregate_reports(["not an import report"])


class CookieTests(unittest.TestCase):
    def test_curl_httponly_cookie_becomes_an_explicit_request_header(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "cookies.txt"
            path.write_text(
                "# Netscape HTTP Cookie File\n"
                "#HttpOnly_localhost\tFALSE\t/\tFALSE\t0\t"
                "urbauth-synthetic\tsynthetic-secret\n",
                encoding="utf-8",
            )

            self.assertEqual(
                upload.cookie_header(path),
                "urbauth-synthetic=synthetic-secret",
            )


if __name__ == "__main__":
    unittest.main()
