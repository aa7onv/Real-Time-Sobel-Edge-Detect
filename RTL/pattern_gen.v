// animated test pattern (replacing image_rom +
// rom_addr_gen). Live compute, not stored. 640x480 @60Hz

//Shifting checkeRboard pattern. 
// 1 cycle registered output

module pattern_gen #(
    parameter BLOCK_SIZE  = 32,  
    parameter SHIFT = 5,    
    parameter PHASE_WIDTH = 6     
)(
    input wire clk,
    input wire rst_n,
    input wire vsync,    
    input wire [9:0] x,   // 0-639
    input wire [9:0] y,  // 0-479
    output reg  [23:0] data_out  // {R[7:0], G[7:0], B[7:0]}
);

// Frame boundary detection: falling edge of active-low vsync marks
// the start of a new frame's vertical sync pulse.
reg vsync_prev;
wire vsync_falling = vsync_prev & !vsync;

reg [PHASE_WIDTH-1:0] frame_phase;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_prev  <= 1'b1;
        frame_phase <= {PHASE_WIDTH{1'b0}};
    end else begin
        vsync_prev <= vsync;
        if (vsync_falling)
            frame_phase <= frame_phase + 1'b1; // wraps naturally at 2^PHASE_WIDTH
    end
end

// ============
// Diagonal shift
// =============
wire [9:0] shifted_x = x + {{(10-PHASE_WIDTH){1'b0}}, frame_phase};
wire [9:0] shifted_y = y + {{(10-PHASE_WIDTH){1'b0}}, frame_phase};


// XOR of the
// column and row parity bits gives the standard alternating pattern.
wire col_parity = shifted_x[SHIFT];
wire row_parity = shifted_y[SHIFT];
wire checker = col_parity ^ row_parity;

localparam [23:0] WHITE = 24'hFFFFFF;
localparam [23:0] BLACK = 24'h000000;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 24'd0;
    else
        data_out <= checker ? WHITE : BLACK;
end
 
endmodule


