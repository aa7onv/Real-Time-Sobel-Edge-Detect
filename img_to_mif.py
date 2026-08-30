#!/usr/bin/env python3
"""Convert an image into an Intel Memory Initialization File (.mif) for FPGA use.

Example:
    python img_to_mif.py input.png output.mif
    python img_to_mif.py input.jpg output.mif --mode gray
    python img_to_mif.py input.bmp output.mif --mode rgb --resize 320 240
"""

import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required. Install it with: pip install pillow"
    ) from exc


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert PNG/JPG/BMP image to Intel MIF format."
    )
    parser.add_argument("input", type=str, help="Input image file path")
    parser.add_argument("output", type=str, help="Output .mif file path")
    parser.add_argument(
        "--mode",
        choices=["gray", "rgb"],
        default="gray",
        help="Image mode for memory content: gray (8-bit) or rgb (24-bit).",
    )
    parser.add_argument(
        "--resize",
        nargs=2,
        type=int,
        metavar=("WIDTH", "HEIGHT"),
        default=None,
        help="Optional resize target in pixels before conversion.",
    )
    return parser.parse_args()


def image_to_memory_rows(img, mode):
    """Return a flat list of FPGA-ready pixel values in row-major order.

    gray mode returns an 8-bit value (0..255) for each pixel.
    rgb mode returns a 24-bit value packed as RRGGBB (0..16777215).
    """
    if mode == "gray":
        gray = img.convert("L")
        return [pixel for row in range(gray.height) for pixel in gray.crop((0, row, gray.width, row + 1)).getdata()]

    rgb = img.convert("RGB")
    values = []
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = rgb.getpixel((x, y))
            packed = (r << 16) | (g << 8) | b
            values.append(packed)
    return values


def format_mif_data(values, width_bits):
    """Format memory values as MIF data lines."""
    data_radix = "HEX"
    width_chars = max(2, (width_bits + 3) // 4)

    lines = []
    for address, value in enumerate(values):
        if width_bits == 8:
            formatted = f"{value:02X}"
        elif width_bits == 24:
            formatted = f"{value:06X}"
        else:
            formatted = f"{value:0{width_chars}X}"
        lines.append(f"{address} : {formatted};")
    return lines


def write_mif(path, values, width_bits):
    depth = len(values)
    mif = [
        f"DEPTH = {depth};",
        f"WIDTH = {width_bits};",
        "ADDRESS_RADIX = UNS;",
        "DATA_RADIX = HEX;",
        "CONTENT",
        "BEGIN",
    ]
    mif.extend(format_mif_data(values, width_bits))
    mif.append("END;")

    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(mif) + "\n", encoding="utf-8")


def main():
    args = parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"Input file not found: {input_path}")

    try:
        with Image.open(input_path) as img:
            if args.resize is not None:
                img = img.resize((args.resize[0], args.resize[1]), Image.Resampling.BILINEAR)
            values = image_to_memory_rows(img, args.mode)
    except Exception as exc:
        raise SystemExit(f"Failed to read image '{input_path}': {exc}") from exc

    if args.mode == "gray":
        width_bits = 8
    else:
        width_bits = 24

    write_mif(args.output, values, width_bits)
    print(f"Wrote {len(values)} memory words to {args.output} ({width_bits}-bit width).")


if __name__ == "__main__":
    main()
