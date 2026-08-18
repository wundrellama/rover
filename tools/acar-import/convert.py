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
    kind: str
    name: str
    default_time: str
    default_distance: str


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
    trip_types: int = 0
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
    attachment_raw_bytes: int = 0
    attachment_written_bytes: int = 0
    attachment_files_with_app_segments: int = 0
    attachment_raw_hashes: set[str] = dataclasses.field(default_factory=set)
    attachment_written_hashes: set[str] = dataclasses.field(default_factory=set)
    unmapped_nonempty: collections.Counter[str] = dataclasses.field(
        default_factory=collections.Counter
    )
    service_events: int = 0
    note_events: int = 0
    expense_events: int = 0
    events_out: int = 0
    event_subtype_links: int = 0
    event_zero_totals: int = 0
    note_records_with_cost: list[str] = dataclasses.field(default_factory=list)
    event_station_none: int = 0
    event_notes_imported: int = 0
    subtype_records: int = 0
    subtype_labels: int = 0
    subtype_labels_collapsed: int = 0
    subtype_defaults_time: int = 0
    subtype_defaults_distance: int = 0
    subtype_expense_only: int = 0
    reminders_in: int = 0
    reminders_out: int = 0
    reminder_time_of_day_dropped: int = 0
    reminders_at_catalog_default: int = 0
    specification_vehicles: int = 0
    specification_fields: int = 0
    specification_fields_absent: int = 0
    insurance_policies: int = 0


@dataclasses.dataclass
class VehicleSource:
    index: int
    label: str
    distance_unit: str
    volume_unit: str
    tank_capacity: str
    records: list[dict[str, str]]
    events: list[dict[str, object]] = dataclasses.field(default_factory=list)
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

# M7 T7 named thirteen specification fields. Each one is a source field of the
# same meaning; the vehicle note is aCar's `notes`. The second member of each
# pair is the Rover import payload key, not the relation name.
SPECIFICATION_FIELDS = (
    ("vin", "vin"),
    ("license-plate", "plate"),
    ("year", "modelYear"),
    ("make", "make"),
    ("model", "model"),
    ("sub-model", "subModel"),
    ("body-type", "bodyType"),
    ("color", "color"),
    ("engine", "engine"),
    ("transmission", "transmission"),
    ("drive-type", "driveType"),
    ("bed-type", "bedType"),
    ("notes", "note"),
)

VEHICLE_FIELDS = {
    "name",
    "distance-unit",
    "volume-unit",
    "fuel-tank-capacity",
    "active",
    "vehicle-id",
    "type",
    "make",
    "make-id",
    "model",
    "model-id",
    "sub-model",
    "year",
    "vin",
    "license-plate",
    "notes",
    "photo",
    "color",
    "engine",
    "engine-id",
    "transmission",
    "transmission-id",
    "body-type",
    "body-type-id",
    "bed-type",
    "bed-type-id",
    "drive-type",
    "drive-type-id",
    "generic-engine-base-id",
    "generic-fuel-type-id",
    "insurance-policy",
    "country-id",
    "country-name",
    "region-id",
    "region-name",
    "city-name",
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
    "photo",
    "make-id",
    "model-id",
    "engine-id",
    "transmission-id",
    "body-type-id",
    "bed-type-id",
    "drive-type-id",
    "generic-engine-base-id",
    "generic-fuel-type-id",
    "insurance-policy",
    "country-id",
    "country-name",
    "region-id",
    "region-name",
    "city-name",
}

