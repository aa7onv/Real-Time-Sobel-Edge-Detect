// delays bus width by fixed amout

// delay 1 video_on for image_rom
// delay 9 hsync, vsync, video_on for full 9-cycle pipeline 

module delay_chain #(
    parameter WIDTH = 1,
    parameter DEPTH = 9
)(
    input  wire  clk,
    input  wire  rst_n,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

integer i;
reg [WIDTH-1:0] shift_reg [0:DEPTH-1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1)
            shift_reg[i] <= {WIDTH{1'b0}};
    end else begin
        shift_reg[0] <= din;
        for (i = 1; i < DEPTH; i = i + 1)
            shift_reg[i] <= shift_reg[i-1];
    end
end

assign dout = shift_reg[DEPTH-1];

endmodule
