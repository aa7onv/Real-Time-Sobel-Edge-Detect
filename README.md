# Real-Time-Sobel-Edge-Detect
Practice Real Time Sobel Edge Detection FPGA Implementation

## References
https://en.wikipedia.org/wiki/Sobel_operator
Sobel Eddge Detection on FPGA.pdf

## Target Hardware

Developed and tested on **DE1-SOC** using **ModelSim** & **Intel Quartus**.

## Architecture Design

pixel stream in -> [ grayscale filter ] -> [ line buffers ] -> [ 3x3 sliding window ]
-> [ Gx Gy convolution ] -> [ Gradient Approx. ] -> pixel stream out

## Project Scope / Overview

## Key Design Decisions
-Will be using Grayscale, 8-bit pixel input
-`\|Gx\| + \|Gy\|` instead of `sqrt(Gx² + Gy²)`  to avoid an expensive sqrt; standard approximation with acceptable accuracy loss
-one pixel/clock | No stalling; required for real-time video-rate throughput
- no thresholding. Would lose visual detail of how strong each edge is.

## Repository Outline 
```
├── rtl/
│   ├── grayscale.v            # weighted avg grayscale                        
│   ├── line_buffer.v          # Row-delay FIFOs
│   ├── window_3x3.v           # 3x3 sliding window shift register
│   ├── sobel_conv.v           # Gx/Gy convolution units
│   ├── gradient_sum.v         # |Gx| + |Gy| Sobel Approximation
│   └── sobel_core.v           # Top-level pipeline integration
└── tb/
    ├── tb_line_buffer.v
    ├── tb_window_3x3.v
    └── tb_sobel_top.v
```

## Key components

Top-level Module (sobel_core.v)
- Complete input/output math pipeline
- Connects data flow between the 3 pipeline stages 
- Outputs edge detected file when converted back to jpg

Grayscale filter (grayscale.v)
- Converts RGB (24 bits) to grayscale (8 bits)
- Uses weighted average (BT.601 luma)

Line Buffer (line_buffer.v)
- Raster-scanned pixel stream (data arrives left to right, then wraps to next row)
- Stores exactly one row of pixels (full image width) 
- On every new input pixel, returns the pixel that was written at the same column -- i.e. the pixel directly ABOVE the current input pixel.

3x3 Sliding Window (window_3x3.v)
- Builds 3x3 pixel neighborhood from a single streaming pixel input
- Chains 2 line_buffer instances (vertical alignment) with column shift registers (horizontal alignment).

Gradient Convolution (sobel_conv.v)
- Computes partial sums and subtract into signed Gx / Gy

TODO:
Phase 1 - DONE
-Core pixel stream datapath pipeline works.can see edge output on static images, simulation only
Phase 2 - WORKING
-Static image on real DE1-SoC hardware.

Phase 4 - timing
Phase 5- Live video

