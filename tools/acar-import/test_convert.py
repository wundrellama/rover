#!/usr/bin/env python3
"""Synthetic-only tests for the aCar converter."""

import ast
import json
import pathlib
import tempfile
import unittest

import convert


FUEL_TYPES = {
    "synthetic-diesel": convert.FuelType(
        category="diesel", name="Example Diesel", rating="45", rating_type="cetane"
    ),
    "synthetic-gasoline": convert.FuelType(
        category="gasoline",
        name="Example Gasoline",
        rating="93",
        rating_type="octane_aki",
    ),
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


def write_synthetic_export(directory):
    directory.mkdir()
    (directory / "metadata.inf").write_text(
        "\n".join(
            (
                "acar.backup.version=11",
                "acar.version=5.6.12",
                "acar.backup.datetime=2026-07-30T09:30:00-05:00",
            )
        ),
        encoding="utf-8",
    )
    (directory / "fuel-types.xml").write_text(
        """<fuel-types>
<fuel-type id="synthetic-diesel"><category>diesel</category><name>Example Diesel</name><rating>45</rating><rating-type>cetane</rating-type></fuel-type>
<fuel-type id="synthetic-gasoline"><category>gasoline</category><name>Example Gasoline</name><rating>93</rating><rating-type>octane_aki</rating-type></fuel-type>
</fuel-types>""",
        encoding="utf-8",
    )
    for name, root in (
        ("trip-types.xml", "trip-types"),
        ("preferences.xml", "preferences"),
    ):
        (directory / name).write_text(f"<{root}/>", encoding="utf-8")
    (directory / "event-subtypes.xml").write_text(
        """<event-subtypes>
<event-subtype id="synthetic-service" type="service"><name>Example Service</name><default-distance-reminder-interval>5000</default-distance-reminder-interval><default-time-reminder-interval>6</default-time-reminder-interval></event-subtype>
<event-subtype id="synthetic-expense" type="expense"><name>Example Service</name><default-distance-reminder-interval></default-distance-reminder-interval><default-time-reminder-interval></default-time-reminder-interval></event-subtype>
</event-subtypes>""",
        encoding="utf-8",
    )
    fill = synthetic_fill()
    fields = "".join(
        f"<{key}>{value}</{key}>"
        for key, value in fill.items()
        if key != "_remote_id"
    )
    (directory / "vehicles.xml").write_text(
        f"""<vehicles><vehicle id="synthetic-vehicle">
<name>Synthetic Vehicle</name><distance-unit>mile</distance-unit>
<volume-unit>us_gallon</volume-unit><fuel-tank-capacity>20.0</fuel-tank-capacity>
<vin>ROVERFAKEVIN00009</vin><license-plate>ROVER-FAKE-09</license-plate>
<year>2020</year><make>Example Make</make><model>Example Model</model>
<sub-model>Example Trim</sub-model><body-type>Example Body</body-type>
<color>Example Blue</color><engine>Example Engine</engine>
<transmission>Example Transmission</transmission><drive-type>Example Drive</drive-type>
<bed-type>Example Bed</bed-type><notes>Example vehicle note</notes>
<fillup-record>{fields}<sync-metadata><remote-id>{fill["_remote_id"]}</remote-id></sync-metadata></fillup-record>
<event-record id="synthetic-event"><date>07/31/2026 - 10:30</date><type>service</type><odometer-reading>12400.0</odometer-reading><total-cost>88.40</total-cost><place-name>Example Workshop</place-name><payment-type>Example Card</payment-type><tags>Example Tag</tags><notes>Example service note</notes><subtypes><subtype id="synthetic-service"/></subtypes><sync-metadata><remote-id>synthetic-event-remote</remote-id></sync-metadata></event-record>
<reminders><reminder id="synthetic-reminder" event-subtype-id="synthetic-service" event-type="service"><distance-interval>5000</distance-interval><distance-due>17400</distance-due><time-interval>6</time-interval><time-unit>months</time-unit><time-due>01/31/2027</time-due></reminder></reminders>
</vehicle></vehicles>""",
        encoding="utf-8",
    )


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

    def test_reminder_due_timestamp_maps_to_its_calendar_day(self):
        self.assertEqual(
            convert.calendar_day("10/01/2025 - 10:45"), "2025-10-01"
        )


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
        self.assertNotIn(address, report)


class CorrectionTests(unittest.TestCase):
    def correction(self):
        return convert.Correction(
            source_record_id="synthetic-record-1",
            field="fuel-type-id",
            before="synthetic-diesel",
            after="synthetic-gasoline",
            before_label="Example Diesel",
            after_label="Example Gasoline",
            reason="Synthetic owner-ratified correction.",
        )

    def test_correction_applies_and_is_reported_in_dry_run(self):
        correction_document = {
            "rover-corrections": 1,
            "source-app": "acar",
            "corrections": [
                {
                    "source-record-id": "synthetic-record-1",
                    "field": "fuel-type-id",
                    "from": "synthetic-diesel",
                    "to": "synthetic-gasoline",
                    "from-label": "Example Diesel",
                    "to-label": "Example Gasoline",
                    "reason": "Synthetic owner-ratified correction.",
                    "ratified": "2026-07-30",
                    "ratified-by": "owner",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "corrections.json"
            path.write_text(json.dumps(correction_document), encoding="utf-8")
            corrections = convert.load_corrections(path.parent)

        record = synthetic_fill()
        stats = convert.ReportStats()
        convert.apply_record_correction(
            record,
            corrections=corrections,
            record_name="Synthetic Vehicle/2026-07-30T09:15",
            stats=stats,
        )

        self.assertEqual(record["fuel-type-id"], "synthetic-gasoline")
        document = {
            "definitions": {
                "additives": [],
                "driving-modes": [],
                "energy": [],
                "payment-methods": [],
                "tags": [],
            },
            "places": [],
            "vehicles": [],
        }
        report = convert.render_report(document=document, stats=stats, dry_run=True)
        self.assertIn("Corrections that would be applied: 1", report)
        self.assertNotIn("Example Diesel -> Example Gasoline", report)
        self.assertNotIn("Synthetic owner-ratified correction.", report)

    def test_correction_with_stale_from_is_a_hard_error(self):
        record = synthetic_fill(**{"fuel-type-id": "synthetic-electricity"})
        with self.assertRaisesRegex(
            convert.ConversionError,
            "stale correction.*Example Diesel.*Example Gasoline.*expected fuel-type-id.*found",
        ):
            convert.apply_record_correction(
                record,
                corrections={"synthetic-record-1": self.correction()},
                record_name="Synthetic Vehicle/2026-07-30T09:15",
                stats=convert.ReportStats(),
            )
        self.assertEqual(record["fuel-type-id"], "synthetic-electricity")

    def test_converter_loads_correction_beside_export_before_mapping(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            export_dir = root / "export"
            output_dir = root / "output"
            write_synthetic_export(export_dir)
            correction = {
                "rover-corrections": 1,
                "source-app": "acar",
                "corrections": [
                    {
                        "source-record-id": "synthetic-record-1",
                        "field": "fuel-type-id",
                        "from": "synthetic-diesel",
                        "to": "synthetic-gasoline",
                        "from-label": "Example Diesel",
                        "to-label": "Example Gasoline",
                        "reason": "Synthetic owner-ratified correction.",
                        "ratified": "2026-07-30",
                        "ratified-by": "owner",
                    }
                ],
            }
            (export_dir / "corrections.json").write_text(
                json.dumps(correction), encoding="utf-8"
            )

            document, _, report = convert.convert_export(
                export_dir,
                output_dir,
                dry_run=True,
                zone="America/Chicago",
            )

        vehicle = document["vehicles"][0]
        self.assertEqual(vehicle["defaultEnergy"], "Gasoline")
        self.assertEqual(vehicle["fills"][0]["definition"], "Gasoline")
        self.assertIn("Corrections that would be applied: 1", report)


class VehicleDefaultTests(unittest.TestCase):
    def test_multiple_referenced_definitions_stop_and_name_the_split(self):
        vehicle = convert.VehicleSource(
            index=1,
            label="Synthetic Split-Fuel Vehicle",
            distance_unit="mile",
            volume_unit="us_gallon",
            tank_capacity="",
            records=[
                synthetic_fill(),
                synthetic_fill(
                    date="07/31/2026 - 09:15",
                    **{
                        "_remote_id": "synthetic-record-2",
                        "fuel-type-id": "synthetic-gasoline",
                    },
                ),
            ],
        )
        with self.assertRaisesRegex(
            convert.ConversionError,
            "Synthetic Split-Fuel Vehicle.*references multiple energy definitions.*Diesel=1.*Gasoline=1",
        ):
            convert.make_import_document(
                metadata={
                    "acar.backup.version": "11",
                    "acar.version": "5.6.12",
                    "acar.backup.datetime": "2026-07-30T09:30:00-05:00",
                },
                vehicles=[vehicle],
                fuel_types=FUEL_TYPES,
                event_subtypes={},
                zone="America/Chicago",
                stats=convert.ReportStats(),
            )


class VehicleUnitTests(unittest.TestCase):
    def test_fill_unit_mismatches_are_named_and_reported(self):
        stats = convert.ReportStats()
        convert.check_import_units(
            vehicle_label="Synthetic Unit Vehicle",
            distance_unit="mi",
            volume_unit="gal",
            fills=[
                {
                    "observed": "2026-07-30T09:15",
                    "mileageUnit": "km",
                    "profile": "eu-eur-litre",
                }
            ],
            stats=stats,
        )

        self.assertEqual(stats.unit_mismatches, 2)
        self.assertIn(
            "Synthetic Unit Vehicle/2026-07-30T09:15: distance km != vehicle mi",
            stats.unit_mismatch_details,
        )
        self.assertIn(
            "Synthetic Unit Vehicle/2026-07-30T09:15: volume litre != vehicle gal",
            stats.unit_mismatch_details,
        )
        report = convert.render_report(
            document={
                "definitions": {
                    "additives": [],
                    "driving-modes": [],
                    "energy": [],
                    "payment-methods": [],
                    "tags": [],
                },
                "places": [],
                "vehicles": [],
            },
            stats=stats,
            dry_run=True,
        )
        self.assertIn("Unit mismatches: 2", report)
        self.assertNotIn("Synthetic Unit Vehicle", report)


class ImportWideningTests(unittest.TestCase):
    def test_events_subtypes_reminders_and_specification_enter_the_document(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            export_dir = root / "export"
            output_dir = root / "output"
            write_synthetic_export(export_dir)

            document, _, report = convert.convert_export(
                export_dir,
                output_dir,
                dry_run=True,
                zone="America/Chicago",
            )

        subtypes = document["definitions"]["service-subtypes"]
        self.assertEqual(
            subtypes,
            [
                {
                    "defaultDistanceInterval": "5000",
                    "defaultDistanceUnit": "mi",
                    "defaultTimeInterval": "6",
                    "defaultTimeUnit": "month",
                    "label": "Example Service",
                }
            ],
        )
        vehicle = document["vehicles"][0]
        self.assertEqual(len(vehicle["serviceEvents"]), 1)
        event = vehicle["serviceEvents"][0]
        self.assertNotIn("kind", event)
        self.assertEqual(event["subtypes"], ["Example Service"])
        self.assertEqual(event["mileage"], "12400.0")
        self.assertEqual(event["station"], "Example Workshop")
        self.assertEqual(event["total"], "88.40")
        self.assertEqual(event["sourceRecordId"], "synthetic-event-remote")
        self.assertEqual(vehicle["noteEvents"], [])
        self.assertEqual(
            vehicle["reminders"],
            [
                {
                    "distanceDue": "17400",
                    "distanceInterval": "5000",
                    "distanceUnit": "mi",
                    "subtype": "Example Service",
                    "timeDue": "2027-01-31",
                    "timeInterval": "6",
                    "timeUnit": "month",
                    "vehicle": "Synthetic Vehicle",
                }
            ],
        )
        self.assertEqual(
            set(vehicle["specification"]),
            {
                "specBedType",
                "specBodyType",
                "specColor",
                "specDriveType",
                "specEngine",
                "specMake",
                "specModel",
                "specNotes",
                "specPlate",
                "specTransmission",
                "specSubModel",
                "specVin",
                "specYear",
            },
        )
        self.assertIn("Service events imported: 1", report)
        self.assertIn("Reminders imported: 1", report)
        self.assertIn("Source subtype definitions processed: 2", report)
        self.assertIn("Duplicate service/expense labels reused: 1", report)

    def test_report_explains_ruled_omissions_in_owner_language(self):
        stats = convert.ReportStats()
        stats.trip_records = 2
        stats.trip_types = 6
        stats.attachments = 3
        stats.attachment_fill_count = 2
        stats.attachment_vehicle_count = 1
        stats.attachment_records = 3
        stats.attachment_raw_hashes.update({"one", "two", "three"})
        stats.unmapped_nonempty.update(
            {
                "vehicle.insurance-policy": 2,
                "fill.device-coordinate-pair": 4,
                "vehicle.active": 2,
            }
        )
        document = {
            "definitions": {
                "energy": [],
                "additives": [],
                "driving-modes": [],
                "tags": [],
                "payment-methods": [],
            },
            "places": [],
            "vehicles": [],
        }

        report = convert.render_report(document=document, stats=stats, dry_run=True)

        self.assertIn(
            "Insurance policy strings: 2 not imported (insurance is fenced; a policy string is not an insurance feature)",
            report,
        )
        self.assertIn(
            "Device coordinate pairs on fills: 4 not imported (device location is not evidence of the station location)",
            report,
        )
        self.assertIn(
            "Source field vehicle.active: 2 not imported (no ratified Rover target; no mapping was invented)",
            report,
        )
        self.assertIn(
            "Photos extracted to disk, not the database: 3",
            report,
        )


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
    def test_owner_attachment_preserves_jpeg_app_markers(self):
        app1 = b"\xff\xe1\x00\x06EXIF"
        dqt = b"\xff\xdb\x00\x04AB"
        scan = b"\xff\xda\x00\x04CDimage-data\xff\xd9"
        original = b"\xff\xd8" + app1 + dqt + scan
        self.assertEqual(convert.owner_jpeg_bytes(original), original)
        self.assertIn(b"\xff\xe1", convert.owner_jpeg_bytes(original))


if __name__ == "__main__":
    unittest.main()
