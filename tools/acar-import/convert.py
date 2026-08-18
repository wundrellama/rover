#!/usr/bin/env python3
"""Convert an aCar XML export into deterministic Rover import JSON."""

from __future__ import annotations

import argparse
import base64
import collections
import dataclasses
import datetime
import hashlib
import json
import os
import pathlib
import re
import sys
import xml.etree.ElementTree as ET


class ConversionError(RuntimeError):
    """The export cannot be converted without guessing or losing required data."""


@dataclasses.dataclass(frozen=True)
class DecimalValue:
    sign: int
    digits: int
    scale: int


@dataclasses.dataclass(frozen=True)
class FuelType:
    category: str
    name: str
    rating: str
    rating_type: str


@dataclasses.dataclass(frozen=True)
class EventSubtype:
    source_id: str
    label: str
    source_kind: str
    default_distance_interval: str
    default_time_interval: str


@dataclasses.dataclass(frozen=True)
class Correction:
    source_record_id: str
    field: str
    before: str
    after: str
    before_label: str
    after_label: str
    reason: str


@dataclasses.dataclass
class ReportStats:
    vehicles: int = 0
    fills_in: int = 0
    fills_out: int = 0
    fills_dropped: int = 0
    event_records: int = 0
    trip_records: int = 0
    reminders: int = 0
    trip_types: int = 0
    event_subtypes: int = 0
    fuel_types: int = 0
    fuel_types_out: int = 0
    sync_metadata_records: int = 0
    event_subtypes_out: int = 0
    event_subtype_duplicates: int = 0
    event_subtype_defaults: int = 0
    service_events_out: int = 0
    note_events_out: int = 0
    expense_events_unmapped: int = 0
    note_events_with_cost: int = 0
    reminders_out: int = 0
    vehicle_specifications: int = 0
    vehicle_spec_fields: collections.Counter[str] = dataclasses.field(
        default_factory=collections.Counter
    )
    preferences: int = 0
    notes_imported: int = 0
    deleted_tags_suppressed: int = 0
    parts_only_addresses: int = 0
    unlabelled_station_addresses: list[str] = dataclasses.field(default_factory=list)
    corrections_applied: list[str] = dataclasses.field(default_factory=list)
    unit_mismatches: int = 0
    unit_mismatch_details: list[str] = dataclasses.field(default_factory=list)
    total_checks: int = 0
    total_exact: int = 0
    total_within_cent: int = 0
    total_beyond: int = 0
    total_mismatches: list[str] = dataclasses.field(default_factory=list)
    efficiency_pairs: int = 0
    efficiency_source_comparisons: int = 0
    efficiency_source_absent: int = 0
    efficiency_beyond: int = 0
    efficiency_mismatches: list[str] = dataclasses.field(default_factory=list)
    coordinate_values: int = 0
    coordinate_values_over_scale: int = 0
    place_coordinate_pairs: int = 0
    place_coordinate_values_rounded: int = 0
    device_coordinate_pairs: int = 0
    device_coordinate_values_rounded: int = 0
    pdf_tags: int = 0
    nonempty_pdfs: int = 0
    attachments: int = 0
    attachment_records: int = 0
    attachment_fill_count: int = 0
    attachment_event_count: int = 0
    attachment_vehicle_count: int = 0
    attachment_raw_bytes: int = 0
    attachment_written_bytes: int = 0
    attachment_files_with_app_segments: int = 0
    attachment_raw_hashes: set[str] = dataclasses.field(default_factory=set)
    attachment_written_hashes: set[str] = dataclasses.field(default_factory=set)
    unmapped_nonempty: collections.Counter[str] = dataclasses.field(
        default_factory=collections.Counter
    )


@dataclasses.dataclass
class VehicleSource:
    index: int
    label: str
    distance_unit: str
    volume_unit: str
    tank_capacity: str
    records: list[dict[str, str]]
    events: list[dict[str, str]] = dataclasses.field(default_factory=list)
    reminders: list[dict[str, str]] = dataclasses.field(default_factory=list)
    specification: dict[str, str] = dataclasses.field(default_factory=dict)


@dataclasses.dataclass
class ExportData:
    vehicles: list[VehicleSource]
    attachment_entries: list[dict[str, object]]


DECIMAL_RE = re.compile(r"^([+-]?)(?:(\d+)(?:\.(\d*))?|\.(\d+))$")
DATE_FORMAT = "%m/%d/%Y - %H:%M"

RECORD_FIELDS = {
    "date",
    "fuel-efficiency",
    "fuel-type-id",
    "notes",
    "odometer-reading",
    "payment-type",
    "partial",
    "previous-missed-fillups",
    "price-per-volume-unit",
    "total-cost",
    "volume",
    "has-fuel-additive",
    "fuel-additive-name",
    "driving-mode",
    "average-speed",
    "city-driving-percentage",
    "highway-driving-percentage",
    "tags",
    "place-name",
    "place-full-address",
    "place-street",
    "place-city",
    "place-state",
    "place-country",
    "place-postal-code",
    "place-google-places-id",
    "place-longitude",
    "place-latitude",
    "device-longitude",
    "device-latitude",
    "photos",
    "pdfs",
    "type",
}

VEHICLE_FIELDS = {
    "name",
    "distance-unit",
    "volume-unit",
    "fuel-tank-capacity",
    "active",
    "vehicle-id",
    "type",
    "make",
    "model",
    "sub-model",
    "year",
    "vin",
    "license-plate",
    "notes",
    "photo",
    "color",
    "engine",
    "transmission",
    "body-type",
    "bed-type",
    "drive-type",
    "insurance-policy",
    "country-name",
    "region-name",
    "city-name",
    "make-id",
    "model-id",
    "body-type-id",
    "bed-type-id",
    "drive-type-id",
    "engine-id",
    "transmission-id",
    "generic-engine-base-id",
    "generic-fuel-type-id",
    "country-id",
    "region-id",
}

ADDRESS_PARTS = (
    ("place-street", "newAddressLine1", "line1"),
    ("place-city", "newLocality", "locality"),
    ("place-state", "newRegion", "region"),
    ("place-postal-code", "newPostalCode", "postalCode"),
    ("place-country", "newCountry", "country"),
)

UNMAPPED_VEHICLE_FIELDS = {
    "active",
    "vehicle-id",
    "type",
    "insurance-policy",
    "country-name",
    "region-name",
    "city-name",
    "make-id",
    "model-id",
    "body-type-id",
    "bed-type-id",
    "drive-type-id",
    "engine-id",
    "transmission-id",
    "generic-engine-base-id",
    "generic-fuel-type-id",
    "country-id",
    "region-id",
}

VEHICLE_SPEC_FIELDS = {
    "vin": "specVin",
    "license-plate": "specPlate",
    "year": "specYear",
    "make": "specMake",
    "model": "specModel",
    "sub-model": "specSubModel",
    "body-type": "specBodyType",
    "color": "specColor",
    "engine": "specEngine",
    "transmission": "specTransmission",
    "drive-type": "specDriveType",
    "bed-type": "specBedType",
    "notes": "specNotes",
}

VEHICLE_SPEC_REPORT_LABELS = {
    "specVin": "VIN",
    "specPlate": "licence plate",
    "specYear": "model year",
    "specMake": "make",
    "specModel": "model",
    "specSubModel": "sub-model",
    "specBodyType": "body type",
    "specColor": "colour",
    "specEngine": "engine",
    "specTransmission": "transmission",
    "specDriveType": "drive type",
    "specBedType": "bed type",
    "specNotes": "notes",
}


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def text_trimmed(record: dict[str, str], key: str) -> str:
    return record.get(key, "").strip()


def parse_decimal(text: str) -> DecimalValue:
    if not isinstance(text, str):
        raise ConversionError("decimal input is not a string")
    match = DECIMAL_RE.fullmatch(text.strip())
    if match is None:
        raise ConversionError(f"invalid decimal syntax: {text!r}")
    sign_text, whole, fraction, leading_fraction = match.groups()
    if leading_fraction is not None:
        whole = "0"
        fraction = leading_fraction
    if fraction is None:
        fraction = ""
    digits = int((whole or "0") + fraction)
    sign = -1 if sign_text == "-" and digits else 1
    return DecimalValue(sign=sign, digits=digits, scale=len(fraction))


