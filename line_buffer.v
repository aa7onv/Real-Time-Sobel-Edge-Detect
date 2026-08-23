module line_buffer(
    // Outputs
    pixel_00, pixel_01, pixel_02,
    pixel_10, pixel_11, pixel_12,
    pixel_20, pixel_21, pixel_22,
    // Inputs
    clk, rst, pixel_in, en, row, col
);

    // clock, reset
    input clk;
    input rst;

    // pixel input
    input [7:0] pixel_in;
    input enable;
    input [7:0] row_count;
    input [7:0] col_count;

    // 3x3 neighborhood output
    output [7:0] pixel_00, pixel_01, pixel_02;
    output [7:0] pixel_10, pixel_11, pixel_12;
    output [7:0] pixel_20, pixel_21, pixel_22;