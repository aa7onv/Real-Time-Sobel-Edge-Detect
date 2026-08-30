// loads img converted to .mif and streams it through sobel_core and writes second .mif to output
// // parses .mif with NO header. needs mif_to_img.py

// params: 
//     IMG_WIDTH   -- must match your actual image's pixel width. The .mif
//      INPUT_FILE  -- path to the .mif produced by img_to_mif.py
//       OUTPUT_FILE -- path to write the result .mif to

// sobel_core produces 'x'  for first couple rows/cols per frame since neighbor pixels dont exist
// testbench subsitutes 0 for any x output
// temp soln for initial visual testing. not real border-handling soln.

`timescale 1ns/1ps
 
module tb_sobel_core;
 
    // ---- EDIT THESE ----
    localparam DATA_WIDTH = 8;
    localparam IMG_WIDTH = 640;  // <-- SET TO YOUR IMAGE WIDTH
    localparam INPUT_FILE = "img_grayscale_mif.mif";
    localparam OUTPUT_FILE = "img_output_mif.mif";
    // ---------------------
 
    localparam CLK_PERIOD = 10;
    localparam PIPE_LATENCY = 8;   // window_3x3(4) + sobel_conv(2) + gradeint_sum(2)
    localparam FLUSH_CYCLES = PIPE_LATENCY + 8;  // small margin beyond the known latency
 
    reg clk;
    reg rst_n;
    reg i_valid;
    reg [DATA_WIDTH-1:0] i_pixel;
    wire o_valid;
    wire [DATA_WIDTH-1:0] o_pixel;
 
    integer depth;
    integer in_file, out_file;
    integer addr;
    integer scanned;
    integer header_line;
    reg [8*256-1:0] discard_line;
 
    reg [DATA_WIDTH-1:0] pix_mem [0:1048575];  // oversized scratch buffer
    reg [DATA_WIDTH-1:0] out_mem [0:1048575];
 
    integer t;
    integer out_count;
    reg sanitized_x;
 
    // ---- unit under test ----
    sobel_core #(
        .DATA_WIDTH (DATA_WIDTH),
        .IMG_WIDTH (IMG_WIDTH)
    ) uut (
        .clk (clk),
        .rst_n (rst_n),
        .i_valid (i_valid),
        .i_pixel (i_pixel),
        
        .o_pixel (o_pixel),
        .o_valid (o_valid)
    );
 
    // ---- Clock generation ----
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // -------------------------------------------------------------------
    // Load the real image from the .mif file
    // -------------------------------------------------------------------
    initial begin
        in_file = $fopen(INPUT_FILE, "r");
        if (in_file == 0) begin
            $display("ERROR: could not open %s", INPUT_FILE);
            $finish;
        end
 
        // Line 1: pull DEPTH out of "DEPTH = <n>;"
        header_line = $fgets(discard_line, in_file);
        scanned = $sscanf(discard_line, "DEPTH = %d", depth);
        if (scanned != 1) begin
            $display("ERROR: could not parse DEPTH from first .mif line");
            $finish;
        end
        $display("Parsed DEPTH = %0d pixels from %s", depth, INPUT_FILE);
 
        // Lines 2-6: WIDTH=, ADDRESS_RADIX=, DATA_RADIX=, CONTENT, BEGIN
        // -- discarded as fixed boilerplate.
        header_line = $fgets(discard_line, in_file);
        header_line = $fgets(discard_line, in_file);
        header_line = $fgets(discard_line, in_file);
        header_line = $fgets(discard_line, in_file);
        header_line = $fgets(discard_line, in_file);
 
        // Content section: "addr : hexval;" per pixel
        for (t = 0; t < depth; t = t + 1) begin
            scanned = $fscanf(in_file, "%d : %h ;", addr, pix_mem[t]);
            if (scanned != 2) begin
                $display("ERROR: failed to parse pixel %0d from %s", t, INPUT_FILE);
                $finish;
            end
        end
 
        $fclose(in_file);
        $display("Loaded %0d pixels. IMG_WIDTH is set to %0d -- verify this matches your image.",
                  depth, IMG_WIDTH);
    end
 
    // -------------------------------------------------------------------
    // Stream the image through sobel_core, capture the result
    // -------------------------------------------------------------------
    initial begin
        out_count = 0;
        rst_n     = 1'b0;
        i_valid   = 1'b0;
        i_pixel   = {DATA_WIDTH{1'b0}};
 
        // Wait for the file-load block above to finish before streaming
        wait (depth != 0);
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
 
        for (t = 0; t < depth + FLUSH_CYCLES; t = t + 1) begin
            @(posedge clk);
            if (t < depth) begin
                i_valid <= 1'b1;
                i_pixel <= pix_mem[t];
            end else begin
                i_valid <= 1'b0;
            end
            #1;
 
            if (o_valid && out_count < depth) begin
                // Sanitize X (pipeline warm-up garbage) to 0 -- stopgap
                // stand-in for real border handling, see file header note.
                sanitized_x = (^o_pixel === 1'bx);
                out_mem[out_count] = sanitized_x ? {DATA_WIDTH{1'b0}} : o_pixel;
                out_count = out_count + 1;
            end
        end
 
        if (out_count != depth)
            $display("WARNING: captured %0d output pixels, expected %0d -- increase FLUSH_CYCLES",
                      out_count, depth);
        else
            $display("Captured all %0d output pixels.", out_count);
 
        // -----------------------------------------------------------------
        // Write the result back out as a .mif, matching the input's header
        // style, so mif_to_img.py can render it directly.
        // -----------------------------------------------------------------
        out_file = $fopen(OUTPUT_FILE, "w");
        if (out_file == 0) begin
            $display("ERROR: could not open %s for writing", OUTPUT_FILE);
            $finish;
        end
 
        $fdisplay(out_file, "DEPTH = %0d;", depth);
        $fdisplay(out_file, "WIDTH = %0d;", DATA_WIDTH);
        $fdisplay(out_file, "ADDRESS_RADIX = UNS;");
        $fdisplay(out_file, "DATA_RADIX = HEX;");
        $fdisplay(out_file, "CONTENT");
        $fdisplay(out_file, "BEGIN");
        for (t = 0; t < depth; t = t + 1)
            $fdisplay(out_file, "%0d : %02h;", t, out_mem[t]);
        $fdisplay(out_file, "END;");
        $fclose(out_file);
 
        $display("Wrote result to %s", OUTPUT_FILE);
        $finish;
    end
 
endmodule

 