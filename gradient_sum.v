//  Implements |Gx| + |Gy| gradient  magnitude approximation (final sobel)

module gradient_sum #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,

    input wire signed [DATA_WIDTH+2:0] i_gx, // from sobel_conv.v,
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
    if (!rst_n) begin
        abs_gx   <= {ABS_WIDTH{1'b0}};
        abs_gy   <= {ABS_WIDTH{1'b0}};
        valid_abs <= 1'b0;
    end else begin
        // negate if negative (sing bit =1)
        abs_gx <= i_gx[DATA_WIDTH+2] ? -i_gx : i_gx;
        abs_gy <= i_gy[DATA_WIDTH+2] ? -i_gy : i_gy;
        valid_abs <= i_valid;
    end
end

// sum the absolute values. clamp value > 255 back down to 255.
wire [SUM_WIDTH-1:0] sum = abs_gx + abs_gy;
localparam [SUM_WIDTH-1:0] MAX_VAL = {DATA_WIDTH{1'b1}};

always @(posedge clk) begin
    if (!rst_n) begin
        o_mag <= {DATA_WIDTH{1'b0}};
        o_valid <= 1'b0;
    end else begin
        // sum the absolute values, and truncate to 8 bits (max = 1020)
        o_mag <= (sum > MAX_VAL) ? {DATA_WIDTH{1'b1}} : sum[DATA_WIDTH-1:0];
        o_valid <= valid_abs;
    end
end

endmodule

