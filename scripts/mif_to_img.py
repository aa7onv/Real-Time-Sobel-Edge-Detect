#!/usr/bin/env python3
"""Convert a Quartus MIF memory file into a PNG image.

This script reads a .mif file containing memory initialization data and exports
it as a grayscale image. The data is interpreted as row-major pixels in the
order they appear in the MIF file.

//assumes square, so pass width & height params.
Example:
    python mif_to_img.py input.mif output.png --width 128 --height 128
    python mif_to_img.py input.mif --out output.png
"""

from __future__ import annotations

import argparse
import math
import re
from pathlib import Path
from typing import Iterable, List, Tuple

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Pillow is required. Install it with: pip install pillow") from exc


NUMBER_RE = re.compile(r"(?:0x[0-9A-Fa-f]+|0b[01]+|[0-9]+|[A-Fa-f0-9]+[hH])")


def strip_comments(line: str) -> str:
    """Remove MIF comments and trailing whitespace."""
    return line.split("--", 1)[0].strip()


def parse_numeric_literal(token: str) -> int:
    """Parse common numeric literals used in MIF files."""
    s = token.strip().replace("_", "")
    if not s:
        raise ValueError("empty numeric token")

    if s.lower().startswith("0x"):
        return int(s, 16)
    if s.lower().startswith("0b"):
        return int(s, 2)
    if s.lower().endswith("h"):
        return int(s[:-1], 16)
    if s.lower().startswith("x'") and s.endswith("'"):
        return int(s[2:-1], 16)
    if s.lower().startswith("b'") and s.endswith("'"):
        return int(s[2:-1], 2)
    if s.lower().startswith("d'") and s.endswith("'"):
        return int(s[2:-1], 10)

    # Handle values like 8'd255, 8'hFF, or plain decimal numbers.
    if "'" in s:
        _, body = s.split("'", 1)
        if body.lower().endswith("h"):
            return int(body[:-1], 16)
        if body.lower().startswith("b"):
            return int(body[1:], 2)
        if body.lower().startswith("o"):
            return int(body[1:], 8)
        if body.lower().startswith("d"):
            return int(body[1:], 10)

    # For 11, 255, etc.
    return int(s, 10)


def parse_mif(path: Path) -> List[int]:
    """Parse a Quartus .mif file and return a list of integer values.

    IMPORTANT: this reads the DATA_RADIX header field and uses it directly
    to interpret every value in the CONTENT section. It does NOT try to
    guess a value's radix from its formatting (e.g. a "0x" prefix or "h"
    suffix) -- plain two-digit hex like "FF" or "3A" has no such marker,
    and guessing from formatting alone previously caused values containing
    A-F to be silently dropped or misparsed as decimal.
    """
    entries: List[int] = []
    in_content = False
    bit_width = None
    data_radix = "HEX"  # matches img_to_mif.py's default; overridden below if declared

    radix_base = {"HEX": 16, "DEC": 10, "UNS": 10, "OCT": 8, "BIN": 2}

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = strip_comments(raw_line)
        if not line:
            continue

        upper = line.upper()

        if upper.startswith("WIDTH"):
            try:
                bit_width = int(re.search(r"=\s*(\d+)", line, re.IGNORECASE).group(1))
            except Exception:
                pass
            continue

        if upper.startswith("DATA_RADIX"):
            match = re.search(r"=\s*([A-Za-z]+)", line)
            if match:
                data_radix = match.group(1).upper()
            continue

        if upper.startswith("CONTENT"):
            in_content = True
            continue

        if upper.startswith("END"):
            in_content = False
            continue

        if not in_content:
            continue

        # Handle address : value ; lines. (BEGIN and similar bare keywords
        # have no colon and are skipped here.)
        if ":" not in line:
            continue

        left, right = line.split(":", 1)
        right = right.strip().rstrip(";").strip()

        if not right:
            continue

        base = radix_base.get(data_radix, 16)
        try:
            entries.append(int(right, base))
        except ValueError:
            # Fall back to the old heuristic parser only for genuinely
            # unusual/marked literals (0x.., 8'hFF, etc.) that occasionally
            # show up in hand-written MIFs.
            try:
                entries.append(parse_numeric_literal(right))
            except ValueError:
                continue

    if not entries:
        raise ValueError(f"No memory entries were found in {path}.")

    if bit_width is not None and bit_width < 8:
        # Keep values within the memory width; for tiny bit sizes, expand to
        # a 0..255 grayscale representation by reusing the value as-is.
        entries = [v & ((1 << bit_width) - 1) for v in entries]

    return entries


