import csv
from collections.abc import Iterable
from io import StringIO

from app.models.item import HomeItem

_CSV_HEADERS = (
    "name",
    "category",
    "location",
    "serial_number",
    "purchase_date",
    "warranty_expires_at",
    "notes",
    "archived",
)


def inventory_csv(items: Iterable[HomeItem]) -> str:
    output = StringIO(newline="")
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(_CSV_HEADERS)
    for item in items:
        writer.writerow(
            (
                _safe_cell(item.name),
                _safe_cell(item.category),
                _safe_cell(item.location),
                _safe_cell(item.serial_number),
                item.purchase_date.isoformat() if item.purchase_date is not None else "",
                item.warranty_expires_at.isoformat() if item.warranty_expires_at is not None else "",
                _safe_cell(item.notes),
                "yes" if item.archived_at is not None else "no",
            )
        )
    return output.getvalue()


def _safe_cell(value: str | None) -> str:
    if value is None:
        return ""
    return f"'{value}" if value.startswith(("=", "+", "-", "@")) else value