def quantized_integer(value: DecimalValue, target_scale: int) -> int:
    if target_scale < 0:
        raise ConversionError("negative decimal scale")
    if value.scale <= target_scale:
        magnitude = value.digits * (10 ** (target_scale - value.scale))
    else:
        divisor = 10 ** (value.scale - target_scale)
        magnitude, remainder = divmod(value.digits, divisor)
        if remainder * 2 >= divisor:
            magnitude += 1
    return value.sign * magnitude


def render_scaled(integer: int, scale: int) -> str:
    sign = "-" if integer < 0 else ""
    digits = str(abs(integer))
    if scale == 0:
        return sign + digits
    digits = digits.rjust(scale + 1, "0")
    return f"{sign}{digits[:-scale]}.{digits[-scale:]}"


def fixed_decimal(text: str, scale: int) -> str:
    return render_scaled(quantized_integer(parse_decimal(text), scale), scale)


def round_div_half_up(numerator: int, denominator: int) -> int:
    quotient, remainder = divmod(numerator, denominator)
    return quotient + int(remainder * 2 >= denominator)


def decimal_places(text: str) -> int:
    return parse_decimal(text).scale


def observed_start(text: str) -> str:
    try:
        parsed = datetime.datetime.strptime(text.strip(), DATE_FORMAT)
    except ValueError as exc:
        raise ConversionError(f"invalid aCar date shape: {text!r}") from exc
    return parsed.strftime("%Y-%m-%dT%H:%M")


def calendar_day(text: str) -> str:
    source = text.strip()
    parsed = None
    for shape in ("%m/%d/%Y", DATE_FORMAT):
        try:
            parsed = datetime.datetime.strptime(source, shape)
            break
        except ValueError:
            continue
    if parsed is None:
        raise ConversionError(f"invalid aCar calendar date: {text!r}")
    return parsed.strftime("%Y-%m-%d")


def record_ref(vehicle_dir: str, record: dict[str, str]) -> str:
    return f"{vehicle_dir}/{observed_start(text_trimmed(record, 'date'))}"


def split_list(text: str) -> list[str]:
    if not text.strip():
        return []
    return [item.strip() for item in text.split(",") if item.strip()]


def parse_bool(text: str, field: str) -> bool:
    value = text.strip().lower()
    if value == "true":
        return True
    if value == "false":
        return False
    raise ConversionError(f"{field} is not true/false")


def distance_unit_label(source_unit: str) -> str:
    mapping = {"mile": "mi", "kilometer": "km", "kilometre": "km"}
    try:
        return mapping[source_unit]
    except KeyError as exc:
        raise ConversionError(f"unsupported aCar distance unit: {source_unit!r}") from exc


def volume_profile(source_unit: str) -> tuple[str, str]:
    mapping = {
        "us_gallon": ("gal", "us-usd-gal"),
        "liter": ("litre", "eu-eur-litre"),
        "litre": ("litre", "eu-eur-litre"),
    }
    try:
        return mapping[source_unit]
    except KeyError as exc:
        raise ConversionError(f"unsupported aCar volume unit: {source_unit!r}") from exc


def profile_volume_unit(profile: str) -> str:
    if profile == "us-usd-gal":
        return "gal"
    if profile.endswith("-litre"):
        return "litre"
    raise ConversionError(f"unsupported Rover price profile: {profile!r}")


def check_import_units(
    *,
    vehicle_label: str,
    distance_unit: str,
    volume_unit: str,
    fills: list[dict[str, object]],
    stats: ReportStats,
) -> None:
    for fill in fills:
        record_name = f"{vehicle_label}/{fill['observed']}"
        mileage_unit = str(fill["mileageUnit"])
        if mileage_unit != distance_unit:
            stats.unit_mismatches += 1
            stats.unit_mismatch_details.append(
                f"{record_name}: distance {mileage_unit} != vehicle {distance_unit}"
            )
        fill_volume_unit = profile_volume_unit(str(fill["profile"]))
        if fill_volume_unit != volume_unit:
            stats.unit_mismatches += 1
            stats.unit_mismatch_details.append(
                f"{record_name}: volume {fill_volume_unit} != vehicle {volume_unit}"
            )


def category_label(category: str) -> str:
    known = {
        "diesel": "Diesel",
        "gasoline": "Gasoline",
        "bioalcohol": "Ethanol",
        "gas": "Gas",
        "electricity": "Electricity",
    }
    return known.get(category, category.replace("_", " ").title())


def check_total(
    name: str,
    quantity: str,
    price: str,
    source_total: str,
    stats: ReportStats,
    minor_unit_decimals: int = 2,
) -> int:
    if minor_unit_decimals < 0:
        raise ConversionError(f"{name}: negative minor-unit decimal count")
    quantity_value = parse_decimal(quantity)
    price_value = parse_decimal(price)
    if quantity_value.sign < 0 or price_value.sign < 0:
        raise ConversionError(f"{name}: negative quantity or price")
    quantity_milli = quantized_integer(quantity_value, 3)
    price_mills = quantized_integer(price_value, 3)
    product = quantity_milli * price_mills
    minor_scale = 10**minor_unit_decimals
    derived_minor_units = round_div_half_up(product * minor_scale, 1_000_000)
    source_minor_units = quantized_integer(
        parse_decimal(source_total), minor_unit_decimals
    )
    delta = derived_minor_units - source_minor_units
    absolute = abs(delta)
    stats.total_checks += 1
    if absolute == 0:
        stats.total_exact += 1
    elif absolute == 1:
        stats.total_within_cent += 1
        stats.total_mismatches.append(
            f"{name}: derived {render_scaled(derived_minor_units, minor_unit_decimals)}, "
            f"source {render_scaled(source_minor_units, minor_unit_decimals)}, "
            f"delta {delta:+d} minor unit"
        )
    else:
        stats.total_beyond += 1
        stats.total_mismatches.append(
            f"{name}: derived {render_scaled(derived_minor_units, minor_unit_decimals)}, "
            f"source {render_scaled(source_minor_units, minor_unit_decimals)}, "
            f"delta {delta:+d} minor units"
        )
    return delta


def aligned_difference(left: DecimalValue, right: DecimalValue) -> tuple[int, int]:
    scale = max(left.scale, right.scale)
    left_scaled = left.sign * left.digits * (10 ** (scale - left.scale))
    right_scaled = right.sign * right.digits * (10 ** (scale - right.scale))
    return left_scaled - right_scaled, scale


def rational_fixed(numerator: int, denominator: int, scale: int) -> str:
    if denominator <= 0:
        raise ConversionError("nonpositive rational denominator")
    sign = -1 if numerator < 0 else 1
    magnitude, remainder = divmod(abs(numerator) * (10**scale), denominator)
    if remainder * 2 >= denominator:
        magnitude += 1
    return render_scaled(sign * magnitude, scale)


def check_efficiencies(
    vehicle_dir: str, records: list[dict[str, str]], stats: ReportStats
) -> None:
    ordered = sorted(records, key=lambda item: observed_start(text_trimmed(item, "date")))
    for previous, current in zip(ordered, ordered[1:]):
        stats.efficiency_pairs += 1
        current_ref = record_ref(vehicle_dir, current)
        previous_odo = parse_decimal(text_trimmed(previous, "odometer-reading"))
        current_odo = parse_decimal(text_trimmed(current, "odometer-reading"))
        distance_digits, distance_scale = aligned_difference(current_odo, previous_odo)
        quantity = parse_decimal(text_trimmed(current, "volume"))
        if distance_digits <= 0 or quantity.sign < 0 or quantity.digits == 0:
            stats.efficiency_beyond += 1
            stats.efficiency_mismatches.append(
                f"{current_ref}: nonpositive odometer interval or volume"
            )
            continue
        source_text = text_trimmed(current, "fuel-efficiency")
        if not source_text:
            stats.efficiency_source_absent += 1
            continue
        stats.efficiency_source_comparisons += 1
        source = parse_decimal(source_text)
        derived_numerator = distance_digits * (10**quantity.scale)
        derived_denominator = (10**distance_scale) * quantity.digits
        difference_numerator = abs(
            derived_numerator * (10**source.scale)
            - source.sign * source.digits * derived_denominator
        )
        threshold_denominator = derived_denominator * (10**source.scale)
        if difference_numerator * 100 > threshold_denominator:
            stats.efficiency_beyond += 1
            stats.efficiency_mismatches.append(
                f"{current_ref}: derived "
                f"{rational_fixed(derived_numerator, derived_denominator, 3)} mpg, "
                f"source {source_text} mpg"
            )


