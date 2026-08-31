//// Kernels:
//   Gx = [-1  0  1]        Gy = [ 1  2  1]
//        [-2  0  2] * A         [ 0  0  0] * A
//        [-1  0  1]             [-1 -2 -1]

//     Gx = (right column: p02 + 2*p12 + p22) - (left column: p00 + 2*p10 + p20)
//     Gy = (bottom row:   p20 + 2*p21 + p22) - (top row:     p00 + 2*p01 + p02)

//no magnitude or thresholding for now. just outputing the signed Gx and Gy values.
module sobel_conv #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    
    input wire [DATA_WIDTH-1:0] i_p00, i_p01, i_p02,
    input wire [DATA_WIDTH-1:0] i_p10, i_p11, i_p12,
    input wire [DATA_WIDTH-1:0] i_p20, i_p21, i_p22,
    input wire i_valid,

    output reg signed [DATA_WIDTH+2:0] o_gx, //bits are unsigned (0 to 1020) 
    output reg signed [DATA_WIDTH+2:0] o_gy, // difference ranges -1020 to +1020. 
    output reg o_valid
);

localparam SUM_WIDTH = DATA_WIDTH + 2; // worst case is 255 + 2*255 + 255 = 1020


// row/col sums
reg [SUM_WIDTH-1:0] left_col, right_col;
reg [SUM_WIDTH-1:0] top_row, bot_row;
reg valid_sum1;

always @(posedge clk) begin
    if (!rst_n) begin
        top_row <= {SUM_WIDTH{1'b0}};
        bot_row <= {SUM_WIDTH{1'b0}};
        left_col <= {SUM_WIDTH{1'b0}};
        right_col <= {SUM_WIDTH{1'b0}};
        valid_sum1  <= 1'b0;
    end else begin
        // skip multiplier hardware with left-shift 
        top_row <= i_p00 + (i_p01 << 1) + i_p02;
        bot_row <= i_p20 + (i_p21 << 1) + i_p22;
        left_col <= i_p00 + (i_p10 << 1) + i_p20;
        right_col <= i_p02 + (i_p12 << 1) + i_p22;

        valid_sum1  <= i_valid;
    end
end

// subtract into signed Gx / Gy
always @(posedge clk) begin
    if (!rst_n) begin
        o_gx <= {(DATA_WIDTH+3){1'b0}};
        o_gy <= {(DATA_WIDTH+3){1'b0}};
        o_valid <= 1'b0;
    end else begin
        // zero-extend the unsigned sums by 1 bit before subtracting,
        o_gx <= $signed({1'b0, right_col}) - $signed({1'b0, left_col});
        o_gy <= $signed({1'b0, bot_row}) - $signed({1'b0, top_row});
        o_valid <= valid_sum1;
    end
end

endmodule
 
