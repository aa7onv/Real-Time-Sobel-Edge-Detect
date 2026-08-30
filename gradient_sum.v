//  Implements |Gx| + |Gy| gradient  magnitude approximation (final sobel)

module gradient_abssum #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,

    input wire signed [DATA_WIDTH+2:0] i_gx, from sobel_conv.v
    input wire signed [DATA_WIDTH+2:0] i_gy,
    input wire i_valid,

    output reg [DATA_WIDTH-1:0] o_mag, // 8-bit edge magnitude 
    output reg o_valid
);

localparam ABS_WIDTH = DATA_WIDTH + 2; // unsigned magnitude width (10 bits)
localparam SUM_WIDTH = DATA_WIDTH + 3;  // unsigned sum width (11 bits)

// abs values of gradients Gx and Gy
reg [ABS_WIDTH-1:0] abs_gx, abs_gy;
reg valid_abs;

always @(posedge clk) begin

end