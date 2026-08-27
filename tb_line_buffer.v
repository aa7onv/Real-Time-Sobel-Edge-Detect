`timescale 1ns/1ps

module tb_line_buffer;
 
    localparam DATA_WIDTH = 8;
    localparam IMG_WIDTH  = 8;   // CHANGE TO 8 IN line_buffer.v FOR TESTING
    localparam CLK_PERIOD = 10;

    reg clk;
    reg rst_n;

    reg [DATA_WIDTH-1:0] i_pixel;
    reg i_valid;
    
    wire [DATA_WIDTH-1:0] o_pixel;
    wire o_valid;

    reg [DATA_WIDTH-1:0] row0 [0:IMG_WIDTH-1]; 
    reg [DATA_WIDTH-1:0] row1 [0:IMG_WIDTH-1];

    // UUT
    line_buffer uut (
        .clk (clk),
        .rst_n (rst_n),
        
        .i_data (i_pixel),
        .i_valid (i_valid),
        .o_data (o_pixel)
        .o_valid ( o_valid),
    );

    // ---- clock gen ----
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // testbench init
    initial begin
        row0[0]=10; row0[1]=20; row0[2]=30; row0[3]=40;
        row0[4]=50; row0[5]=60; row0[6]=70; row0[7]=80;

        row1[0]=11; row1[1]=21; row1[2]=31; row1[3]=41;
        row1[4]=51; row1[5]=61; row1[6]=71; row1[7]=81;
    end

