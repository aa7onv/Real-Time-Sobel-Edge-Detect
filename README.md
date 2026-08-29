# Real-Time-Sobel-Edge-Detect
Practice Real Time Sobel Edge Detection FPGA Implementation

## References
https://en.wikipedia.org/wiki/Sobel_operator
Sobel Eddge Detection on FPGA.pdf

## Target Hardware

Developed and tested on **DE1-SOC** using **ModelSim** & **Intel Quartus**.

## Architecture Design

pixel stream in -> [ grayscale filter ] -> [ line buffers ] -> [ 3x3 sliding window ]
-> [ Gx Gy convolution ] -> [ Gradient Approx. ] -> [ Threshold]
-> pixel stream out

## Project Scope / Overview

## Key Design Decisions
-Will be using Grayscale, 8-bit pixel input
-`\|Gx\| + \|Gy\|` instead of `sqrt(Gx² + Gy²)`  to avoid an expensive sqrt; standard approximation with acceptable accuracy loss
-one pixel/clock | No stalling; required for real-time video-rate throughput

## Repository Outline 
```
├── rtl/
│   ├── grayscale.v            # weighted avg grayscale                        
│   ├── line_buffer.v          # Row-delay FIFOs
│   ├── window_gen.v           # 3x3 sliding window shift register
│   ├── sobel_conv.v           # Gx/Gy convolution units
│   ├── gradient_mag.v         # Magnitude approximation + threshold
│   └── sobel_top.v            # Top-level pipeline integration
└── tb/
    ├── tb_line_buffer.v
    ├── tb_window_gen.v
    └── tb_sobel_top.v
```

## Key components

Top-level Module (top.v)
- Connects input/output frame buffers with the Sobel filter
- Manages data flow between pipeline stages

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

