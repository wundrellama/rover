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
        ("event-subtypes.xml", "event-subtypes"),
        ("preferences.xml", "preferences"),
    ):
        (directory / name).write_text(f"<{root}/>", encoding="utf-8")
    fill = synthetic_fill()
    fields = "".join(
        f"<{key}>{value}</{key}>"
        for key, value in fill.items()
        if key != "_remote_id"
    )
    (directory / "vehicles.xml").write_text(
        f"""<vehicles><vehicle>
<name>Synthetic Vehicle</name><distance-unit>mile</distance-unit>
<volume-unit>us_gallon</volume-unit><fuel-tank-capacity>20.0</fuel-tank-capacity>
<fillup-record>{fields}<sync-metadata><remote-id>{fill["_remote_id"]}</remote-id></sync-metadata></fillup-record>
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
        self.assertIn("Example Diesel -> Example Gasoline", report)
        self.assertIn("Synthetic owner-ratified correction.", report)

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
        self.assertIn("distance km != vehicle mi", report)
        self.assertIn("volume litre != vehicle gal", report)


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


EVENT_SUBTYPES = {
    "1": convert.EventSubtype(
        kind="service",
        name="Engine Oil",
        default_time="3",
        default_distance="3000",
    ),
    "2": convert.EventSubtype(
        kind="service", name="Car Wash", default_time="1", default_distance="1000"
    ),
    "3": convert.EventSubtype(
        kind="expense", name="Car Wash", default_time="", default_distance=""
    ),
    "4": convert.EventSubtype(
        kind="service", name="Tire Rotation", default_time="", default_distance=""
    ),
}


def synthetic_event(**overrides):
    record = {
        "type": "service",
        "date": "07/30/2026 - 11:20",
        "odometer-reading": "23456.7",
        "total-cost": "412.75",
        "payment-type": "Amex",
        "notes": "",
        "tags": "",
        "_remote_id": "synthetic-event-1",
        "_subtype_ids": ["1", "4"],
    }
    record.update(overrides)
    return record


class ServiceSubtypeTests(unittest.TestCase):
    def test_duplicate_labels_collapse_to_one_definition(self):
        definitions, stats = convert.build_service_subtypes(EVENT_SUBTYPES)
        labels = [entry["label"] for entry in definitions]
        self.assertEqual(labels, ["Car Wash", "Engine Oil", "Tire Rotation"])
        self.assertEqual(stats.subtype_records, 4)
        self.assertEqual(stats.subtype_labels_collapsed, 1)

    def test_a_definition_carries_a_label_and_nothing_else(self):
        definitions, stats = convert.build_service_subtypes(EVENT_SUBTYPES)
        for entry in definitions:
            self.assertEqual(sorted(entry), ["label"])
        self.assertEqual(stats.subtype_defaults_time, 2)
        self.assertEqual(stats.subtype_defaults_distance, 2)

    def test_the_catalog_suggestions_are_counted_for_the_report(self):
        stats = convert.ReportStats()
        convert.build_service_subtypes(EVENT_SUBTYPES, stats)
        notices = {item["kind"]: item for item in convert.build_notices(stats)}
        self.assertEqual(
            notices["Service-subtype default reminder intervals"]["count"], 2
        )

    def test_a_reminder_taking_the_catalog_suggestion_is_counted(self):
        stats = convert.ReportStats()
        convert.convert_reminder(
            source={
                "_subtype_id": "1",
                "time-interval": "3",
                "time-unit": "months",
                "time-due": "10/01/2025 - 10:45",
                "distance-interval": "3000.0",
                "distance-due": "83169.0",
            },
            vehicle_label="Synthetic Vehicle",
            distance_unit="mile",
            event_subtypes=EVENT_SUBTYPES,
            stats=stats,
        )
        self.assertEqual(stats.reminders_at_catalog_default, 1)


class EventMappingTests(unittest.TestCase):
    def make_event(self, record, kind="service"):
        stats = convert.ReportStats()
        event = convert.convert_event(
            record=record,
            vehicle_label="Synthetic Vehicle",
            vehicle_dir="vehicle-1",
            distance_unit="mile",
            event_subtypes=EVENT_SUBTYPES,
            zone="America/Chicago",
            stats=stats,
        )
        return event, stats

    def test_event_carries_odometer_total_and_subtype_labels(self):
        event, _ = self.make_event(synthetic_event())
        self.assertEqual(event["vehicle"], "Synthetic Vehicle")
        self.assertEqual(event["observed"], "2026-07-30T11:20")
        self.assertEqual(event["mileage"], "23456.7")
        self.assertEqual(event["mileageUnit"], "mi")
        self.assertEqual(event["total"], "412.75")
        self.assertEqual(event["paymentMethod"], "Amex")
        self.assertEqual(sorted(event["subtypes"]), ["Engine Oil", "Tire Rotation"])
        self.assertEqual(event["station"], "none")

    def test_absent_optional_fields_stay_absent(self):
        event, _ = self.make_event(synthetic_event())
        for key in ("notes", "newStationLabel"):
            self.assertNotIn(key, event)
        self.assertEqual(event["tags"], [])

    def test_a_zero_source_total_writes_no_total_and_is_reported(self):
        event, stats = self.make_event(synthetic_event(**{"total-cost": "0.0"}))
        self.assertNotIn("total", event)
        self.assertEqual(stats.event_zero_totals, 1)

    def test_a_note_record_carrying_money_is_reported_and_never_reclassified(self):
        event, stats = self.make_event(
            synthetic_event(type="note", _subtype_ids=[], **{"total-cost": "811.88"}),
            kind="note",
        )
        self.assertEqual(event["total"], "811.88")
        self.assertEqual(event["subtypes"], [])
        self.assertEqual(len(stats.note_records_with_cost), 1)
        self.assertIn("811.88", stats.note_records_with_cost[0])

    def test_deleted_tag_is_suppressed_on_an_event_too(self):
        event, stats = self.make_event(
            synthetic_event(tags="deleted,Scheduled Maintenance")
        )
        self.assertEqual(event["tags"], ["Scheduled Maintenance"])
        self.assertEqual(stats.deleted_tags_suppressed, 1)

    def test_a_named_place_becomes_a_private_station_by_label(self):
        event, _ = self.make_event(
            synthetic_event(
                **{"place-name": "Synthetic Garage", "place-city": "Sampletown"}
            )
        )
        self.assertEqual(event["station"], "Synthetic Garage")


class ReminderMappingTests(unittest.TestCase):
    def test_a_reminder_carries_both_intervals_and_a_day_due_point(self):
        stats = convert.ReportStats()
        reminder = convert.convert_reminder(
            source={
                "_subtype_id": "1",
                "time-interval": "3",
                "time-unit": "months",
                "time-due": "10/01/2025 - 10:45",
                "distance-interval": "3000.0",
                "distance-due": "83169.0",
            },
            vehicle_label="Synthetic Vehicle",
            distance_unit="mile",
            event_subtypes=EVENT_SUBTYPES,
            stats=stats,
        )
        self.assertEqual(reminder["vehicle"], "Synthetic Vehicle")
        self.assertEqual(reminder["subtype"], "Engine Oil")
        self.assertEqual(reminder["timeInterval"], "3")
        self.assertEqual(reminder["timeUnit"], "month")
        self.assertEqual(reminder["timeDue"], "2025-10-01")
        self.assertEqual(reminder["distanceInterval"], "3000.0")
        self.assertEqual(reminder["distanceDue"], "83169.0")
        self.assertEqual(reminder["distanceUnit"], "mi")
        self.assertEqual(stats.reminder_time_of_day_dropped, 1)

    def test_an_absent_interval_writes_no_key(self):
        stats = convert.ReportStats()
        reminder = convert.convert_reminder(
            source={
                "_subtype_id": "1",
                "time-interval": "",
                "time-unit": "",
                "time-due": "",
                "distance-interval": "3000.0",
                "distance-due": "83169.0",
            },
            vehicle_label="Synthetic Vehicle",
            distance_unit="mile",
            event_subtypes=EVENT_SUBTYPES,
            stats=stats,
        )
        for key in ("timeInterval", "timeUnit", "timeDue"):
            self.assertNotIn(key, reminder)


class SpecificationTests(unittest.TestCase):
    def test_only_the_fields_the_source_filled_become_keys(self):
        stats = convert.ReportStats()
        specification = convert.build_specification(
            {
                "vin": "SYNTHETICVIN00001",
                "license-plate": "FAKE-001",
                "year": "1981",
                "make": "Examplemobile",
                "model": "Prototype",
                "sub-model": "",
                "body-type": "pickup",
                "color": "",
                "engine": "5.7L V8",
                "transmission": "4-speed manual",
                "drive-type": "RWD",
                "bed-type": "8 ft",
                "notes": "",
            },
            stats=stats,
        )
        self.assertEqual(specification["vin"], "SYNTHETICVIN00001")
        self.assertEqual(specification["modelYear"], "1981")
        self.assertEqual(specification["bedType"], "8 ft")
        for key in ("subModel", "color", "note"):
            self.assertNotIn(key, specification)
        self.assertEqual(stats.specification_fields, 10)
        self.assertEqual(stats.specification_fields_absent, 3)

    def test_a_vehicle_with_no_specification_field_emits_no_section(self):
        stats = convert.ReportStats()
        specification = convert.build_specification(
            {key: "" for key in convert.SPECIFICATION_FIELDS}, stats=stats
        )
        self.assertEqual(specification, {})


class NoticeTests(unittest.TestCase):
    def test_every_unmapped_kind_is_named_with_a_count_and_a_reason(self):
        stats = convert.ReportStats()
        stats.trip_types = 6
        stats.reminders_in = 8
        stats.insurance_policies = 2
        stats.attachments = 121
        stats.unmapped_nonempty["vehicle.insurance-policy"] = 2
        notices = convert.build_notices(stats)
        by_kind = {notice["kind"]: notice for notice in notices}
        self.assertIn("Trip types", by_kind)
        self.assertEqual(by_kind["Trip types"]["count"], 6)
        self.assertTrue(by_kind["Trip types"]["reason"])
        self.assertIn("Insurance policies", by_kind)
        self.assertEqual(by_kind["Insurance policies"]["count"], 2)
        for notice in notices:
            self.assertTrue(notice["reason"].strip())
            self.assertIsInstance(notice["count"], int)

    def test_every_unmapped_field_the_report_names_carries_a_reason(self):
        for field in convert.UNMAPPED_REASONS:
            self.assertTrue(convert.UNMAPPED_REASONS[field].strip())
        stats = convert.ReportStats()
        stats.unmapped_nonempty["vehicle.insurance-policy"] = 2
        stats.unmapped_nonempty["fill.device-coordinate-pair"] = 318
        document = {
            "definitions": {
                "additives": [],
                "driving-modes": [],
                "energy": [],
                "payment-methods": [],
                "service-subtypes": [],
                "tags": [],
            },
            "notices": convert.build_notices(stats),
            "places": [],
            "vehicles": [],
        }
        report = convert.render_report(document=document, stats=stats, dry_run=True)
        self.assertIn(
            f"vehicle.insurance-policy: 2 - "
            f"{convert.UNMAPPED_REASONS['vehicle.insurance-policy']}",
            report,
        )
        self.assertIn(
            f"fill.device-coordinate-pair: 318 - "
            f"{convert.UNMAPPED_REASONS['fill.device-coordinate-pair']}",
            report,
        )


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
