# Real-Time-Sobel-Edge-Detect
Practice Real Time Sobel Edge Detection FPGA Implementation

# References
https://en.wikipedia.org/wiki/Sobel_operator
Sobel Eddge Detection on FPGA.pdf

# Project Scope & Design Decisions
-Will be using Grayscale, 8-bit pixel input
-`\|Gx\| + \|Gy\|` instead of `sqrt(Gx² + Gy²)`  to avoid an expensive sqrt; standard approximation with acceptable accuracy loss
-one pixel/clock | No stalling; required for real-time video-rate throughput

# Project Outline 
```
├── rtl/
│   ├── line_buffer.v          # Row-delay FIFOs
│   ├── window_gen.v           # 3x3 sliding window shift register
│   ├── sobel_conv.v           # Gx/Gy convolution units
│   ├── gradient_mag.v         # Magnitude approximation + threshold
│   └── sobel_top.v            # Top-level pipeline integration
└── tb/
│   ├── tb_line_buffer.v
│   ├── tb_window_gen.v
│   └── tb_sobel_top.v
```

## Target Hardware

Developed and tested on **DE1-SOC** using **ModelSim & Intel Quartus**.
