// convert RGB (24 bits) to grayscale (8 bits)
// weighted average: 0.299*R + 0.587*G + 0.114*B (BT.601 luma)
module gray_scale (
    input clk,
    input rst_n,

    input i_valid,
    input [7:0] i_r,
    input [7:0] i_g,
    input [7:0] i_b,

    output reg o_valid,
    output reg [7:0] o_gray
);
    localparam integer DATA_WIDTH = 8; // 8-> 0-255 grayscale

// luma weights
    localparam integer weight_red = 77;   // 0.299 * 256, rounded
    localparam integer weight_green = 150;  // 0.587 * 256, rounded
    localparam integer weight_blue = 29;   // 0.114 * 256, rounded

    // Max sum = 77*255 + 150*255 + 29*255 = 65280 -> fits in 16 bits
    localparam integer SUM_WIDTH = 16; //unsigned multiplication sum width. (2*DATA_WIDTH)

    /// ========= \\\\ setup complete
    reg [15:0] sum_stage; 
    reg valid_stage;

    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stage <= {SUM_WIDTH{1'b0}};
            valid_stage <= 1'b0;
            o_gray <= {DATA_WIDTH{1'b0}};
            o_valid <= 1'b0;
        end else begin
            // weighted multiplication and sum
            sum_stage <= (weight_red * i_r) + (weight_green * i_g) + (weight_blue * i_b);
            valid_stage <= i_valid;

            // divide by 256 (right shift)
            o_gray <= sum_stage[15:8]; // keeping upper 8 bits
            o_valid <= valid_stage;
        end
    end
endmodule

// can reduce by removing localparams, or paramertize code later. doing half of each rn cause it made sense while writing.