def strip_jpeg_app_segments(data: bytes) -> bytes:
    if len(data) < 4 or data[:2] != b"\xff\xd8" or data[2] != 0xFF:
        raise ConversionError("photo is not a JPEG")
    output = bytearray(data[:2])
    offset = 2
    while offset < len(data):
        if data[offset] != 0xFF:
            raise ConversionError("malformed JPEG marker stream")
        marker_start = offset
        while offset < len(data) and data[offset] == 0xFF:
            offset += 1
        if offset >= len(data):
            raise ConversionError("truncated JPEG marker")
        marker = data[offset]
        offset += 1
        if marker == 0xDA:
            output.extend(data[marker_start:])
            return bytes(output)
        if marker in {0xD8, 0xD9, 0x01} or 0xD0 <= marker <= 0xD7:
            output.extend(data[marker_start:offset])
            if marker == 0xD9:
                return bytes(output)
            continue
        if offset + 2 > len(data):
            raise ConversionError("truncated JPEG segment length")
        segment_length = int.from_bytes(data[offset : offset + 2], "big")
        if segment_length < 2 or offset + segment_length > len(data):
            raise ConversionError("invalid JPEG segment length")
        segment_end = offset + segment_length
        if not 0xE0 <= marker <= 0xEF:
            output.extend(data[marker_start:segment_end])
        offset = segment_end
    raise ConversionError("JPEG has no scan or end marker")


def owner_jpeg_bytes(data: bytes) -> bytes:
    """Validate an owner attachment without altering its metadata."""
    if len(data) < 4 or data[:3] != b"\xff\xd8\xff":
        raise ConversionError("photo is not a JPEG")
    return data


def read_properties(path: pathlib.Path) -> dict[str, str]:
    properties: dict[str, str] = {}
    with path.open(encoding="utf-8-sig") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\r\n")
            if not line or line.lstrip().startswith(("#", "!")):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            properties[key.strip()] = (
                value.strip()
                .replace(r"\:", ":")
                .replace(r"\=", "=")
                .replace(r"\\", "\\")
            )
    return properties


def read_fuel_types(path: pathlib.Path) -> dict[str, FuelType]:
    fuel_types: dict[str, FuelType] = {}
    for _, element in ET.iterparse(path, events=("end",)):
        if local_name(element.tag) != "fuel-type":
            continue
        values = {
            local_name(child.tag): (child.text or "").strip() for child in element
        }
        fuel_id = element.attrib.get("id", "").strip()
        if not fuel_id:
            raise ConversionError("fuel type without an id")
        fuel_types[fuel_id] = FuelType(
            category=values.get("category", ""),
            name=values.get("name", ""),
            rating=values.get("rating", ""),
            rating_type=values.get("rating-type", ""),
        )
        element.clear()
    return fuel_types


def read_event_subtypes(path: pathlib.Path) -> dict[str, EventSubtype]:
    subtypes: dict[str, EventSubtype] = {}
    for _, element in ET.iterparse(path, events=("end",)):
        if local_name(element.tag) != "event-subtype":
            continue
        values = {
            local_name(child.tag): (child.text or "").strip() for child in element
        }
        source_id = element.attrib.get("id", "").strip()
        source_kind = element.attrib.get("type", "").strip()
        label = values.get("name", "")
        if not source_id or not label or source_kind not in {"service", "expense"}:
            raise ConversionError("event subtype lacks a supported id, type, or name")
        subtypes[source_id] = EventSubtype(
            source_id=source_id,
            label=label,
            source_kind=source_kind,
            default_distance_interval=values.get(
                "default-distance-reminder-interval", ""
            ),
            default_time_interval=values.get("default-time-reminder-interval", ""),
        )
        element.clear()
    return subtypes


def build_service_subtypes(
    source: dict[str, EventSubtype],
    *,
    distance_unit: str,
    stats: ReportStats,
) -> list[dict[str, object]]:
    by_label: dict[str, dict[str, object]] = {}
    for subtype in source.values():
        row: dict[str, object] = {"label": subtype.label}
        has_distance = bool(subtype.default_distance_interval)
        has_time = bool(subtype.default_time_interval)
        if has_distance != has_time:
            raise ConversionError(
                f"service subtype {subtype.label!r} has only half a default interval"
            )
        if has_distance:
            distance = parse_decimal(subtype.default_distance_interval)
            time = parse_decimal(subtype.default_time_interval)
            if distance.sign < 0 or time.sign < 0 or distance.scale or time.scale:
                raise ConversionError(
                    f"service subtype {subtype.label!r} has a non-integer default"
                )
            if distance.digits == 0 or time.digits == 0:
                raise ConversionError(
                    f"service subtype {subtype.label!r} has a zero default"
                )
            row.update(
                {
                    "defaultDistanceInterval": str(distance.digits),
                    "defaultDistanceUnit": distance_unit,
                    "defaultTimeInterval": str(time.digits),
                    "defaultTimeUnit": "month",
                }
            )
        previous = by_label.get(subtype.label)
        if previous is None:
            by_label[subtype.label] = row
        else:
            stats.event_subtype_duplicates += 1
            if len(row) > 1:
                if len(previous) > 1 and previous != row:
                    raise ConversionError(
                        f"duplicate service subtype {subtype.label!r} has conflicting defaults"
                    )
                by_label[subtype.label] = row
    rows = [by_label[label] for label in sorted(by_label)]
    stats.event_subtypes_out = len(rows)
    stats.event_subtype_defaults = sum(len(row) > 1 for row in rows)
    return rows


def load_corrections(export_dir: pathlib.Path) -> dict[str, Correction]:
    path = export_dir / "corrections.json"
    if not path.is_file():
        return {}
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ConversionError(f"{path.name}: invalid JSON") from exc
    if (
        not isinstance(document, dict)
        or document.get("rover-corrections") != 1
        or document.get("source-app") != "acar"
        or not isinstance(document.get("corrections"), list)
    ):
        raise ConversionError(f"{path.name}: unsupported correction document")
    corrections: dict[str, Correction] = {}
    for index, item in enumerate(document["corrections"], start=1):
        if not isinstance(item, dict):
            raise ConversionError(f"{path.name}: correction {index} is not an object")
        required = (
            "source-record-id",
            "field",
            "from",
            "to",
            "from-label",
            "to-label",
            "reason",
        )
        if any(not isinstance(item.get(key), str) or not item[key] for key in required):
            raise ConversionError(
                f"{path.name}: correction {index} lacks a required string"
            )
        correction = Correction(
            source_record_id=item["source-record-id"],
            field=item["field"],
            before=item["from"],
            after=item["to"],
            before_label=item["from-label"],
            after_label=item["to-label"],
            reason=item["reason"],
        )
        if correction.source_record_id in corrections:
            raise ConversionError(
                f"{path.name}: duplicate source-record-id at correction {index}"
            )
        corrections[correction.source_record_id] = correction
    return corrections


def apply_record_correction(
    record: dict[str, str],
    *,
    corrections: dict[str, Correction],
    record_name: str,
    stats: ReportStats,
) -> None:
    source_record_id = text_trimmed(record, "_remote_id")
    correction = corrections.get(source_record_id)
    if correction is None:
        return
    current = record.get(correction.field, "")
    if current != correction.before:
        raise ConversionError(
            f"{record_name}: stale correction {correction.before_label!r} -> "
            f"{correction.after_label!r} expected {correction.field} "
            f"{correction.before!r}, found {current!r}"
        )
    record[correction.field] = correction.after
    stats.corrections_applied.append(
        f"{record_name}: {correction.before_label} -> {correction.after_label}; "
        f"{correction.reason}"
    )


def count_elements(path: pathlib.Path, wanted: str) -> int:
    count = 0
    for _, element in ET.iterparse(path, events=("end",)):
        if local_name(element.tag) == wanted:
            count += 1
        element.clear()
    return count


def coordinate_measurement(record: dict[str, str], stats: ReportStats) -> None:
    for prefix in ("place", "device"):
        latitude = text_trimmed(record, f"{prefix}-latitude")
        longitude = text_trimmed(record, f"{prefix}-longitude")
        if bool(latitude) != bool(longitude):
            raise ConversionError(f"{prefix} coordinate pair is incomplete")
        if not latitude:
            continue
        stats.coordinate_values += 2
        over = sum(decimal_places(value) > 7 for value in (latitude, longitude))
        stats.coordinate_values_over_scale += over
        if prefix == "place":
            stats.place_coordinate_pairs += 1
            stats.place_coordinate_values_rounded += over
        else:
            stats.device_coordinate_pairs += 1
            stats.device_coordinate_values_rounded += over


