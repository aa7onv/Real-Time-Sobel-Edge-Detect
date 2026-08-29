//// Kernels:
//   Gx = [-1  0  1]      Gy = [ 1  2  1]
//        [-2  0  2]           [ 0  0  0]
//        [-1  0  1]           [-1 -2 -1]

module sobel_conv #(
    parameter PIXEL_WIDTH = 8, //  8 = grayscale
    parameter GRAD_WIDTH = 11 // 
);

    input wire clk,
    input wire rst,
    input wire en,

    //3x3 pixel window p<row><col>
    input wire [PIXEL_WIDTH-1:0] p00, p01, p02,
    input wire [PIXEL_WIDTH-1:0] p10, p11, p12,
    input wire [PIXEL_WIDTH-1:0] p20, p21, p22,

    output reg  signed [GRAD_WIDTH-1:0]  gx,
    output reg  signed [GRAD_WIDTH-1:0]  gy,
    output reg valid_out //data is good
