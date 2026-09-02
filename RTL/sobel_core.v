//  top module - complete math pipeline

//   3 stages: i_pixel --> [window_3x3] --> [sobel_conv] --> [gradient_sum] --> o_pixel
//                        (signed Gx/Gy)      (|Gx|+|Gy|,

// latency: window_3x3 (4 cycles) + sobel_conv (2 cycles) + gradient_sum (2 cycles) = 8 cycles from a pixel entering i_data to its Sobel result coming out.

module sobel_core #(
    parameter integer DATA_WIDTH = 8,
    parameter integer IMG_WIDTH = 640
)(
    input wire clk,
    input wire rst_n,

    input wire [DATA_WIDTH-1:0] i_pixel,
    input wire i_valid, // grayscale pixel in

    output wire [DATA_WIDTH-1:0] o_pixel,
    output wire o_valid // Sobel edge magnitude out
);

// === stage 1 =====
// build 3x3 window of pixels from the input stream
wire win_valid;
wire [DATA_WIDTH-1:0] win_p00, win_p01, win_p02;
wire [DATA_WIDTH-1:0] win_p10, win_p11, win_p12;
wire [DATA_WIDTH-1:0] win_p20, win_p21, win_p22;

window_3x3 #(
    .DATA_WIDTH (DATA_WIDTH),
    .IMG_WIDTH (IMG_WIDTH)
) u_window_3x3 (
    .clk (clk),
    .rst_n (rst_n),
    .i_pixel (i_pixel),
    .i_valid (i_valid),

    .o_p00 (win_p00), .o_p01 (win_p01), .o_p02 (win_p02),
    .o_p10 (win_p10), .o_p11 (win_p11), .o_p12 (win_p12),
    .o_p20 (win_p20), .o_p21 (win_p21), .o_p22 (win_p22),
    .o_valid (win_valid)
);

// ====== stage 2 =======
// convolve window against Gx/Gy kernal.

wire conv_valid; 
wire signed [DATA_WIDTH+2:0] gx, gy;

    sobel_conv #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_sobel_conv (
        .clk (clk),
        .rst_n (rst_n),

        .i_valid (win_valid),
        .i_p00 (win_p00), .i_p01 (win_p01), .i_p02 (win_p02),
        .i_p10 (win_p10), .i_p11 (win_p11), .i_p12 (win_p12),
        .i_p20 (win_p20), .i_p21 (win_p21), .i_p22 (win_p22),
        
        .o_gx (gx),
        .o_gy (gy),
        .o_valid (conv_valid)
    );

// ====== stage 3 =======
// |Gx| + |Gy|

gradient_sum #(
    .DATA_WIDTH (DATA_WIDTH)
) u_gradient_sum (
    .clk (clk),
    .rst_n (rst_n),
 
    .i_gx (gx),
    .i_gy (gy),
    .i_valid (conv_valid),

    .o_mag (o_pixel),
    .o_valid (o_valid)
);
 
endmodule