# Every unmapped field the report names carries the reason it stayed out. A
# count on its own tells the owner something was dropped without telling them
# whether that was a decision or an oversight.
UNMAPPED_REASONS = {
    "vehicle.active": (
        "aCar's own show/hide flag. Rover has `archived`, and an import must "
        "not decide that a vehicle is retired."
    ),
    "vehicle.vehicle-id": "aCar's internal row number. Rover keys on its own IDs.",
    "vehicle.type": (
        "aCar's vehicle category. Rover models make, model and body type "
        "instead, and all three are imported."
    ),
    "vehicle.photo": (
        "The vehicle photo, held inline as base64. Attachments are their own "
        "task: the bytes are extracted to disk and no database row is written."
    ),
    "vehicle.make-id": "aCar's catalog row number behind `make`, which is imported.",
    "vehicle.model-id": "aCar's catalog row number behind `model`, which is imported.",
    "vehicle.engine-id": "aCar's catalog row number behind `engine`, which is imported.",
    "vehicle.transmission-id": (
        "aCar's catalog row number behind `transmission`, which is imported."
    ),
    "vehicle.body-type-id": (
        "aCar's catalog row number behind `body-type`, which is imported."
    ),
    "vehicle.bed-type-id": (
        "aCar's catalog row number behind `bed-type`, which is imported."
    ),
    "vehicle.drive-type-id": (
        "aCar's catalog row number behind `drive-type`, which is imported."
    ),
    "vehicle.generic-engine-base-id": "aCar's internal engine catalog reference.",
    "vehicle.generic-fuel-type-id": "aCar's internal fuel catalog reference.",
    "vehicle.insurance-policy": (
        "Insurance is fenced, ruled 2026-08-18. A bare policy string is a stub "
        "of a feature rather than a feature."
    ),
    "vehicle.country-id": "aCar's catalog row number behind the country name.",
    "vehicle.country-name": (
        "Where the vehicle is registered. Rover models a place for a station, "
        "not a home country for a vehicle."
    ),
    "vehicle.region-id": "aCar's catalog row number behind the region name.",
    "vehicle.region-name": (
        "Where the vehicle is registered. Rover has no relation for it."
    ),
    "vehicle.city-name": (
        "Where the vehicle is registered. Rover has no relation for it."
    ),
    "fill.place-google-places-id": (
        "A provider-namespaced directory ID. It is a machine value that never "
        "reaches a person, and Rover already holds the label and the address."
    ),
    "fill.device-coordinate-pair": (
        "Where the phone was standing, not where the station is. Ruled "
        "2026-07-30 (import Q6): the grain is per visit and Rover models a "
        "location per place."
    ),
    "event.place-google-places-id": (
        "A provider-namespaced directory ID. It is a machine value that never "
        "reaches a person, and Rover already holds the label and the address."
    ),
    "event.device-coordinate-pair": (
        "Where the phone was standing, not where the shop is. Ruled "
        "2026-07-30 (import Q6)."
    ),
    "event.fuel-efficiency": (
        "A derived figure. Rover derives fuel economy and never stores it."
    ),
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
        subtype_id = element.attrib.get("id", "").strip()
        if not subtype_id:
            raise ConversionError("event subtype without an id")
        name = values.get("name", "")
        if not name:
            raise ConversionError(f"event subtype {subtype_id} has no name")
        subtypes[subtype_id] = EventSubtype(
            kind=element.attrib.get("type", "").strip(),
            name=name,
            default_time=values.get("default-time-reminder-interval", ""),
            default_distance=values.get("default-distance-reminder-interval", ""),
        )
        element.clear()
    return subtypes


# aCar names its reminder unit in the plural. Rover's `reminder-time-unit` is
# a singular term, and it is a calendar step rather than a count of seconds.
REMINDER_TIME_UNITS = {
    "days": "day",
    "day": "day",
    "weeks": "week",
    "week": "week",
    "months": "month",
    "month": "month",
    "years": "year",
    "year": "year",
}


def reminder_time_unit(source_unit: str) -> str:
    try:
        return REMINDER_TIME_UNITS[source_unit.strip().lower()]
    except KeyError as exc:
        raise ConversionError(
            f"unsupported aCar reminder time unit: {source_unit!r}"
        ) from exc


def build_service_subtypes(
    event_subtypes: dict[str, EventSubtype],
    stats: ReportStats | None = None,
) -> tuple[list[dict[str, object]], ReportStats]:
    """One definition per LABEL, matching the T2 starter pack.

    The source catalog carries `Car Wash`, `Insurance` and `Registration`
    twice, once as a service subtype and once as an expense subtype. Rover has
    one service-subtype family and T2 seeded one row for each of those labels,
    so a second row here would put a duplicate in every selector.

    A definition carries its label and nothing else. aCar attaches a SUGGESTED
    reminder interval to every catalog entry; Rover stores an interval on a
    reminder, which is where the owner's own eight arrive. Emitting a key no
    relation reads would be a stub, so the suggestions are counted here and
    named in the report instead.
    """
    if stats is None:
        stats = ReportStats()
    collected: dict[str, dict[str, object]] = {}
    for _, subtype in sorted(event_subtypes.items(), key=lambda item: item[1].name):
        stats.subtype_records += 1
        if subtype.kind == "expense":
            stats.subtype_expense_only += 1
        if subtype.default_time:
            stats.subtype_defaults_time += 1
        if subtype.default_distance:
            stats.subtype_defaults_distance += 1
        if subtype.name in collected:
            stats.subtype_labels_collapsed += 1
            continue
        collected[subtype.name] = {"label": subtype.name}
    stats.subtype_labels = len(collected)
    return [collected[label] for label in sorted(collected)], stats


def build_specification(
    values: dict[str, str], *, stats: ReportStats
) -> dict[str, str]:
    """The thirteen T7 fields, and only the ones the source actually filled.

    An empty source field writes NO key, so the importer never clears a value
    the owner corrected in Rover after an earlier import.
    """
    specification: dict[str, str] = {}
    for source_key, payload_key in SPECIFICATION_FIELDS:
        value = values.get(source_key, "").strip()
        if value:
            specification[payload_key] = value
            stats.specification_fields += 1
        else:
            stats.specification_fields_absent += 1
    return specification


def convert_event(
    *,
    record: dict[str, object],
    vehicle_label: str,
    vehicle_dir: str,
    distance_unit: str,
    event_subtypes: dict[str, EventSubtype],
    zone: str,
    stats: ReportStats,
) -> dict[str, object]:
    """One aCar event record as an `add-*-event` payload.

    The KIND is not a member of this object. It is which section of the import
    document the record lands in, exactly as the kind of a hand-entered event
    is which route a browser posted to.
    """
    text_record = {
        key: value for key, value in record.items() if isinstance(value, str)
    }
    rover_distance = distance_unit_label(distance_unit)
    kind = text_trimmed(text_record, "type")
    reference = record_ref(vehicle_dir, text_record)
    remote_id = text_trimmed(text_record, "_remote_id")
    if not remote_id:
        raise ConversionError(f"{reference}: remote-id absent")
    odometer = text_trimmed(text_record, "odometer-reading")
    if not odometer:
        raise ConversionError(f"{reference}: odometer-reading absent")
    event: dict[str, object] = {
        "mileage": fixed_decimal(odometer, 1),
        "mileageUnit": rover_distance,
        "observed": observed_start(text_trimmed(text_record, "date")),
        "sourceApp": "acar",
        "sourceRecordId": remote_id,
        "station": "none",
        "subtypes": [],
        "tags": [],
        "vehicle": vehicle_label,
        "zone": zone,
    }
    source_total = text_trimmed(text_record, "total-cost")
    if source_total:
        # aCar's total is a mandatory numeric field and writes 0 when nothing
        # was entered, so a zero cannot be told apart from a genuine free
        # service. An absent cost row is visibly unknown; a stored 0.00 would
        # be invisibly wrong, and the owner can enter the real figure later.
        if parse_decimal(source_total).digits:
            event["total"] = source_total
        else:
            stats.event_zero_totals += 1
    if kind == "note" and source_total and parse_decimal(source_total).digits:
        stats.note_records_with_cost.append(
            f"{reference}: a record aCar typed `note` carries a total of "
            f"{source_total}. It is imported as a note with that total and is "
            "not reclassified as an expense."
        )
    subtype_ids = record.get("_subtype_ids", [])
    labels: list[str] = []
    for subtype_id in subtype_ids if isinstance(subtype_ids, list) else []:
        subtype = event_subtypes.get(str(subtype_id))
        if subtype is None:
            raise ConversionError(f"{reference}: unknown event subtype")
        if subtype.name not in labels:
            labels.append(subtype.name)
        stats.event_subtype_links += 1
    event["subtypes"] = labels
    tags = []
    for tag in split_list(text_record.get("tags", "")):
        if tag == "deleted":
            stats.deleted_tags_suppressed += 1
        elif tag not in tags:
            tags.append(tag)
    event["tags"] = tags
    payment = text_trimmed(text_record, "payment-type")
    if payment:
        event["paymentMethod"] = payment
    notes = text_record.get("notes", "")
    if notes.strip():
        event["notes"] = notes
        stats.event_notes_imported += 1
    label = resolve_place_label(text_record)
    if label:
        event["station"] = label
    else:
        # Q10 applied to an event: the address text names no station, and
        # matching on it would invent which shop was visited.
        formatted = text_trimmed(text_record, "place-full-address")
        if formatted:
            stats.unlabelled_station_addresses.append(formatted)
        stats.event_station_none += 1
    stats.events_out += 1
    return event


def convert_reminder(
    *,
    source: dict[str, str],
    vehicle_label: str,
    distance_unit: str,
    event_subtypes: dict[str, EventSubtype],
    stats: ReportStats,
) -> dict[str, str]:
    subtype_id = text_trimmed(source, "_subtype_id")
    subtype = event_subtypes.get(subtype_id)
    if subtype is None:
        raise ConversionError(f"{vehicle_label}: reminder names an unknown subtype")
    reminder: dict[str, str] = {
        "subtype": subtype.name,
        "vehicle": vehicle_label,
    }
    time_interval = text_trimmed(source, "time-interval")
    time_due = text_trimmed(source, "time-due")
    if time_interval and time_due:
        reminder["timeInterval"] = time_interval
        reminder["timeUnit"] = reminder_time_unit(text_trimmed(source, "time-unit"))
        # T6 ruled the due point a calendar day rather than an instant, so the
        # source's time of day has no home. The count is reported.
        due = observed_start(time_due)
        reminder["timeDue"] = due[:10]
        if due[11:] != "00:00":
            stats.reminder_time_of_day_dropped += 1
    elif time_interval or time_due:
        raise ConversionError(
            f"{vehicle_label}: reminder carries half a time interval"
        )
    distance_interval = text_trimmed(source, "distance-interval")
    distance_due = text_trimmed(source, "distance-due")
    if distance_interval and distance_due:
        reminder["distanceInterval"] = distance_interval
        reminder["distanceDue"] = distance_due
        reminder["distanceUnit"] = distance_unit_label(distance_unit)
    elif distance_interval or distance_due:
        raise ConversionError(
            f"{vehicle_label}: reminder carries half a distance interval"
        )
    # Evidence that the catalog suggestion is exactly what a reminder carries:
    # the owner either accepted it here or typed over it.
    if subtype.default_time and time_interval == subtype.default_time:
        stats.reminders_at_catalog_default += 1
    if "timeInterval" not in reminder and "distanceInterval" not in reminder:
        raise ConversionError(f"{vehicle_label}: reminder names no interval at all")
    stats.reminders_out += 1
    return reminder


def build_notices(stats: ReportStats) -> list[dict[str, object]]:
    """Every source record kind that did not become a Rover row.

    The list travels inside the import document, so the report a person reads
    after the import carries the same disclosure as the converter's own report.
    A count with no reason leaves the owner unable to act on it.
    """
    candidates = [
        (
            "Trip types",
            stats.trip_types,
            "aCar's shipped defaults, carrying IRS mileage deduction rates. "
            "Rover has no model for a deduction rate.",
        ),
        (
            "Trip records",
            stats.trip_records,
            "The feature was never used, so there is nothing to carry.",
        ),
        (
            "Insurance policies",
            stats.insurance_policies,
            "Insurance is fenced, ruled 2026-08-18. A bare policy string is a "
            "stub of a feature rather than a feature.",
        ),
        (
            "Photos",
            stats.attachments,
            "Attachments are their own task. The bytes are extracted to disk "
            "beside this document with a manifest, and no database row holds "
            "an image.",
        ),
        (
            "PDF slots with content",
            stats.nonempty_pdfs,
            "The export defines PDF slots but none carries a document.",
        ),
        (
            "Expense event records",
            stats.expense_events,
            "The corpus holds none. Rover records the kind, so a later export "
            "carrying one would import.",
        ),
        (
            "Expense-only subtype definitions",
            stats.subtype_expense_only,
            "Rover keeps one service-subtype catalog, so these arrive as "
            "ordinary definitions rather than a second family.",
        ),
        (
            "Duplicate subtype labels collapsed",
            stats.subtype_labels_collapsed,
            "The source names these labels twice, once under service and once "
            "under expense. Rover's catalog holds one row per label, which is "
            "what the starter pack already seeded.",
        ),
        (
            "Event records with a source total of zero",
            stats.event_zero_totals,
            "aCar writes 0 when no amount was entered, so a stored 0.00 could "
            "not be told apart from a genuine free service. These import with "
            "no cost row, and the amount can be entered later.",
        ),
        (
            "Service-subtype default reminder intervals",
            stats.subtype_defaults_time,
            "aCar suggests an interval on every catalog entry. Rover stores an "
            "interval on a reminder, and the owner's own reminders carry "
            f"theirs: {stats.reminders_at_catalog_default} of "
            f"{stats.reminders_out} arrive holding exactly the suggestion for "
            "their subtype. Creating a reminder for every catalog entry would "
            "invent schedules nobody set.",
        ),
        (
            "Reminder due points losing a time of day",
            stats.reminder_time_of_day_dropped,
            "A Rover reminder falls due on a calendar day rather than at an "
            "instant, so the source's clock time has no home.",
        ),
        (
            "Event records aCar typed `note` that carry money",
            len(stats.note_records_with_cost),
            "They import as notes with their total. Reclassifying one as an "
            "expense would decide, on the owner's behalf, that aCar's own type "
            "was wrong.",
        ),
        (
            "Suppressed literal `deleted` tags",
            stats.deleted_tags_suppressed,
            "An aCar internal marker, not an owner tag. Ruled 2026-07-30 "
            "(import Q8).",
        ),
        (
            "Station-none fills with unmapped address text",
            len(stats.unlabelled_station_addresses),
            "The address text names no station, and several stations share one "
            "address, so a match would invent which one was visited. Ruled "
            "2026-07-30 (import Q10).",
        ),
    ]
    notices = [
        {"count": count, "kind": kind, "reason": reason}
        for kind, count, reason in candidates
        if count
    ]
    for field, count in sorted(stats.unmapped_nonempty.items()):
        notices.append(
            {
                "count": count,
                "kind": f"Source field {field}",
                "reason": UNMAPPED_REASONS.get(
                    field, "No Rover relation holds this fact."
                ),
            }
        )
    return notices


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
        stripped = strip_jpeg_app_segments(raw)
        raw_hash = hashlib.sha256(raw).hexdigest()
        written_hash = hashlib.sha256(stripped).hexdigest()
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
            destination.write_bytes(stripped)
        entries.append(
            {
                "bytes": len(stripped),
                "file": relative_text,
                "odometer": fixed_decimal(
                    text_trimmed(record, "odometer-reading"), 1
                ),
                "observed-start": observed,
                "ordinal": ordinal,
                "record-kind": record_kind,
                "sha256": written_hash,
                "source-remote-id": remote_id,
                "vehicle": vehicle_label,
            }
        )
        stats.attachments += 1
        stats.attachment_raw_bytes += len(raw)
        stats.attachment_written_bytes += len(stripped)
        stats.attachment_raw_hashes.add(raw_hash)
        stats.attachment_written_hashes.add(written_hash)
        stats.attachment_files_with_app_segments += int(raw != stripped)
        if record_kind == "fill":
            stats.attachment_fill_count += 1
        else:
            stats.attachment_event_count += 1


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
    vehicle_events: list[dict[str, object]] | None = None
    vehicle_reminders: list[dict[str, str]] | None = None
    vehicle_index = 0
    record: dict[str, str] | None = None
    record_kind = ""

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
                if vehicle_events is None:
                    raise ConversionError("event record found outside a vehicle")
                stats.event_records += 1
                # The typed children live under `<subtypes>`, not among the
                # scalar fields, so they are read from the element itself.
                subtype_ids = [
                    child.attrib.get("id", "").strip()
                    for container in element
                    if local_name(container.tag) == "subtypes"
                    for child in container
                    if local_name(child.tag) == "subtype"
                ]
                if any(not value for value in subtype_ids):
                    raise ConversionError("event subtype reference without an id")
                kind = text_trimmed(record, "type")
                if kind == "service":
                    stats.service_events += 1
                elif kind == "note":
                    stats.note_events += 1
                elif kind == "expense":
                    stats.expense_events += 1
                else:
                    raise ConversionError(f"unsupported aCar event type: {kind!r}")
                vehicle_events.append({**record, "_subtype_ids": subtype_ids})
            record = None
            record_kind = ""
            element.clear()

        elif tag == "reminder":
            if vehicle_reminders is None:
                raise ConversionError("reminder found outside a vehicle")
            stats.reminders_in += 1
            values = {
                local_name(child.tag): (child.text or "").strip()
                for child in element
            }
            values["_subtype_id"] = element.attrib.get(
                "event-subtype-id", ""
            ).strip()
            values["_event_type"] = element.attrib.get("event-type", "").strip()
            vehicle_reminders.append(values)
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
            for field in UNMAPPED_VEHICLE_FIELDS:
                if vehicle_values.get(field, "").strip():
                    stats.unmapped_nonempty[f"vehicle.{field}"] += 1
            if vehicle_values.get("insurance-policy", "").strip():
                stats.insurance_policies += 1
            specification = build_specification(vehicle_values, stats=stats)
            if specification:
                stats.specification_vehicles += 1
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
                    specification=specification,
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


def build_places(vehicles: list[VehicleSource]) -> list[dict[str, object]]:
    """One `places` row per label, over fills AND events alike.

    A place is a place. Import rule 6 already matched them by label so two
    fills at one forecourt make one row; an event at a repair shop obeys the
    same rule, and a shop the owner also buys fuel at would be one place.
    """
    accumulated: dict[str, dict[str, object]] = {}
    fuelling: set[str] = set()
    for vehicle in vehicles:
        for record in list(vehicle.records) + [
            {key: value for key, value in event.items() if isinstance(value, str)}
            for event in vehicle.events
        ]:
            label = resolve_place_label(record)
            if not label:
                continue
            if "volume" in record:
                fuelling.add(label)
            place = accumulated.setdefault(label, {"label": label})
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
    # A place only a service visit ever names is not a filling station, and
    # saying it were would put a forecourt in the Add Fill selector that sells
    # nothing. `private` is what the Add Event form's own station control
    # offers first, so an imported shop matches a hand-entered one.
    for label, place in accumulated.items():
        place["kind"] = "fuel" if label in fuelling else "private"
    return [accumulated[label] for label in sorted(accumulated)]


def build_definitions(
    vehicles: list[VehicleSource],
    fuel_types: dict[str, FuelType],
    event_subtypes: dict[str, EventSubtype] | None = None,
    stats: ReportStats | None = None,
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
        # An event reaches the same tag and payment-method catalogs a fill
        # reaches. Only the link rows differ.
        for event in vehicle.events:
            text_event = {
                key: value for key, value in event.items() if isinstance(value, str)
            }
            tags.update(
                tag
                for tag in split_list(text_event.get("tags", ""))
                if tag != "deleted"
            )
            payment = text_trimmed(text_event, "payment-type")
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
    service_subtypes, _ = build_service_subtypes(event_subtypes or {}, stats)
    return {
        "additives": simple(additives),
        "driving-modes": simple(modes),
        "energy": energy,
        "payment-methods": simple(payment_methods),
        "service-subtypes": service_subtypes,
        "tags": simple(tags),
    }


def count_record_unmapped(vehicles: list[VehicleSource], stats: ReportStats) -> None:
    for vehicle in vehicles:
        for record in vehicle.records:
            if text_trimmed(record, "place-google-places-id"):
                stats.unmapped_nonempty["fill.place-google-places-id"] += 1
            if text_trimmed(record, "device-latitude"):
                stats.unmapped_nonempty["fill.device-coordinate-pair"] += 1
        for event in vehicle.events:
            text_event = {
                key: value for key, value in event.items() if isinstance(value, str)
            }
            if text_trimmed(text_event, "place-google-places-id"):
                stats.unmapped_nonempty["event.place-google-places-id"] += 1
            if text_trimmed(text_event, "device-latitude"):
                stats.unmapped_nonempty["event.device-coordinate-pair"] += 1


def make_import_document(
    *,
    metadata: dict[str, str],
    vehicles: list[VehicleSource],
    fuel_types: dict[str, FuelType],
    event_subtypes: dict[str, EventSubtype],
    zone: str,
    stats: ReportStats,
) -> dict[str, object]:
    definitions = build_definitions(vehicles, fuel_types, event_subtypes, stats)
    places = build_places(vehicles)
    output_vehicles: list[dict[str, object]] = []
    for vehicle in vehicles:
        rover_distance = distance_unit_label(vehicle.distance_unit)
        quantity_unit, _ = volume_profile(vehicle.volume_unit)
        output_vehicle: dict[str, object] = {
            "distanceUnit": rover_distance,
            "fills": [],
            "label": vehicle.label,
            "volumeUnit": quantity_unit,
        }
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
        if vehicle.specification:
            output_vehicle["specification"] = vehicle.specification
        # One section per kind. The section is the route: a record never names
        # its own kind, so it cannot disagree with the child row it becomes.
        by_kind: dict[str, list[dict[str, object]]] = {
            "service": [],
            "expense": [],
            "note": [],
        }
        for source_event in vehicle.events:
            kind = str(source_event.get("type", "")).strip()
            by_kind[kind].append(
                convert_event(
                    record=source_event,
                    vehicle_label=vehicle.label,
                    vehicle_dir=f"vehicle-{vehicle.index}",
                    distance_unit=vehicle.distance_unit,
                    event_subtypes=event_subtypes,
                    zone=zone,
                    stats=stats,
                )
            )
        for kind, section in (
            ("service", "serviceEvents"),
            ("expense", "expenseEvents"),
            ("note", "noteEvents"),
        ):
            if by_kind[kind]:
                output_vehicle[section] = by_kind[kind]
        reminders = [
            convert_reminder(
                source=source_reminder,
                vehicle_label=vehicle.label,
                distance_unit=vehicle.distance_unit,
                event_subtypes=event_subtypes,
                stats=stats,
            )
            for source_reminder in vehicle.reminders
        ]
        if reminders:
            output_vehicle["reminders"] = reminders
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
        "notices": build_notices(stats),
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
        f"Event records in/out: {stats.event_records}/{stats.events_out}",
        f"Service/note/expense events: {stats.service_events}/{stats.note_events}"
        f"/{stats.expense_events}",
        f"Event to subtype links: {stats.event_subtype_links}",
        f"Events with no station: {stats.event_station_none}",
        f"Reminders in/out: {stats.reminders_in}/{stats.reminders_out}",
        f"Vehicles carrying a specification: {stats.specification_vehicles}",
        f"Specification fields present/empty: {stats.specification_fields}"
        f"/{stats.specification_fields_absent}",
        f"Trip records unmapped: {stats.trip_records}",
        f"Trip types unmapped: {stats.trip_types}",
        f"Preferences ignored (application settings): {stats.preferences}",
        "",
        "Definitions and places",
        f"Energy definitions: {len(definitions['energy'])}",
        f"Additive definitions: {len(definitions['additives'])}",
        f"Driving-mode definitions: {len(definitions['driving-modes'])}",
        f"Tag definitions: {len(definitions['tags'])}",
        f"Payment-method definitions: {len(definitions['payment-methods'])}",
        f"Service-subtype source records: {stats.subtype_records}",
        f"Service-subtype definitions: {len(definitions.get('service-subtypes', []))}",
        f"Duplicate subtype labels collapsed: {stats.subtype_labels_collapsed}",
        f"Subtype default time/distance intervals carried: "
        f"{stats.subtype_defaults_time}/{stats.subtype_defaults_distance}",
        f"Places: {len(places)}",
        f"Fill notes imported verbatim: {stats.notes_imported}",
        f"Event notes imported verbatim: {stats.event_notes_imported}",
        f"Suppressed literal 'deleted' tags: {stats.deleted_tags_suppressed}",
        f"Parts-only addresses imported: {stats.parts_only_addresses}",
        f"Station-none fills with unmapped address text: {len(stats.unlabelled_station_addresses)}",
        f"Corrections {'that would be applied' if dry_run else 'applied'}: {len(stats.corrections_applied)}",
        f"Unit mismatches: {stats.unit_mismatches}",
    ]
    lines.extend(
        f"{'Would correct' if dry_run else 'Corrected'}: {item}"
        for item in stats.corrections_applied
    )
    lines.extend(
        f"Unmapped station address: {address}"
        for address in stats.unlabelled_station_addresses
    )
    lines.extend(f"Unit mismatch: {item}" for item in stats.unit_mismatch_details)
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
    lines.extend(f"Mismatch: {item}" for item in stats.total_mismatches)
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
    lines.extend(f"Mismatch: {item}" for item in stats.efficiency_mismatches)
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
            f"Photos extracted: {stats.attachments}",
            f"Records carrying photos: {stats.attachment_records}",
            f"Fill/event photo split: {stats.attachment_fill_count}/{stats.attachment_event_count}",
            f"Raw/written bytes: {stats.attachment_raw_bytes}/{stats.attachment_written_bytes}",
            f"Distinct raw hashes: {len(stats.attachment_raw_hashes)}",
            f"Duplicate raw photos: {stats.attachments - len(stats.attachment_raw_hashes)}",
            f"Distinct filenames: {stats.attachments}",
            f"Files changed by APPn stripping: {stats.attachment_files_with_app_segments}",
            f"PDF tags/nonempty PDFs: {stats.pdf_tags}/{stats.nonempty_pdfs}",
        ]
    )
    # Nothing leaves the source without a line here. A count on its own tells
    # the owner that something was dropped without telling them why, which is
    # the loss they would otherwise find months later.
    lines.extend(["", "Not imported, and why"])
    notices = document.get("notices")
    if isinstance(notices, list) and notices:
        lines.extend(
            f"{notice['kind']}: {notice['count']} - {notice['reason']}"
            for notice in notices
        )
    else:
        lines.append("Nothing. Every source record kind became a Rover row.")
    lines.extend(f"Note: {item}" for item in stats.note_records_with_cost)
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
    stats.preferences = count_elements(export_dir / "preferences.xml", "preference")
    fuel_types = read_fuel_types(export_dir / "fuel-types.xml")
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
