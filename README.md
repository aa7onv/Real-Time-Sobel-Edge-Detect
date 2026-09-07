# Real-Time-Sobel-Edge-Detect

Real-time Sobel edge detection pipeline implemented in Verilog, running live on a DE1-SoC FPGA board with VGA output.

## References
https://en.wikipedia.org/wiki/Sobel_operator
Sobel Eddge Detection on FPGA.pdf

## Target Hardware

Developed and tested on **DE1-SoC** (Cyclone V, 5CSEMA5F31C6) using **Intel Quartus** (synthesis) and **ModelSim** (simulation).

## Status

| Phase | Description | Status |
|---|---|---|
| 1 | Core pixel pipeline, static image, simulation only | Done |
| 2 | Static image on real hardware (no display output) | Done |
| 3 | Static image on hardware with VGA output | Done |
| 4 | Video timing / sync delay | Done (folded into Phase 3's VGA bring-up) |
| 5 | Real-time output via on-chip animated test pattern generator | Done |
| 6 | Live camera input | Not started — see [Future Work](#future-work) |

The pipeline currently runs live on hardware, displaying a synthesized, animated checkerboard pattern with real-time Sobel edge detection on VGA at 640x480@60Hz.

## Architecture Design

```
[ pattern_gen ] -- (pixel source, RGB)
        │
        ▼
[ grayscale ]  -- BT.601 weighted luma, RGB -> 8-bit gray
        │
        ▼
[ window_3x3 ] -- 2x line_buffer (row delay) + column shift registers
        │           -> 3x3 pixel neighborhood
        ▼
[ sobel_conv ] -- Gx / Gy convolution
        │
        ▼
[ gradient_sum ] -- |Gx| + |Gy| approximation, saturated to 8-bit
        │
        ▼
   edge pixel out -> VGA output (R=G=B=edge magnitude)
```

`grayscale.v` -> `window_3x3.v` -> `sobel_conv.v` -> `gradient_sum.v` are wired together as `sobel_core.v`. Everything upstream (pixel source) and downstream (VGA timing/output) lives in `sobel_top.v`.

### Pipeline latency

| Stage | Latency (cycles) |
|---|---|
| Pixel source (`pattern_gen` / `image_rom`, registered output) | 1 |
| `grayscale.v` | 2 |
| `sobel_core.v` (`window_3x3` + `sobel_conv` + `gradient_sum`) | 6 |
| **Total** | **9** |

## Key Design Decisions
- Will be using Grayscale, 8-bit pixel input
- `\|Gx\| + \|Gy\|` instead of `sqrt(Gx² + Gy²)`  to avoid an expensive sqrt; standard approximation with acceptable accuracy loss
- one pixel/clock | No stalling; required for real-time video-rate throughput
- no thresholding. Would lose visual detail of how strong each edge is.

## Repository Outline 
```
├── rtl/
│   ├── grayscale.v          # weighted avg grayscale                        
│   ├── line_buffer.v        # Row-delay FIFOs
│   ├── window_3x3.v         # 3x3 sliding window shift register
│   ├── sobel_conv.v         # Gx/Gy convolution units
│   ├── gradient_sum.v       # |Gx| + |Gy| Sobel Approximation
│   ├── sobel_core.v         # Sobel Algo wiring 
│   ├── vga_controller.v     # 640x480@60Hz VGA timing generator
│   ├── delay_chain.v        # Generic parameterized shift-register delay
│   ├── pattern_gen.v        # Phase 5: synthesized animated checkerboard 
│   └── sobel_top.v          # Full top-level integration (PLL, VGA, source, pipeline) 
├── ip/
│   └── pll_vga.qip          # PLL IP: 50MHz -> ~25.175MHz pixel clock
├── scripts/
│   └── image_to_hex.py      # Converts an image to the .hex format image_rom.v expects
│   └── image_to_mif.py      # Converts img to .mif for Sim testing
│   └── mif_to_img.py        # Converts .mif back to viewable format
├── constraints/
│   └── sobel_top.sdc        # Timing constraints (base clock + derive_pll_clocks)
└── tb/
│   ├── tb_line_buffer.v
│   ├── tb_window_3x3.v
│   └── tb_sobel_top.v
└── old_RTL/
   ├── image_rom.v           # Phase 3 (legacy): static 320x240  RGB test image ROM
   └── rom_addr_gen.v        # Phase 3 (legacy): VGA coord -> image_rom address
```

## Key components

**`Top-level Module`** (sobel_top.v)
- Full top level integration
- Streams a live computed test pattern through fll wired pipeline
- displays the result live on VGA at native 640x480@60Hz

**`Sobel level top wiring`** (sobel_core.v)
- Complete input/output math pipeline
- Connects data flow between the 3 pipeline stages `window_3x3` → `sobel_conv` → `gradient_sum`


**`Grayscale filter`** (grayscale.v)
- Converts RGB (24 bits) to grayscale (8 bits)
- Uses weighted average (BT.601 luma)

**`Line Buffer`** (line_buffer.v)
- Raster-scanned pixel stream (data arrives left to right, then wraps to next row)
- Stores exactly one row of pixels (full image width) 
- On every new input pixel, returns the pixel that was written at the same column -- i.e. the pixel directly ABOVE the current input pixel.

**`3x3 Sliding Window`** (window_3x3.v)
- Builds 3x3 pixel neighborhood from a single streaming pixel input
- Chains 2 line_buffer instances (vertical alignment) with column shift registers (horizontal alignment).

**`Gradient Convolution`** (sobel_conv.v)
- computes the Gx/Gy convolution from the 3x3 window via partial sums.

**`Gradient Sum`** (gradient_sum.v)
- computes `|Gx| + |Gy|`, saturated to 8-bit output.

**`VGA Controller`**  (vga_controller.v)
- free-running 640x480@60Hz VGA timing generator (active-low hsync/vsync), driven by a 25.175 MHz pixel clock.

**`Pattern Generation`** (pattern_gen.v)
- Computes an animated checkerboard directly from `(x, y, frame_phase)` 
- Live computer, no stored memory.

**Delay Chain** (delay_chain.v) 
- Parameterized shift register
- used to align `video_on`/sync signals with pipeline latency at different points in `sobel_top`.

**Static Test image**  (image_rom.v / rom_addr_gen.v)
- Phase 3 pixel source (legacy). Static 320x240 RGB image stored in on-chip ROM 
- Legacy testing


## Key Learnings

- TODO

## Future Work

**Live camera input** 

1. **Dedicated camera sensor module** (e.g. OV7670, Terasic D5M) via GPIO — outputs a raw parallel pixel stream with its own timing signals, no USB protocol involved. Stays entirely in FPGA fabric/Verilog, consistent with everything built so far; requires writing a `camera_capture` module analogous to `vga_controller` but for input.
2. **Real USB webcam via the DE1-SoC's HPS** (ARM Cortex-A9 running Linux) — meaningfully larger scope, involving Platform Designer/Qsys bus configuration, embedded Linux boot, V4L2 capture software, HPS-FPGA shared memory with cache coherency handling, a new Avalon-MM read interface in fabric, YUYV->RGB conversion, and a real frame buffer with double-buffering. Everything downstream of frame acquisition (`grayscale.v` onward) remains reusable either way.

**Threshold**
- Threshold for edge detection sensitivity

**Toggle**
- Button/Switch Toggle to edge detect otput