def extract_attachments(
    photo_text: str,
    *,
    vehicle_label: str,
    vehicle_dir: str,
    record: dict[str, str],
    record_kind: str,
    output_dir: pathlib.Path,
    dry_run: bool,
    stats: ReportStats,
    entries: list[dict[str, object]],
    filenames: set[str],
) -> None:
    photos = split_list(photo_text)
    if not photos:
        return
    stats.attachment_records += 1
    observed = observed_start(text_trimmed(record, "date"))
    safe_observed = observed.replace(":", "-")
    remote_id = text_trimmed(record, "_remote_id")
    if not remote_id:
        raise ConversionError(f"{vehicle_dir}/{observed}: photo record has no remote-id")
    for ordinal, encoded in enumerate(photos, start=1):
        compact = "".join(encoded.split())
        try:
            raw = base64.b64decode(compact, validate=True)
        except (ValueError, base64.binascii.Error) as exc:
            raise ConversionError(f"{vehicle_dir}/{observed}: invalid photo base64") from exc
        if raw[:3] != b"\xff\xd8\xff":
            raise ConversionError(f"{vehicle_dir}/{observed}: photo is not JPEG")
        written = owner_jpeg_bytes(raw)
        raw_hash = hashlib.sha256(raw).hexdigest()
        written_hash = hashlib.sha256(written).hexdigest()
        relative = pathlib.PurePosixPath(vehicle_dir) / (
            f"{safe_observed}-{ordinal}-{written_hash[:12]}.jpg"
        )
        relative_text = relative.as_posix()
        if relative_text in filenames:
            raise ConversionError(f"attachment filename collision: {relative_text}")
        filenames.add(relative_text)
        if not dry_run:
            destination = output_dir / pathlib.Path(relative_text)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(written)
        entries.append(
            {
                "bytes": len(written),
                "file": relative_text,
                "odometer": fixed_decimal(
                    text_trimmed(record, "odometer-reading"), 1
                ),
                "observed-start": observed,
                "ordinal": ordinal,
                "record-kind": record_kind,
                "sha256": written_hash,
                "vehicle": vehicle_label,
            }
        )
        stats.attachments += 1
        stats.attachment_raw_bytes += len(raw)
        stats.attachment_written_bytes += len(written)
        stats.attachment_raw_hashes.add(raw_hash)
        stats.attachment_written_hashes.add(written_hash)
        stats.attachment_files_with_app_segments += int(raw != written)
        if record_kind == "fill":
            stats.attachment_fill_count += 1
        elif record_kind == "event":
            stats.attachment_event_count += 1
        else:
            stats.attachment_vehicle_count += 1


def extract_vehicle_attachment(
    photo_text: str,
    *,
    vehicle_label: str,
    vehicle_dir: str,
    output_dir: pathlib.Path,
    dry_run: bool,
    stats: ReportStats,
    entries: list[dict[str, object]],
    filenames: set[str],
) -> None:
    if not photo_text.strip():
        return
    compact = "".join(photo_text.split())
    try:
        raw = base64.b64decode(compact, validate=True)
    except (ValueError, base64.binascii.Error) as exc:
        raise ConversionError(f"{vehicle_dir}: invalid vehicle photo base64") from exc
    written = owner_jpeg_bytes(raw)
    digest = hashlib.sha256(written).hexdigest()
    relative = pathlib.PurePosixPath(vehicle_dir) / f"vehicle-{digest[:12]}.jpg"
    relative_text = relative.as_posix()
    if relative_text in filenames:
        raise ConversionError(f"attachment filename collision: {relative_text}")
    filenames.add(relative_text)
    if not dry_run:
        destination = output_dir / pathlib.Path(relative_text)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(written)
    entries.append(
        {
            "bytes": len(written),
            "file": relative_text,
            "ordinal": 1,
            "record-kind": "vehicle",
            "sha256": digest,
            "vehicle": vehicle_label,
        }
    )
    stats.attachments += 1
    stats.attachment_records += 1
    stats.attachment_vehicle_count += 1
    stats.attachment_raw_bytes += len(raw)
    stats.attachment_written_bytes += len(written)
    stats.attachment_raw_hashes.add(hashlib.sha256(raw).hexdigest())
    stats.attachment_written_hashes.add(digest)


def read_vehicles(
    path: pathlib.Path,
    output_dir: pathlib.Path,
    dry_run: bool,
    stats: ReportStats,
    corrections: dict[str, Correction],
) -> ExportData:
    vehicles: list[VehicleSource] = []
    attachment_entries: list[dict[str, object]] = []
    attachment_filenames: set[str] = set()
    stack: list[str] = []
    vehicle_values: dict[str, str] | None = None
    vehicle_records: list[dict[str, str]] | None = None
    vehicle_events: list[dict[str, str]] | None = None
    vehicle_reminders: list[dict[str, str]] | None = None
    vehicle_index = 0
    record: dict[str, str] | None = None
    record_kind = ""
    reminder: dict[str, str] | None = None

    for event, element in ET.iterparse(path, events=("start", "end")):
        tag = local_name(element.tag)
        if event == "start":
            stack.append(tag)
            if tag == "vehicle":
                vehicle_index += 1
                vehicle_values = {}
                vehicle_records = []
                vehicle_events = []
                vehicle_reminders = []
            elif tag in {"fillup-record", "event-record"}:
                record = {}
                record_kind = "fill" if tag == "fillup-record" else "event"
            elif tag == "reminder":
                reminder = {
                    "_source_id": element.attrib.get("id", "").strip(),
                    "event-subtype-id": element.attrib.get(
                        "event-subtype-id", ""
                    ).strip(),
                    "event-type": element.attrib.get("event-type", "").strip(),
                }
            continue

        parent = stack[-2] if len(stack) >= 2 else ""
        grandparent = stack[-3] if len(stack) >= 3 else ""
        raw_text = element.text or ""

        if record is not None:
            if parent in {"fillup-record", "event-record"} and tag in RECORD_FIELDS:
                record[tag] = raw_text
                element.clear()
            elif (
                tag == "remote-id"
                and parent == "sync-metadata"
                and grandparent in {"fillup-record", "event-record"}
            ):
                record["_remote_id"] = raw_text.strip()
                element.clear()
            elif tag == "subtype" and parent == "subtypes":
                source_id = element.attrib.get("id", "").strip()
                if not source_id:
                    raise ConversionError("event subtype link has no id")
                current = record.get("_subtype_ids", "")
                record["_subtype_ids"] = ",".join(
                    value for value in (current, source_id) if value
                )
                element.clear()

        if reminder is not None and parent == "reminder":
            reminder[tag] = raw_text
            element.clear()

        if tag in {"fillup-record", "event-record"}:
            if record is None or vehicle_values is None or vehicle_records is None:
                raise ConversionError("record found outside a vehicle")
            coordinate_measurement(record, stats)
            if "pdfs" in record:
                stats.pdf_tags += 1
                stats.nonempty_pdfs += int(bool(text_trimmed(record, "pdfs")))
            label = vehicle_values.get("name", "")
            if not label:
                raise ConversionError(f"vehicle-{vehicle_index} has no name")
            apply_record_correction(
                record,
                corrections=corrections,
                record_name=f"{label}/{observed_start(text_trimmed(record, 'date'))}",
                stats=stats,
            )
            photo_text = record.pop("photos", "")
            extract_attachments(
                photo_text,
                vehicle_label=label,
                vehicle_dir=f"vehicle-{vehicle_index}",
                record=record,
                record_kind=record_kind,
                output_dir=output_dir,
                dry_run=dry_run,
                stats=stats,
                entries=attachment_entries,
                filenames=attachment_filenames,
            )
            if record_kind == "fill":
                stats.fills_in += 1
                vehicle_records.append(record)
            else:
                stats.event_records += 1
                if vehicle_events is None:
                    raise ConversionError("event found outside a vehicle")
                vehicle_events.append(record)
            record = None
            record_kind = ""
            element.clear()

        elif tag == "reminder":
            if reminder is None or vehicle_reminders is None:
                raise ConversionError("reminder found outside a vehicle")
            stats.reminders += 1
            vehicle_reminders.append(reminder)
            reminder = None
            element.clear()
        elif tag == "trip-record":
            stats.trip_records += 1
            element.clear()
        elif (
            vehicle_values is not None
            and record is None
            and parent == "vehicle"
            and tag in VEHICLE_FIELDS
        ):
            vehicle_values[tag] = raw_text
            element.clear()
        elif tag == "vehicle":
            if (
                vehicle_values is None
                or vehicle_records is None
                or vehicle_events is None
                or vehicle_reminders is None
            ):
                raise ConversionError("malformed vehicle element")
            label = vehicle_values.get("name", "")
            distance_unit = vehicle_values.get("distance-unit", "").strip()
            volume_unit = vehicle_values.get("volume-unit", "").strip()
            if not label or not distance_unit or not volume_unit:
                raise ConversionError(f"vehicle-{vehicle_index} lacks required metadata")
            extract_vehicle_attachment(
                vehicle_values.get("photo", ""),
                vehicle_label=label,
                vehicle_dir=f"vehicle-{vehicle_index}",
                output_dir=output_dir,
                dry_run=dry_run,
                stats=stats,
                entries=attachment_entries,
                filenames=attachment_filenames,
            )
            for field in UNMAPPED_VEHICLE_FIELDS:
                if vehicle_values.get(field, "").strip():
                    stats.unmapped_nonempty[f"vehicle.{field}"] += 1
            vehicles.append(
                VehicleSource(
                    index=vehicle_index,
                    label=label,
                    distance_unit=distance_unit,
                    volume_unit=volume_unit,
                    tank_capacity=vehicle_values.get("fuel-tank-capacity", "").strip(),
                    records=vehicle_records,
                    events=vehicle_events,
                    reminders=vehicle_reminders,
                    specification={
                        field: vehicle_values.get(field, "").strip()
                        for field in VEHICLE_SPEC_FIELDS
                    },
                )
            )
            stats.vehicles += 1
            vehicle_values = None
            vehicle_records = None
            vehicle_events = None
            vehicle_reminders = None
            element.clear()

        stack.pop()

    return ExportData(
        vehicles=vehicles,
        attachment_entries=sorted(
            attachment_entries, key=lambda item: str(item["file"])
        ),
    )


