L// stores one row of pixels and returns the pixel that is directly above the current pixel
// notes: even though conv is 3x3, need full img-width to guarantee the
//  value you overwrite is exactly the value you no longer need (the row above)
module line_buffer (
    input clk,
    input rst_n,

    input [7:0] i_pixel,
    input i_valid,
    output reg [7:0] o_pixel,
    output reg o_valid
);

    localparam ADDR_WIDTH = $clog2(IMG_WIDTH);
    localparam integer DATA_WIDTH = 8; // 8-> 0-255 grayscale
    localparam integer IMG_WIDTH = 8; // 640 pixels per row ***Set to 8 for TB***

    // mem[] circular buffer, read the pixel  written 1 cycle ago before overwtiting
    reg [DATA_WIDTH-1:0] mem [0:IMG_WIDTH-1]; // [one row of storage] 640 pixels with 8 bits each
    reg [ADDR_WIDTH-1:0] col_index;

    always @(posedge clk) begin
        if (!rst_n) begin
            col_index <= {ADDR_WIDTH{1'b0}};
            o_pixel <= {DATA_WIDTH{1'b0}};
            o_valid <= 1'b0;
        end else if (i_valid) begin
            // READ old value at this col = row above
            o_pixel <= mem[col_index]; 
            o_valid <= 1'b1;

            // WRITE: store curr pixel for next row
            mem[col_index] <= i_pixel;

            // advance col pointer, & wrap at end of row
            if (col_index == IMG_WIDTH-1)
                col_index <= {ADDR_WIDTH{1'b0}};
            else
                col_index <= col_index + 1'b1;
        end else begin
            o_valid <= 1'b0;

        end
    end


endmodule