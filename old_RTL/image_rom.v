// stand in for live video. feed pixels into sobel pipeline for hardware bringup test. 
//holds one static 320×240 RGB image entirely in on-chip memory, and streams pixels out,one word per address ,similar to cam feed

// single-port synchronous ROM 
// Inferred on-chip memory (M10K), initialized at configuration time via
// $readmemh from a plain hex text file 
//
// Storage format: each 24-bit word is packed as {R[7:0], G[7:0], B[7:0]},
// one word per pixel, in row-major order (address = y * IMG_WIDTH + x).
//
// Read latency: 1 cycle (registered output), matching standard M10K
// synchronous-read behavior. This latency must be included when computing
// total pipeline latency for the VGA sync delay chain in sobel_top.

module image_rom #(
    parameter IMG_WIDTH  = 320,
    parameter IMG_HEIGHT = 240,
    parameter DATA_WIDTH = 24,
    parameter ADDR_WIDTH = 17,                 // ceil(log2(320*240)) = 17
    parameter INIT_FILE  = "../img/image.hex"
)(
    input  wire                    clk,
    input  wire [ADDR_WIDTH-1:0]   addr,
    output reg  [DATA_WIDTH-1:0]   data_out
);

    localparam DEPTH = IMG_WIDTH * IMG_HEIGHT; // 76800 words

    reg [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(INIT_FILE, rom);
    end

    always @(posedge clk) begin
        data_out <= rom[addr];
    end

endmodule