def resolve_place_label(record: dict[str, str]) -> str:
    label = text_trimmed(record, "place-name")
    if label:
        return label
    formatted = text_trimmed(record, "place-full-address")
    has_parts = any(
        text_trimmed(record, source) for source, _, _ in ADDRESS_PARTS
    )
    has_coordinates = bool(
        text_trimmed(record, "place-latitude")
        or text_trimmed(record, "place-longitude")
    )
    has_google_id = bool(text_trimmed(record, "place-google-places-id"))
    if formatted and not (has_parts or has_coordinates or has_google_id):
        return ""
    if not (formatted or has_parts or has_coordinates or has_google_id):
        return ""
    raise ConversionError("place evidence has no source label and cannot be matched")


def convert_fill(
    *,
    record: dict[str, str],
    vehicle_label: str,
    vehicle_dir: str,
    distance_unit: str,
    volume_unit: str,
    fuel_types: dict[str, FuelType],
    zone: str,
    stats: ReportStats,
) -> dict[str, object]:
    fuel_id = text_trimmed(record, "fuel-type-id")
    try:
        fuel = fuel_types[fuel_id]
    except KeyError as exc:
        raise ConversionError(f"{record_ref(vehicle_dir, record)}: unknown fuel type") from exc
    rover_distance = distance_unit_label(distance_unit)
    _, profile = volume_profile(volume_unit)
    quantity = fixed_decimal(text_trimmed(record, "volume"), 3)
    price = fixed_decimal(text_trimmed(record, "price-per-volume-unit"), 3)
    source_total = text_trimmed(record, "total-cost")
    if not source_total:
        raise ConversionError(f"{record_ref(vehicle_dir, record)}: total-cost absent")
    check_total(
        record_ref(vehicle_dir, record),
        quantity=quantity,
        price=price,
        source_total=source_total,
        stats=stats,
    )
    partial = parse_bool(text_trimmed(record, "partial"), "partial")
    missed = parse_bool(
        text_trimmed(record, "previous-missed-fillups"),
        "previous-missed-fillups",
    )
    payment = text_trimmed(record, "payment-type")
    fill: dict[str, object] = {
        "additives": [],
        "definition": category_label(fuel.category),
        "drivingMode": text_trimmed(record, "driving-mode"),
        "mileage": fixed_decimal(text_trimmed(record, "odometer-reading"), 1),
        "mileageUnit": rover_distance,
        "missedFill": "yes" if missed else "no",
        "observed": observed_start(text_trimmed(record, "date")),
        "price": price,
        "profile": profile,
        "quantity": quantity,
        "settlement": "cash" if payment == "Cash" else "standard",
        "sourceApp": "acar",
        "sourceRecordId": text_trimmed(record, "_remote_id"),
        "sourceTotal": source_total,
        "station": "none",
        "subtype": fuel.name,
        "tags": [],
        "tank": "partial" if partial else "full",
        "vehicle": vehicle_label,
        "zone": zone,
    }
    if not fill["sourceRecordId"]:
        raise ConversionError(f"{record_ref(vehicle_dir, record)}: remote-id absent")

    source_efficiency = text_trimmed(record, "fuel-efficiency")
    if source_efficiency:
        fill["sourceEfficiency"] = source_efficiency

    if parse_bool(
        text_trimmed(record, "has-fuel-additive"), "has-fuel-additive"
    ):
        additive = text_trimmed(record, "fuel-additive-name")
        if not additive:
            raise ConversionError(
                f"{record_ref(vehicle_dir, record)}: additive flag has no name"
            )
        fill["additives"] = [additive]

    speed = text_trimmed(record, "average-speed")
    if speed:
        fill["averageSpeed"] = speed
        fill["speedUnit"] = "mph" if rover_distance == "mi" else "kmh"

    city = text_trimmed(record, "city-driving-percentage")
    highway = text_trimmed(record, "highway-driving-percentage")
    if bool(city) != bool(highway):
        raise ConversionError(
            f"{record_ref(vehicle_dir, record)}: incomplete drive balance"
        )
    if city:
        city_value = quantized_integer(parse_decimal(city), 0)
        highway_value = quantized_integer(parse_decimal(highway), 0)
        if city_value + highway_value != 100:
            raise ConversionError(
                f"{record_ref(vehicle_dir, record)}: drive balance does not sum to 100"
            )
        fill["driveBalance"] = str(highway_value)

    tags = []
    for tag in split_list(record.get("tags", "")):
        if tag == "deleted":
            stats.deleted_tags_suppressed += 1
        else:
            tags.append(tag)
    fill["tags"] = tags

    notes = record.get("notes", "")
    if notes.strip():
        fill["notes"] = notes
        stats.notes_imported += 1
    if payment:
        fill["paymentMethod"] = payment

    place_label = resolve_place_label(record)
    formatted = text_trimmed(record, "place-full-address")
    parts = {
        payload_key: text_trimmed(record, source_key)
        for source_key, payload_key, _ in ADDRESS_PARTS
        if text_trimmed(record, source_key)
    }
    if parts and not formatted:
        stats.parts_only_addresses += 1
    latitude = text_trimmed(record, "place-latitude")
    longitude = text_trimmed(record, "place-longitude")
    if place_label:
        fill.update(
            {
                "station": "new",
                "newStationLabel": place_label,
                "newPlaceLabel": place_label,
                "newStationKind": "fuel",
            }
        )
        if formatted:
            fill["newAddressFormatted"] = formatted
        fill.update(parts)
        if latitude:
            fill["newLatitude"] = fixed_decimal(latitude, 7)
            fill["newLongitude"] = fixed_decimal(longitude, 7)
    elif formatted:
        stats.unlabelled_station_addresses.append(formatted)
    elif parts or latitude or longitude:
        raise ConversionError(
            f"{record_ref(vehicle_dir, record)}: location evidence has no place"
        )

    stats.fills_out += 1
    return fill


