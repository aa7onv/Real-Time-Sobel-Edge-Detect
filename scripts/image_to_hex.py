#!/usr/bin/env python3
"""
image_to_hex.py

Converts an input image into the plain hex text file format expected by
image_rom.v's $readmemh initialization.

- Resizes/crops the source image to 320x240 (matching image_rom.v's
  IMG_WIDTH/IMG_HEIGHT parameters).
- Packs each pixel as a 24-bit hex word: RRGGBB (R in upper byte, G middle,
  B lower byte), matching image_rom.v's storage format.
- Writes one hex word per line, in row-major order (address = y*320 + x),
  matching rom_addr_gen.v's addressing.

Usage:
    python3 image_to_hex.py input.jpg image.hex
"""

import sys
from PIL import Image

IMG_WIDTH = 320
IMG_HEIGHT = 240


def convert(input_path, output_path):
    img = Image.open(input_path).convert("RGB")

    # Resize to fill 320x240 exactly (stretches aspect ratio if source
    # doesn't match -- swap to a crop-based approach here if preserving
    # aspect ratio matters more than filling the frame).
    img = img.resize((IMG_WIDTH, IMG_HEIGHT), Image.LANCZOS)

    with open(output_path, "w") as f:
        for y in range(IMG_HEIGHT):
            for x in range(IMG_WIDTH):
                r, g, b = img.getpixel((x, y))
                word = (r << 16) | (g << 8) | b
                f.write(f"{word:06x}\n")

    print(f"Wrote {IMG_WIDTH * IMG_HEIGHT} words to {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 image_to_hex.py <input_image> <output.hex>")
        sys.exit(1)

    convert(sys.argv[1], sys.argv[2])