// chains  two line_buffer instances (vertical alignment ie p00 p10 p20)
//  with column shift registers (horizontal alignment).

module window_3x3 (
    input  wire clk,
    input  wire rst_n,
 
    input  wire [DATA_WIDTH-1:0] i_pixel,
    input  wire i_valid,
    
    output wire [DATA_WIDTH-1:0] o_p00, o_p01, o_p02,
    output wire [DATA_WIDTH-1:0] o_p10, o_p11, o_p12,
    output wire [DATA_WIDTH-1:0] o_p20, o_p21, o_p22
    output wire o_valid,
);

// step 1 -- vertical alignment (which row):
//   row0_raw = i_data itself            (current row, 0 reg delay)
//   row1_raw = line_buffer #1 output    (1 row up, 1 reg delay)
//   row2_raw = line_buffer #2 output    (2 rows up, 2 reg delays)


parameter DATA_WIDTH = 8,
parameter IMG_WIDTH  = 640

wire [DATA_WIDTH-1:0] lb_row1, lb_row2; // pxiel store: 1 row up, 2 rows up
wire lb1_valid, lb2_valid;


line_buffer lb_row1 (
    .clk (clk),
    .rst_n(rst_n),
    .i_pixel (i_pixel),
    .i_valid (i_valid), 
    .o_pixel (lb_row1),
    .o_valid (lb1_valid)
);

line_buffer lb_row2 (
    .clk (clk),
    .rst_n(rst_n),
    .i_pixel (lb_row1),
    .i_valid (lb1_valid),
    .o_pixel (lb_row2),
    .o_valid (lb2_valid)
);

// latency match row0 (+2 cycles) and row1 (+1 cycle) so all 3 rows 
// reach same col at same time

    reg [DATA_WIDTH-1:0] row0_align_1, row0_align_2;
    reg [DATA_WIDTH-1:0] row1_align_1;
    reg  valid_align_1, valid_align_2;

    always @(posedge clk) begin
        if (!rst_n) begin
            row0_align_1 <= {DATA_WIDTH{1'b0}};
            row0_align_2 <= {DATA_WIDTH{1'b0}};
            row1_align_1 <= {DATA_WIDTH{1'b0}};

            valid_align_1 <= 1'b0;
            valid_align_2 <= 1'b0;

        end else begin
            row0_align_1 <= i_pixel; //row 0 +1 ccycle
            row0_align_2 <= row0_align_1; // row0: +2 cycles total
            row1_align_1 <= lb_row1; // row1: +1 cycle

            valid_align_1 <= i_valid;
            valid_align_2 <= valid_align_1;
        end
    end

