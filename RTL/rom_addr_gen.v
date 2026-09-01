// vga controller uses 640×480 coordinates. image rom only holds 320×240 image. 
// rom_addr_gen translates the 2 by halving each vga coord so we get valid pixel addr

//combinational
// maps free-running VGA pixel coordinates (0-639, 0-479) down to a
// 320x240 image_rom address, implementing 2x pixel replication
// (each stored pixel is displayed as a 2x2 block, exactly filling the
// 640x480 screen since 320*2=640 and 240*2=480).


// addr = rom_y * 320 + rom_x, computed via shift-add
// (320 = 256 + 64 = 2^8 + 2^6) instead of a real multiplier.

module rom_addr_gen #(
    parameter IMG_WIDTH = 320,
    parameter ADDR_WIDTH = 17
)(
    input  wire [9:0]              vga_x,      // 0-639
    input  wire [9:0]              vga_y,      // 0-479
    output wire [ADDR_WIDTH-1:0]   rom_addr
);
 
    // 2x downscale: drop the low bit of each coordinate
    wire [8:0] rom_x = vga_x[9:1];  // 0-319
    wire [8:0] rom_y = vga_y[9:1];  // 0-239
 
    // rom_addr = rom_y * IMG_WIDTH + rom_x
    // IMG_WIDTH = 320 = (1 << 8) + (1 << 6), so multiply-by-320 becomes
    // a shift-add: (rom_y << 8) + (rom_y << 6)
    wire [ADDR_WIDTH-1:0] row_base = ({7'd0, rom_y} << 8) + ({7'd0, rom_y} << 6);
 
    assign rom_addr = row_base + {8'd0, rom_x};
 
endmodule
