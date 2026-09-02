// streams a static 320x240 RGB test image (stored on-chip)
// // Pipeline:
//   image_rom (RGB) -> grayscale.v -> sobel_core.v -> VGA output

module sobel_top (
    input wire CLOCK_50,
    input wire RESET_N; // pushbutton

    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_CLK,
    output wire VGA_SYNC_N

);

// PLL 25.175 MHz per vga standard

wire pixel_clk;
wire pll_locked;

pll_vga u_pll (
    .refclk (CLOCK_50),
    .rst (~RESET_N),
    .outclk_0 (pixel_clk),
    .locked (pll_locked)
);

    wire rst_n = RESET_N & pll_locked;

// ============ VGA timing ============

wire hsync, vsync, video_on;
wire [9:0] vga_x, vga_y;

vga_controller u_vga (
    .clk (pixel_clk),
    .rst_n (rst_n),
    .hsync (hsync),
    .vsync (vsync),
    .video_on (video_on),
    .x (vga_x),
    .y (vga_y)
);

// static test image  320x240 RGB ROM
localparam IMG_WIDTH  = 320;
localparam IMG_HEIGHT = 240;
localparam ADDR_WIDTH = 17;

wire [ADDR_WIDTH-1:0] rom_addr_raw;
wire [ADDR_WIDTH-1:0] rom_addr = video_on ? rom_addr_raw : {ADDR_WIDTH{1'b0}};

rom_addr_gen #(
    .IMG_WIDTH (IMG_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) u_addr_gen (
    .vga_x (vga_x),
    .vga_y (vga_y),
    .rom_addr (rom_addr_raw)
);

wire [23:0] rom_pixel; // {R[7:0], G[7:0], B[7:0]}

 
image_rom #(
    .IMG_WIDTH (IMG_WIDTH),
    .IMG_HEIGHT (IMG_HEIGHT),
    .DATA_WIDTH (24),
    .ADDR_WIDTH (ADDR_WIDTH),
    .INIT_FILE ("image.hex")
) u_image_rom (
    .clk (pixel_clk),
    .addr(rom_addr),
    .data_out (rom_pixel)
);

// ++++++++++++++++++ Delay chain 1 +++++++++++++++++++
// video_on delayed 1 cycle to align with image_rom registered read output

wire video_on_d1;

delay_chain #(
    .WIDTH (1),
    .DEPTH (1)
) u_delay_video_on_1 (
    .clk (pixel_clk),
    .rst_n (rst_n),
    .din (video_on),
    .dout (video_on_d1)
);


// ===========+ Grayscale conversion +========
wire gray_valid;
wire [7:0] gray_pixel;

grayscale u_grayscale (
    .clk (pixel_clk),
    .rst_n (rst_n),
    .i_valid (video_on_d1),
    .i_r (rom_pixel[23:16]),
    .i_g (rom_pixel[15:8]),
    .i_b (rom_pixel[7:0]),
    .o_valid (gray_valid),
    .o_gray (gray_pixel)
);

// ============+ Sobel edge detect +==========
wire edge_valid;
wire [7:0] edge_pixel;

sobel_core #(
    .DATA_WIDTH (8),
    .IMG_WIDTH (IMG_WIDTH)
) u_sobel_core (
    .clk (pixel_clk),
    .rst_n (rst_n),
    .i_pixel (gray_pixel),
    .i_valid (gray_valid),
    .o_pixel (edge_pixel),
    .o_valid (edge_valid)
);


// +++++++++++++++++++ Sync delay chain 2: 9 cycles +++++++++++++++++++
wire [2:0] sync_bus_in  = {hsync, vsync, video_on};
wire [2:0] sync_bus_out;
wire hsync_d9, vsync_d9, video_on_d9;

delay_chain #(
    .WIDTH (3),
    .DEPTH (9)
) u_delay_sync_9 (
    .clk (pixel_clk),
    .rst_n (rst_n),
    .din (sync_bus_in),
    .dout (sync_bus_out)
);

assign {hsync_d9, vsync_d9, video_on_d9} = sync_bus_out;


// ============== VGA output==================

wire [7:0] display_pixel = video_on_d9 ? edge_pixel : 8'd0;

assign VGA_R = display_pixel;
assign VGA_G = display_pixel;
assign VGA_B = display_pixel;
assign VGA_HS = hsync_d9;
assign VGA_VS = vsync_d9;
assign VGA_BLANK_N = video_on_d9;
assign VGA_SYNC_N = 1'b0;     // unused composite sync, tied low
assign VGA_CLK = pixel_clk;

endmodule