def convert_event(
    *,
    record: dict[str, str],
    expected_kind: str,
    vehicle_label: str,
    distance_unit: str,
    event_subtypes: dict[str, EventSubtype],
    zone: str,
    stats: ReportStats,
) -> dict[str, object]:
    source_kind = text_trimmed(record, "type")
    if source_kind != expected_kind:
        raise ConversionError(
            f"event section {expected_kind!r} contains {source_kind!r}"
        )
    source_record_id = text_trimmed(record, "_remote_id")
    if not source_record_id:
        raise ConversionError("event record has no remote-id")
    output: dict[str, object] = {
        "currency": "usd",
        "mileage": fixed_decimal(text_trimmed(record, "odometer-reading"), 1),
        "mileageUnit": distance_unit,
        "observed": observed_start(text_trimmed(record, "date")),
        "sourceApp": "acar",
        "sourceRecordId": source_record_id,
        "station": "none",
        "subtypes": [],
        "tags": [],
        "vehicle": vehicle_label,
        "zone": zone,
    }
    total_text = text_trimmed(record, "total-cost")
    if total_text:
        total = parse_decimal(total_text)
        if total.sign < 0:
            raise ConversionError("event total is negative")
        if total.digits:
            output["total"] = render_scaled(total.digits, total.scale)
            if expected_kind == "note":
                stats.note_events_with_cost += 1
    subtype_labels: list[str] = []
    for source_id in split_list(record.get("_subtype_ids", "")):
        try:
            subtype = event_subtypes[source_id]
        except KeyError as exc:
            raise ConversionError("event references an unknown subtype") from exc
        subtype_labels.append(subtype.label)
    if expected_kind != "service" and subtype_labels:
        raise ConversionError(f"{expected_kind} event carries service subtypes")
    output["subtypes"] = sorted(set(subtype_labels))
    output["tags"] = sorted(
        {
            tag
            for tag in split_list(record.get("tags", ""))
            if tag != "deleted"
        }
    )
    place_label = resolve_place_label(record)
    if place_label:
        output["station"] = place_label
    notes = record.get("notes", "")
    if notes.strip():
        output["notes"] = notes
    payment = text_trimmed(record, "payment-type")
    if payment:
        output["paymentMethod"] = payment
    if expected_kind == "service":
        stats.service_events_out += 1
    elif expected_kind == "note":
        stats.note_events_out += 1
    return output


def reminder_time_unit(source: str) -> str:
    mapping = {
        "day": "day",
        "days": "day",
        "week": "week",
        "weeks": "week",
        "month": "month",
        "months": "month",
        "year": "year",
        "years": "year",
    }
    try:
        return mapping[source.strip().lower()]
    except KeyError as exc:
        raise ConversionError(f"unsupported reminder time unit: {source!r}") from exc


def convert_reminder(
    *,
    source: dict[str, str],
    vehicle_label: str,
    distance_unit: str,
    event_subtypes: dict[str, EventSubtype],
    stats: ReportStats,
) -> dict[str, object]:
    if text_trimmed(source, "event-type") != "service":
        raise ConversionError("only service reminders have a Rover target")
    try:
        subtype = event_subtypes[text_trimmed(source, "event-subtype-id")]
    except KeyError as exc:
        raise ConversionError("reminder references an unknown subtype") from exc
    output: dict[str, object] = {
        "subtype": subtype.label,
        "vehicle": vehicle_label,
    }
    distance_interval = text_trimmed(source, "distance-interval")
    distance_due = text_trimmed(source, "distance-due")
    if bool(distance_interval) != bool(distance_due):
        raise ConversionError("reminder has only half a distance interval")
    if distance_interval:
        output.update(
            {
                "distanceInterval": render_scaled(
                    parse_decimal(distance_interval).digits,
                    parse_decimal(distance_interval).scale,
                ),
                "distanceDue": render_scaled(
                    parse_decimal(distance_due).digits,
                    parse_decimal(distance_due).scale,
                ),
                "distanceUnit": distance_unit,
            }
        )
    time_interval = text_trimmed(source, "time-interval")
    time_due = text_trimmed(source, "time-due")
    if bool(time_interval) != bool(time_due):
        raise ConversionError("reminder has only half a time interval")
    if time_interval:
        parsed = parse_decimal(time_interval)
        if parsed.sign < 0 or parsed.scale or parsed.digits == 0:
            raise ConversionError("reminder time interval is not a positive integer")
        output.update(
            {
                "timeInterval": str(parsed.digits),
                "timeUnit": reminder_time_unit(text_trimmed(source, "time-unit")),
                "timeDue": calendar_day(time_due),
            }
        )
    if len(output) == 2:
        raise ConversionError("reminder has no interval")
    stats.reminders_out += 1
    return output


def convert_vehicle_specification(values: dict[str, str]) -> dict[str, str]:
    output = {
        target: values.get(source, "").strip()
        for source, target in VEHICLE_SPEC_FIELDS.items()
        if values.get(source, "").strip()
    }
    year = output.get("specYear")
    if year:
        parsed = parse_decimal(year)
        if parsed.sign < 0 or parsed.scale or parsed.digits == 0:
            raise ConversionError("vehicle model year is not a positive integer")
        output["specYear"] = str(parsed.digits)
    return output


def build_places(vehicles: list[VehicleSource]) -> list[dict[str, object]]:
    accumulated: dict[str, dict[str, object]] = {}
    for vehicle in vehicles:
        sources = [(record, "fuel") for record in vehicle.records]
        sources.extend((record, "private") for record in vehicle.events)
        for record, station_kind in sources:
            label = resolve_place_label(record)
            if not label:
                continue
            place = accumulated.setdefault(
                label, {"label": label, "stationKind": station_kind}
            )
            if place["stationKind"] != station_kind:
                place["stationKind"] = "mixed"
            formatted = text_trimmed(record, "place-full-address")
            source_parts = {
                output_key: text_trimmed(record, source_key)
                for source_key, _, output_key in ADDRESS_PARTS
                if text_trimmed(record, source_key)
            }
            if formatted or source_parts:
                address = place.setdefault("address", {})
                if formatted:
                    address.setdefault("formatted", formatted)
                if source_parts:
                    parts = address.setdefault("parts", {})
                    for key, value in source_parts.items():
                        parts.setdefault(key, value)
            latitude = text_trimmed(record, "place-latitude")
            if latitude and "coordinates" not in place:
                place["coordinates"] = {
                    "lat": fixed_decimal(latitude, 7),
                    "lon": fixed_decimal(
                        text_trimmed(record, "place-longitude"), 7
                    ),
                    "source": "directory",
                }
    return [accumulated[label] for label in sorted(accumulated)]


def build_definitions(
    vehicles: list[VehicleSource],
    fuel_types: dict[str, FuelType],
) -> dict[str, list[dict[str, object]]]:
    used_fuels: dict[str, FuelType] = {}
    additives: set[str] = set()
    modes: set[str] = set()
    tags: set[str] = set()
    payment_methods: set[str] = set()
    volume_units: dict[str, set[str]] = collections.defaultdict(set)

    for vehicle in vehicles:
        quantity_unit, _ = volume_profile(vehicle.volume_unit)
        for record in vehicle.records:
            fuel_id = text_trimmed(record, "fuel-type-id")
            if fuel_id not in fuel_types:
                raise ConversionError("record references unknown fuel type")
            used_fuels[fuel_id] = fuel_types[fuel_id]
            volume_units[fuel_types[fuel_id].category].add(quantity_unit)
            if parse_bool(
                text_trimmed(record, "has-fuel-additive"), "has-fuel-additive"
            ):
                additive = text_trimmed(record, "fuel-additive-name")
                if additive:
                    additives.add(additive)
            mode = text_trimmed(record, "driving-mode")
            if mode:
                modes.add(mode)
            tags.update(tag for tag in split_list(record.get("tags", "")) if tag != "deleted")
            payment = text_trimmed(record, "payment-type")
            if payment:
                payment_methods.add(payment)
        for record in vehicle.events:
            tags.update(tag for tag in split_list(record.get("tags", "")) if tag != "deleted")
            payment = text_trimmed(record, "payment-type")
            if payment:
                payment_methods.add(payment)

    grouped: dict[str, list[FuelType]] = collections.defaultdict(list)
    for fuel in used_fuels.values():
        grouped[fuel.category].append(fuel)
    energy: list[dict[str, object]] = []
    for category in sorted(grouped, key=category_label):
        units = volume_units[category]
        if len(units) != 1:
            raise ConversionError(
                f"energy definition {category!r} has multiple quantity units"
            )
        subtypes: list[dict[str, object]] = []
        for fuel in sorted(grouped[category], key=lambda item: item.name):
            subtype: dict[str, object] = {"label": fuel.name}
            if fuel.rating_type == "cetane" and fuel.rating:
                subtype["cetane"] = fuel.rating
            elif fuel.rating_type in {"octane_aki", "octane_ron"} and fuel.rating:
                subtype["octane"] = fuel.rating
                subtype["method"] = fuel.rating_type.removeprefix("octane_")
            elif fuel.rating_type or fuel.rating:
                raise ConversionError(
                    f"unsupported rating shape for fuel subtype {fuel.name!r}"
                )
            subtypes.append(subtype)
        energy.append(
            {
                "label": category_label(category),
                "physicalKind": "reservoir",
                "quantityUnit": next(iter(units)),
                "subtypes": subtypes,
            }
        )

    simple = lambda labels: [{"label": label} for label in sorted(labels)]
    return {
        "additives": simple(additives),
        "driving-modes": simple(modes),
        "energy": energy,
        "payment-methods": simple(payment_methods),
        "tags": simple(tags),
    }


