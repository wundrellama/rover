#!/usr/bin/env python3
"""Synthetic-only tests for the aCar converter."""

import ast
import pathlib
import unittest

import convert


FUEL_TYPES = {
    "synthetic-diesel": convert.FuelType(
        category="diesel", name="Example Diesel", rating="45", rating_type="cetane"
    )
}


def synthetic_fill(**overrides):
    record = {
        "date": "07/30/2026 - 09:15",
        "odometer-reading": "12345.6",
        "volume": "12.345",
        "price-per-volume-unit": "3.499",
        "total-cost": "43.19",
        "fuel-efficiency": "20.000000",
        "fuel-type-id": "synthetic-diesel",
        "partial": "false",
        "previous-missed-fillups": "false",
        "has-fuel-additive": "false",
        "driving-mode": "normal",
        "_remote_id": "synthetic-record-1",
    }
    record.update(overrides)
    return record


class DecimalTests(unittest.TestCase):
    def test_decimal_string_surgery_preserves_3499(self):
        value = convert.parse_decimal("3.499")
        self.assertEqual((value.sign, value.digits, value.scale), (1, 3499, 3))
        self.assertEqual(convert.fixed_decimal("3.499", 3), "3.499")

    def test_coordinate_rounding_is_half_up_and_symmetric(self):
        self.assertEqual(convert.fixed_decimal("1.00000005", 7), "1.0000001")
        self.assertEqual(convert.fixed_decimal("-1.00000005", 7), "-1.0000001")
        self.assertEqual(
            convert.fixed_decimal("-97.123456789012345", 7), "-97.1234568"
        )

    def test_value_path_has_no_float_or_round_calls(self):
        tree = ast.parse(pathlib.Path(convert.__file__).read_text(encoding="utf-8"))
        forbidden = [
            node.func.id
            for node in ast.walk(tree)
            if isinstance(node, ast.Call)
            and isinstance(node.func, ast.Name)
            and node.func.id in {"float", "round"}
        ]
        self.assertEqual(forbidden, [])


class FillMappingTests(unittest.TestCase):
    def make_fill(self, record):
        stats = convert.ReportStats()
        fill = convert.convert_fill(
            record=record,
            vehicle_label="Synthetic Vehicle",
            vehicle_dir="vehicle-1",
            distance_unit="mile",
            volume_unit="us_gallon",
            fuel_types=FUEL_TYPES,
            zone="America/Chicago",
            stats=stats,
        )
        return fill, stats

    def test_absent_optional_fields_stay_absent(self):
        fill, _ = self.make_fill(synthetic_fill())
        for key in (
            "averageSpeed",
            "speedUnit",
            "driveBalance",
            "notes",
            "paymentMethod",
            "newAddressFormatted",
        ):
            self.assertNotIn(key, fill)
        self.assertEqual(fill["additives"], [])

    def test_deleted_tag_is_suppressed_but_owner_tag_survives(self):
        fill, stats = self.make_fill(synthetic_fill(tags="deleted,Active Regen"))
        self.assertEqual(fill["tags"], ["Active Regen"])
        self.assertEqual(stats.deleted_tags_suppressed, 1)

    def test_missed_fill_is_parsed_as_boolean_not_count(self):
        missed, _ = self.make_fill(
            synthetic_fill(**{"previous-missed-fillups": "true"})
        )
        normal, _ = self.make_fill(
            synthetic_fill(**{"previous-missed-fillups": "false"})
        )
        self.assertEqual(missed["missedFill"], "yes")
        self.assertEqual(normal["missedFill"], "no")

    def test_parts_only_address_survives_without_formatted_text(self):
        fill, stats = self.make_fill(
            synthetic_fill(
                **{
                    "place-name": "Synthetic Depot",
                    "place-street": "20 Example Road",
                    "place-city": "Sampletown",
                }
            )
        )
        self.assertEqual(fill["station"], "new")
        self.assertEqual(fill["newAddressLine1"], "20 Example Road")
        self.assertEqual(fill["newLocality"], "Sampletown")
        self.assertNotIn("newAddressFormatted", fill)
        self.assertEqual(stats.parts_only_addresses, 1)

    def test_unlabelled_formatted_address_imports_without_station_and_is_reported(self):
        address = "10 Example Road, Sampletown"
        fill, stats = self.make_fill(
            synthetic_fill(**{"place-full-address": address})
        )
        self.assertEqual(fill["station"], "none")
        self.assertNotIn("newStationLabel", fill)
        self.assertEqual(stats.fills_out, 1)

        document = {
            "definitions": {
                "additives": [],
                "driving-modes": [],
                "energy": [],
                "payment-methods": [],
                "tags": [],
            },
            "places": [],
            "vehicles": [{"fills": [fill]}],
        }
        report = convert.render_report(document=document, stats=stats, dry_run=True)
        self.assertIn("Station-none fills with unmapped address text: 1", report)
        self.assertIn(address, report)