def infer_dimensions(count: int, width: int | None = None, height: int | None = None) -> Tuple[int, int]:
    if width is not None and height is not None:
        return width, height
    if width is None and height is not None:
        width = math.ceil(count / height)
        return width, height
    if height is None and width is not None:
        height = math.ceil(count / width)
        return width, height

    size = int(math.sqrt(count))
    while size * size < count:
        size += 1
    return size, size


def normalize_to_grayscale(values: Iterable[int]) -> List[int]:
    """Convert memory values to 8-bit grayscale pixels."""
    normalized: List[int] = []
    max_value = 255
    value_list = list(values)
    if not value_list:
        return normalized

    max_seen = max(value_list)
    if max_seen <= 255:
        return [int(v) for v in value_list]

    # 16-bit or wider memory values: scale to 8-bit range.
    if max_seen > 255:
        max_value = max_seen
        for v in value_list:
            normalized.append(int((v / max_value) * 255))
        return normalized

    return [int(v) for v in value_list]


def save_image(values: List[int], image_path: Path, width: int | None = None, height: int | None = None) -> None:
    gray_values = normalize_to_grayscale(values)
    count = len(gray_values)
    if width is None and height is None:
        width, height = infer_dimensions(count)
    elif width is None:
        width = math.ceil(count / height)
    elif height is None:
        height = math.ceil(count / width)

    if width * height < count:
        raise ValueError(f"Image dimensions {width}x{height} are too small for {count} pixels.")

    pad = width * height - count
    if pad:
        gray_values.extend([0] * pad)

    image = Image.new("L", (width, height))
    image.putdata(gray_values[: width * height])
    image.save(image_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert a Quartus .mif file to a grayscale PNG image.")
    parser.add_argument("mif", type=Path, help="Input MIF file path")
    parser.add_argument("output", type=Path, nargs="?", help="Output image path")
    parser.add_argument("--width", type=int, default=None, help="Image width in pixels. If unspecified, infer a square image.")
    parser.add_argument("--height", type=int, default=None, help="Image height in pixels.")
    parser.add_argument("--scale", choices=["8", "16"], default="8", help="Output grayscale bit depth (default: 8)")

    args = parser.parse_args()

    if not args.mif.exists():
        raise SystemExit(f"MIF file not found: {args.mif}")

    out_path = args.output
    if out_path is None:
        out_path = args.mif.with_suffix(".png")
    if out_path.suffix.lower() not in {".png", ".bmp", ".jpg", ".jpeg", ".ppm"}:
        out_path = out_path.with_suffix(".png")

    values = parse_mif(args.mif)

    if args.scale == "16":
        # Preserve more dynamic range by scaling the data to 16-bit when the
        # source values are larger than 255, otherwise leave the values as-is.
        max_seen = max(values)
        if max_seen <= 65535:
            values = [min(int(v), 65535) for v in values]
        else:
            scale = max_seen / 65535
            values = [min(int(v / scale), 65535) for v in values]

        gray = [int(v >> 8) for v in values]
        save_image(gray, out_path, args.width, args.height)
        print(f"Saved 8-bit grayscale preview to {out_path}")
        return

    save_image(values, out_path, args.width, args.height)
    print(f"Saved {args.mif} -> {out_path}")


if __name__ == "__main__":
    main()