def count_record_unmapped(vehicles: list[VehicleSource], stats: ReportStats) -> None:
    for vehicle in vehicles:
        for kind, records in (("fill", vehicle.records), ("event", vehicle.events)):
            for record in records:
                if text_trimmed(record, "place-google-places-id"):
                    stats.unmapped_nonempty[
                        f"{kind}.place-google-places-id"
                    ] += 1
                if text_trimmed(record, "device-latitude"):
                    stats.unmapped_nonempty[f"{kind}.device-coordinate-pair"] += 1


def make_import_document(
    *,
    metadata: dict[str, str],
    vehicles: list[VehicleSource],
    fuel_types: dict[str, FuelType],
    event_subtypes: dict[str, EventSubtype],
    zone: str,
    stats: ReportStats,
) -> dict[str, object]:
    definitions = build_definitions(vehicles, fuel_types)
    stats.fuel_types_out = sum(
        len(definition["subtypes"]) for definition in definitions["energy"]
    )
    distance_units = {distance_unit_label(vehicle.distance_unit) for vehicle in vehicles}
    if len(distance_units) != 1 and any(
        subtype.default_distance_interval for subtype in event_subtypes.values()
    ):
        raise ConversionError(
            "subtype distance defaults are ambiguous across vehicle distance units"
        )
    default_distance_unit = next(iter(distance_units), "mi")
    definitions["service-subtypes"] = build_service_subtypes(
        event_subtypes,
        distance_unit=default_distance_unit,
        stats=stats,
    )
    places = build_places(vehicles)
    output_vehicles: list[dict[str, object]] = []
    for vehicle in vehicles:
        rover_distance = distance_unit_label(vehicle.distance_unit)
        quantity_unit, _ = volume_profile(vehicle.volume_unit)
        output_vehicle: dict[str, object] = {
            "distanceUnit": rover_distance,
            "fills": [],
            "label": vehicle.label,
            "noteEvents": [],
            "reminders": [],
            "serviceEvents": [],
            "specification": convert_vehicle_specification(vehicle.specification),
            "volumeUnit": quantity_unit,
        }
        if output_vehicle["specification"]:
            stats.vehicle_specifications += 1
            stats.vehicle_spec_fields.update(output_vehicle["specification"].keys())
        if vehicle.tank_capacity:
            capacity = parse_decimal(vehicle.tank_capacity)
            if capacity.digits:
                output_vehicle["tankSize"] = {
                    "unit": quantity_unit,
                    "value": render_scaled(
                        capacity.sign * capacity.digits, capacity.scale
                    ),
                }
        fills = [
            convert_fill(
                record=record,
                vehicle_label=vehicle.label,
                vehicle_dir=f"vehicle-{vehicle.index}",
                distance_unit=vehicle.distance_unit,
                volume_unit=vehicle.volume_unit,
                fuel_types=fuel_types,
                zone=zone,
                stats=stats,
            )
            for record in vehicle.records
        ]
        output_vehicle["fills"] = fills
        for record in vehicle.events:
            kind = text_trimmed(record, "type")
            if kind == "service":
                output_vehicle["serviceEvents"].append(
                    convert_event(
                        record=record,
                        expected_kind="service",
                        vehicle_label=vehicle.label,
                        distance_unit=rover_distance,
                        event_subtypes=event_subtypes,
                        zone=zone,
                        stats=stats,
                    )
                )
            elif kind == "note":
                output_vehicle["noteEvents"].append(
                    convert_event(
                        record=record,
                        expected_kind="note",
                        vehicle_label=vehicle.label,
                        distance_unit=rover_distance,
                        event_subtypes=event_subtypes,
                        zone=zone,
                        stats=stats,
                    )
                )
            else:
                stats.expense_events_unmapped += 1
        output_vehicle["reminders"] = [
            convert_reminder(
                source=reminder,
                vehicle_label=vehicle.label,
                distance_unit=rover_distance,
                event_subtypes=event_subtypes,
                stats=stats,
            )
            for reminder in vehicle.reminders
        ]
        check_import_units(
            vehicle_label=vehicle.label,
            distance_unit=rover_distance,
            volume_unit=quantity_unit,
            fills=fills,
            stats=stats,
        )
        referenced = collections.Counter(
            str(fill["definition"]) for fill in fills
        )
        if not referenced:
            raise ConversionError(
                f"vehicle {vehicle.label!r} references no energy definition; "
                "defaultEnergy is required"
            )
        if len(referenced) > 1:
            split = ", ".join(
                f"{label}={count}" for label, count in sorted(referenced.items())
            )
            raise ConversionError(
                f"vehicle {vehicle.label!r} references multiple energy definitions: "
                f"{split}; defaultEnergy cannot be inferred"
            )
        output_vehicle["defaultEnergy"] = next(iter(referenced))
        check_efficiencies(f"vehicle-{vehicle.index}", vehicle.records, stats)
        output_vehicles.append(output_vehicle)

    count_record_unmapped(vehicles, stats)
    try:
        backup_version = int(metadata["acar.backup.version"])
        source_version = metadata["acar.version"]
        exported = metadata["acar.backup.datetime"]
    except (KeyError, ValueError) as exc:
        raise ConversionError("metadata.inf lacks valid aCar source metadata") from exc
    return {
        "definitions": definitions,
        "places": places,
        "rover-import": 1,
        "source": {
            "app": "aCar",
            "backup-version": backup_version,
            "exported": exported,
            "version": source_version,
        },
        "vehicles": output_vehicles,
    }


