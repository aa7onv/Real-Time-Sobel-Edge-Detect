// chains  ie p00 p10 p20)
//  with column shift registers (horizontal alignment).

module window_3x3 #(
    parameter integer DATA_WIDTH = 8,
    parameter integer IMG_WIDTH  = 640
)(
    input  wire clk,
    input  wire rst_n,
 
    input  wire [DATA_WIDTH-1:0] i_pixel,
    input  wire i_valid,
    
    output wire [DATA_WIDTH-1:0] o_p00, o_p01, o_p02,
    output wire [DATA_WIDTH-1:0] o_p10, o_p11, o_p12,
    output wire [DATA_WIDTH-1:0] o_p20, o_p21, o_p22,
    output wire o_valid
);

// step 1 -- vertical alignment (which row):
//   row2_raw = line_buffer #2 output    (2 rows up, 2 reg delays)
//   row1_raw = line_buffer #1 output    (1 row up, 1 reg delay)
//   row0_raw = i_data itself            (current row, 0 reg delay)

//chained line buffers to give 1 row and 2 rows above current pixel (i_pixel)
wire [DATA_WIDTH-1:0] row1_raw, row2_raw; // pxiel store: 1 row up, 2 rows up. // single pixel handoffs
wire lb1_valid, lb2_valid;

line_buffer lb_row1 (
    .clk (clk),
    .rst_n(rst_n),
    .i_pixel (i_pixel),
    .i_valid (i_valid), 
    .o_pixel (row1_raw),
    .o_valid (lb1_valid)
);

line_buffer lb_row2 (
    .clk (clk),
    .rst_n(rst_n),
    .i_pixel (row1_raw),
    .i_valid (lb1_valid),
    .o_pixel (row2_raw),
    .o_valid (lb2_valid)
);

// latency match row0 (+2 cycles) and row1 (+1 cycle) so all 3 rows 
// reach same col at same time (matching delay of row2 which is already +2))

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
        // each register adds +1 cycle delay. 
        row0_align_1 <= i_pixel; //row 0 +1 ccycle
        row0_align_2 <= row0_align_1; // row0: +2 cycles total
        row1_align_1 <= row1_raw; // row1: +1 cycle

        valid_align_1 <= i_valid;
        valid_align_2 <= valid_align_1;
    end
end

// now verticall aligned.
// step 3 - horizonatl alignment 
// using shift registers to give 3 columns of each row (3x3 window)

wire [DATA_WIDTH-1:0] row0_col_c = row0_align_2; // current row
wire [DATA_WIDTH-1:0] row1_col_c = row1_align_1; // one row up
wire [DATA_WIDTH-1:0] row2_col_c = row2_raw;     // two rows up
wire aligned_valid = valid_align_2;

reg [DATA_WIDTH-1:0] row0_c1, row0_c2;
reg [DATA_WIDTH-1:0] row1_c1, row1_c2;
reg [DATA_WIDTH-1:0] row2_c1, row2_c2;
reg win_valid_1, win_valid_2;

always @(posedge clk) begin
    if (!rst_n) begin
        row0_c1 <= {DATA_WIDTH{1'b0}};  row0_c2 <= {DATA_WIDTH{1'b0}};
        row1_c1 <= {DATA_WIDTH{1'b0}};  row1_c2 <= {DATA_WIDTH{1'b0}};
        row2_c1 <= {DATA_WIDTH{1'b0}};  row2_c2 <= {DATA_WIDTH{1'b0}};
        win_valid_1 <= 1'b0;
        win_valid_2 <= 1'b0;
    end else begin
        // 2 cycles of delay for each row to get 2 extra past columns
        row0_c1 <= row0_col_c;  
        row0_c2 <= row0_c1;

        row1_c1 <= row1_col_c;  
        row1_c2 <= row1_c1;

        row2_c1 <= row2_col_c;  
        row2_c2 <= row2_c1;

        win_valid_1 <= aligned_valid;
        win_valid_2 <= win_valid_1;
    end
end

// final output assignment
assign o_p00 = row2_c2;      assign o_p01 = row2_c1;      assign o_p02 = row2_col_c;
assign o_p10 = row1_c2;      assign o_p11 = row1_c1;      assign o_p12 = row1_col_c;
assign o_p20 = row0_c2;      assign o_p21 = row0_c1;      assign o_p22 = row0_col_c;

assign o_valid = win_valid_2;

endmodule
