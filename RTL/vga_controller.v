//VGA industry standard 640×480 @ 60Hz
// 25.175 MHz pixel clock

///=============
//              horiz   vert
//Front porch:	16	    10
//Sync pulse:	96	    2
//Back porch:	48	    33
// ^^ blanking intervals ( no data sent)
//Total cycles: 800     525
//=========

module vga_controller (
    input wire clk,        // 25.175 MHz pixel clock (PLL)
    input wire rst_n,
    output reg hsync,   // VGA timing ref
    output reg vsync,   // VGA timing ref
    output reg video_on,  // timing for free running x,y
    output reg [9:0] x, // 0-639, 
    output reg [9:0] y  // 0-479,  
);

// =======================
// Horizontal Timing (in pixels)
//=========================
localparam H_ACTIVE = 640;
localparam H_FRONT_PORCH = 16;
localparam H_SYNC_PULSE = 96;
localparam H_BACK_PORCH = 48;
localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // 800

localparam H_SYNC_START =  H_FRONT_PORCH + H_ACTIVE;         // 656
localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;         // 752

// ========================
// Vertical timing (in lines)
// =======================
localparam V_ACTIVE= 480;
localparam V_FRONT_PORCH = 10;
localparam V_SYNC_PULSE = 2;
localparam V_BACK_PORCH = 33;
localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // 525

localparam V_SYNC_START = V_ACTIVE + V_FRONT_PORCH;      // 490
localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;     // 492


// --------- COUNTERS -------------

// x, y counters to track if active zone or dead zone
reg [9:0] h_count; // 0 <-> H_TOTAL-1 (0 - 799)
reg [9:0] v_count; // 0 <-> V_TOTAL-1 (0 - 524)

wire h_count_max = (h_count == H_TOTAL - 1);
wire v_count_max = (v_count == V_TOTAL - 1);

// horizontal counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        h_count <= 10'd0;
    else if (h_count_max)
        h_count <= 10'd0;
    else
        h_count <= h_count + 10'd1;
end

// vertical counter (advances once per completed horizontal line)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        v_count <= 10'd0;
    else if (h_count_max) begin
        if (v_count_max)
            v_count <= 10'd0;
        else
            v_count <= v_count + 10'd1;
    end
end

// ----------------------

//==============
// Sync Gen
//============

// is h_count inside [H_SYNC_START , H_SYNC_END) window
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        hsync <= 1'b1;
    else
        hsync <= ~((h_count >= H_SYNC_START) && (h_count < H_SYNC_END));
end

// is v_count inside [V_SYNC_START , V_SYNC_END) window
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        vsync <= 1'b1;
    else
        vsync <= ~((v_count >= V_SYNC_START) && (v_count < V_SYNC_END));
end

// ========================
// Active video region flag
// ========================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        video_on <= 1'b0;
    else
        video_on <= (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
end

//========================
// Free-running pixel coordinates
    // maybe fold x <= h_count; y <= v_count; directly into their respective counter blocks above?
// ========================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x <= 10'd0;
        y <= 10'd0;
    end else begin
        x <= h_count;
        y <= v_count;
    end
end
endmodule