def json_bytes(value: object) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def render_report(
    *,
    document: dict[str, object],
    stats: ReportStats,
    dry_run: bool,
) -> str:
    definitions = document["definitions"]
    if not isinstance(definitions, dict):
        raise ConversionError("internal definitions shape error")
    places = document["places"]
    lines = [
        "Rover aCar conversion report",
        f"Mode: {'dry-run' if dry_run else 'write'}",
        "",
        "Records",
        f"Vehicles in/out: {stats.vehicles}/{len(document['vehicles'])}",
        f"Fills in/out/dropped: {stats.fills_in}/{stats.fills_out}/{stats.fills_dropped}",
        f"Service events imported: {stats.service_events_out}",
        f"Note events imported: {stats.note_events_out}",
        f"Expense events not imported: {stats.expense_events_unmapped} (Rover T9 carries service and note history; every expense remains named here)",
        f"Note events with a nonzero total kept as notes: {stats.note_events_with_cost} (the source kind is authoritative; the entered total was retained)",
        f"Trip records not imported: {stats.trip_records} (Rover has no trip-record model)",
        f"Reminders imported: {stats.reminders_out}",
        f"Trip types not imported: {stats.trip_types} (aCar defaults carry tax-deduction rates Rover does not model)",
        f"Source subtype definitions processed: {stats.event_subtypes}",
        f"Rover service subtype definitions emitted: {stats.event_subtypes_out}",
        f"Duplicate service/expense labels reused: {stats.event_subtype_duplicates} (T2 uses one shared service catalog entry for the same label)",
        f"Subtype default intervals imported: {stats.event_subtype_defaults}",
        f"Vehicle specifications imported: {stats.vehicle_specifications}",
        "Specification values imported by field: "
        + ", ".join(
            f"{VEHICLE_SPEC_REPORT_LABELS[field]}={stats.vehicle_spec_fields[field]}"
            for field in VEHICLE_SPEC_FIELDS.values()
        ),
        f"Source fuel definitions processed: {stats.fuel_types}",
        f"Referenced fuel definitions emitted: {stats.fuel_types_out}",
        f"Unused source fuel definitions not imported: {stats.fuel_types - stats.fuel_types_out} (unused aCar catalog entries would add definitions the owner never selected)",
        f"Preferences not imported: {stats.preferences} (application settings do not describe vehicle history)",
        f"Sync metadata records not imported: {stats.sync_metadata_records} (account and synchronization bookkeeping is not vehicle history)",
        "",
        "Definitions and places",
        f"Energy definitions: {len(definitions['energy'])}",
        f"Additive definitions: {len(definitions['additives'])}",
        f"Driving-mode definitions: {len(definitions['driving-modes'])}",
        f"Tag definitions: {len(definitions['tags'])}",
        f"Payment-method definitions: {len(definitions['payment-methods'])}",
        f"Places: {len(places)}",
        f"Fill notes imported verbatim: {stats.notes_imported}",
        f"Suppressed literal 'deleted' tags: {stats.deleted_tags_suppressed}",
        f"Parts-only addresses imported: {stats.parts_only_addresses}",
        f"Station-none fills with unmapped address text: {len(stats.unlabelled_station_addresses)} (the text has no source label that can identify a station)",
        f"Corrections {'that would be applied' if dry_run else 'applied'}: {len(stats.corrections_applied)}",
        f"Unit mismatches: {stats.unit_mismatches}",
    ]
    lines.extend(
        [
            "",
            "total-cost cross-check",
            f"Compared: {stats.total_checks}",
            f"Exact: {stats.total_exact}",
            f"Within one cent: {stats.total_within_cent}",
            f"Beyond one cent: {stats.total_beyond}",
        ]
    )
    lines.extend(
        [
            "",
            "fuel-efficiency cross-check",
            f"Chronological interval pairs: {stats.efficiency_pairs}",
            f"Compared to source: {stats.efficiency_source_comparisons}",
            f"Source value absent: {stats.efficiency_source_absent}",
            f"Beyond 0.01 mpg: {stats.efficiency_beyond}",
        ]
    )
    lines.extend(
        [
            "",
            "Coordinates",
            f"Source coordinate values: {stats.coordinate_values}",
            f"Values exceeding scale 7: {stats.coordinate_values_over_scale}",
            f"Place coordinate pairs imported: {stats.place_coordinate_pairs}",
            f"Imported place values rounded to scale 7: {stats.place_coordinate_values_rounded}",
            f"Device coordinate pairs skipped: {stats.device_coordinate_pairs}",
            f"Skipped device values exceeding scale 7: {stats.device_coordinate_values_rounded}",
            "",
            "Attachments (no database rows)",
            f"Photos extracted to disk, not the database: {stats.attachments}",
            f"Records carrying photos: {stats.attachment_records}",
            f"Fill/event/vehicle photo split: {stats.attachment_fill_count}/{stats.attachment_event_count}/{stats.attachment_vehicle_count}",
            f"Raw/written bytes: {stats.attachment_raw_bytes}/{stats.attachment_written_bytes}",
            f"Distinct raw hashes: {len(stats.attachment_raw_hashes)}",
            f"Duplicate raw photos: {stats.attachments - len(stats.attachment_raw_hashes)}",
            f"Distinct filenames: {stats.attachments}",
            "Owner JPEG metadata preserved: yes (EXIF is stripped only from a later published artifact)",
            f"PDF tags/nonempty PDFs: {stats.pdf_tags}/{stats.nonempty_pdfs} (empty PDFs contain nothing to carry; nonempty PDFs remain attachment-task scope)",
            "",
            "Other nonempty unmapped fields",
        ]
    )
    if stats.unmapped_nonempty:
        reasons = {
            "vehicle.insurance-policy": "insurance is fenced; a policy string is not an insurance feature",
            "fill.device-coordinate-pair": "device location is not evidence of the station location",
            "event.device-coordinate-pair": "device location is not evidence of the station location",
            "fill.place-google-places-id": "the external directory identifier has no ratified Rover target",
            "event.place-google-places-id": "the external directory identifier has no ratified Rover target",
        }
        labels = {
            "vehicle.insurance-policy": "Insurance policy strings",
            "fill.device-coordinate-pair": "Device coordinate pairs on fills",
            "event.device-coordinate-pair": "Device coordinate pairs on events",
            "fill.place-google-places-id": "External place-directory identifiers on fills",
            "event.place-google-places-id": "External place-directory identifiers on events",
        }
        lines.extend(
            f"{labels.get(field, f'Source field {field}')}: {count} not imported ({reasons.get(field, 'no ratified Rover target; no mapping was invented')})"
            for field, count in sorted(stats.unmapped_nonempty.items())
        )
    else:
        lines.append("None")
    return "\n".join(lines) + "\n"


def ensure_output_outside_repo(output_dir: pathlib.Path) -> None:
    repo = pathlib.Path(__file__).resolve().parents[2]
    resolved = output_dir.expanduser().resolve()
    try:
        resolved.relative_to(repo)
    except ValueError:
        return
    raise ConversionError(f"output directory must be outside the repository: {repo}")


def validate_input(export_dir: pathlib.Path) -> None:
    required = {
        "vehicles.xml",
        "fuel-types.xml",
        "trip-types.xml",
        "event-subtypes.xml",
        "preferences.xml",
        "metadata.inf",
    }
    missing = sorted(name for name in required if not (export_dir / name).is_file())
    if missing:
        raise ConversionError(f"missing export files: {', '.join(missing)}")


def convert_export(
    export_dir: pathlib.Path,
    output_dir: pathlib.Path,
    *,
    dry_run: bool,
    zone: str,
) -> tuple[dict[str, object], list[dict[str, object]], str]:
    export_dir = export_dir.expanduser().resolve()
    output_dir = output_dir.expanduser().resolve()
    validate_input(export_dir)
    ensure_output_outside_repo(output_dir)
    stats = ReportStats()
    stats.trip_types = count_elements(export_dir / "trip-types.xml", "trip-type")
    stats.event_subtypes = count_elements(
        export_dir / "event-subtypes.xml", "event-subtype"
    )
    stats.preferences = count_elements(export_dir / "preferences.xml", "preference")
    fuel_types = read_fuel_types(export_dir / "fuel-types.xml")
    stats.fuel_types = len(fuel_types)
    sync_path = export_dir / "sync-metadata.xml"
    if sync_path.is_file():
        stats.sync_metadata_records = count_elements(sync_path, "sync-metadata")
    event_subtypes = read_event_subtypes(export_dir / "event-subtypes.xml")
    corrections = load_corrections(export_dir)
    metadata = read_properties(export_dir / "metadata.inf")
    parsed = read_vehicles(
        export_dir / "vehicles.xml",
        output_dir,
        dry_run=dry_run,
        stats=stats,
        corrections=corrections,
    )
    document = make_import_document(
        metadata=metadata,
        vehicles=parsed.vehicles,
        fuel_types=fuel_types,
        event_subtypes=event_subtypes,
        zone=zone,
        stats=stats,
    )
    report = render_report(document=document, stats=stats, dry_run=dry_run)
    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / "rover-import.json").write_bytes(json_bytes(document))
        attachment_document = {
            "attachments": parsed.attachment_entries,
            "vehicles": [
                {"directory": f"vehicle-{vehicle.index}", "label": vehicle.label}
                for vehicle in parsed.vehicles
            ],
        }
        (output_dir / "attachments.json").write_bytes(json_bytes(attachment_document))
        (output_dir / "report.txt").write_text(report, encoding="utf-8")
    return document, parsed.attachment_entries, report


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Convert aCar XML files to Rover import JSON."
    )
    parser.add_argument("export_dir", type=pathlib.Path)
    parser.add_argument(
        "--out",
        type=pathlib.Path,
        default=pathlib.Path.home() / "workspace" / "rover" / "converted",
        help="output directory outside the Rover repository",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="validate and report without writing JSON or photos",
    )
    parser.add_argument(
        "--zone",
        default="America/Chicago",
        help="IANA source zone for aCar's minute-precision local timestamps",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = argument_parser().parse_args(argv)
    try:
        _, _, report = convert_export(
            args.export_dir, args.out, dry_run=args.dry_run, zone=args.zone
        )
    except (ConversionError, OSError, ET.ParseError) as exc:
        print(f"acar-import: ERROR: {exc}", file=sys.stderr)
        return 1
    sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