class CrossCheckTests(unittest.TestCase):
    def test_total_check_rounds_product_once_to_minor_unit(self):
        stats = convert.ReportStats()
        delta = convert.check_total(
            "vehicle-1/2026-07-30T09:15",
            quantity="1.500",
            price="0.003",
            source_total="0.00",
            stats=stats,
        )
        self.assertEqual(delta, 0)
        self.assertEqual(stats.total_exact, 1)
        self.assertEqual(stats.total_within_cent, 0)

    def test_total_check_parameterizes_minor_unit_decimals(self):
        stats = convert.ReportStats()
        delta = convert.check_total(
            "vehicle-1/2026-07-30T09:15",
            quantity="1.000",
            price="1.499",
            source_total="1",
            minor_unit_decimals=0,
            stats=stats,
        )
        self.assertEqual(delta, 0)
        self.assertEqual(stats.total_exact, 1)

    def test_known_wrong_total_is_named_and_counted(self):
        stats = convert.ReportStats()
        delta = convert.check_total(
            "vehicle-1/2026-07-30T09:15",
            quantity="10.000",
            price="3.499",
            source_total="20.00",
            stats=stats,
        )
        self.assertEqual(delta, 1499)
        self.assertEqual(stats.total_beyond, 1)
        self.assertIn("vehicle-1/2026-07-30T09:15", stats.total_mismatches[0])

    def test_efficiency_check_sorts_before_comparing(self):
        records = [
            synthetic_fill(
                date="07/03/2026 - 09:00",
                **{
                    "odometer-reading": "1300.0",
                    "volume": "10.000",
                    "fuel-efficiency": "19.000",
                },
            ),
            synthetic_fill(
                date="07/01/2026 - 09:00",
                **{
                    "odometer-reading": "1000.0",
                    "volume": "8.000",
                    "fuel-efficiency": "",
                },
            ),
            synthetic_fill(
                date="07/02/2026 - 09:00",
                **{
                    "odometer-reading": "1100.0",
                    "volume": "10.000",
                    "fuel-efficiency": "10.000",
                },
            ),
        ]
        stats = convert.ReportStats()
        convert.check_efficiencies("vehicle-1", records, stats)
        self.assertEqual(stats.efficiency_pairs, 2)
        self.assertEqual(stats.efficiency_beyond, 1)
        self.assertIn("2026-07-03T09:00", stats.efficiency_mismatches[0])


class AttachmentTests(unittest.TestCase):
    def test_jpeg_app_markers_are_removed(self):
        app1 = b"\xff\xe1\x00\x06EXIF"
        dqt = b"\xff\xdb\x00\x04AB"
        scan = b"\xff\xda\x00\x04CDimage-data\xff\xd9"
        stripped = convert.strip_jpeg_app_segments(b"\xff\xd8" + app1 + dqt + scan)
        self.assertEqual(stripped, b"\xff\xd8" + dqt + scan)
        self.assertNotIn(b"\xff\xe1", stripped)


if __name__ == "__main__":
    unittest.main()
