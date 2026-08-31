//  feed a known test image, one pixel per cycle, 
//  each pixels value is its own index:  
//  (pix[0], pix[1], pix[IMG_WIDTH-1] = row 0; 
//   pix[IMG_WIDTH], ..., pix[2*IMG_WIDTH-1] = row 1;  and so on)

//   This makes checking trivial: expected neighbors of any
//   pixel at index `idx` are just (W = IMG_WIDTH):
//
//        top-left=idx-W-1   top=idx-W    top-right=idx-W+1
//        left=idx-1         CENTER=idx   right=idx+1
//        bot-left=idx+W-1   bot=idx+W    bot-right=idx+W+1

// timing:
//   window_3x3 p11 (window center) carries a total delay of
//   (IMG_WIDTH + 3) cycles from i_pixel:
//     lb_row1 (1 cycle) -> row1_align_1 (+1) -> row1_c1 (+1) = W + 3
//   at absolute input cycle t (i_pixel = pix[t]), the pixel currently
//   sitting at the window's CENTER is pix[t - IMG_WIDTH - 3].
//

`timescale 1ns/1ps

module tb_window_3x3;

    localparam DATA_WIDTH = 8;
    localparam IMG_WIDTH = 8;  
    localparam NUM_PIXELS = 4 * IMG_WIDTH; //feeds to test image
    localparam CLK_PERIOD = 10;
    localparam FLUSH_CYCLES = 6;  // extra cycles to finish processing the last few pixels after the last real pixel

    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] i_pixel;
    reg  i_valid;
    
    wire [DATA_WIDTH-1:0] o_p00, o_p01, o_p02;
    wire [DATA_WIDTH-1:0] o_p10, o_p11, o_p12;
    wire [DATA_WIDTH-1:0] o_p20, o_p21, o_p22;
    wire o_valid;

    integer errors;
    integer idx;

    reg [DATA_WIDTH-1:0] pix [0:NUM_PIXELS-1];  // known test image

    // instantiate uut
    window_3x3 #(
        .DATA_WIDTH (DATA_WIDTH),
        .IMG_WIDTH  (IMG_WIDTH)
    ) uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .i_pixel  (i_pixel),
        .i_valid (i_valid),

        .o_p00 (o_p00), .o_p01 (o_p01), .o_p02 (o_p02),
        .o_p10 (o_p10), .o_p11 (o_p11), .o_p12 (o_p12),
        .o_p20 (o_p20), .o_p21 (o_p21), .o_p22 (o_p22),
        .o_valid (o_valid)
    );

    // clock gen
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // set test image pixels == its own linear index \ pix[0] = 0, pix[1] = 1, ..., pix[31] = 31
    integer p;
    initial begin
        for (p = 0; p < NUM_PIXELS; p = p + 1)
            pix[p] = p[DATA_WIDTH-1:0];
    end
 
    // Compares all 9 pix against the known image, given the linear index
    // of the pixel currently at the window's CENTER. 
    task check_window(input integer center_idx);
        reg skip; // skips checks near the stream's start/end where a neighbor doesn't exist.
        begin
            skip = (center_idx - IMG_WIDTH - 1 < 0) ||
                   (center_idx + IMG_WIDTH + 1 > NUM_PIXELS - 1);

            if (!skip) begin
                if (!o_valid) begin
                    $display("ERROR @%0t: center_idx=%0d expected o_valid=1, got 0", $time, center_idx);
                    errors = errors + 1;
                end else if (o_p00 !== pix[center_idx-IMG_WIDTH-1] ||
                             o_p01 !== pix[center_idx-IMG_WIDTH]   ||
                             o_p02 !== pix[center_idx-IMG_WIDTH+1] ||
                             o_p10 !== pix[center_idx-1]           ||
                             o_p11 !== pix[center_idx]             ||
                             o_p12 !== pix[center_idx+1]           ||
                             o_p20 !== pix[center_idx+IMG_WIDTH-1] ||
                             o_p21 !== pix[center_idx+IMG_WIDTH]   ||
                             o_p22 !== pix[center_idx+IMG_WIDTH+1]) begin

                    $display("ERROR @%0t: center_idx=%0d window mismatch", $time, center_idx);
                    $display("   got: %0d %0d %0d / %0d %0d %0d / %0d %0d %0d",
                              o_p00, o_p01, o_p02, o_p10, o_p11, o_p12, o_p20, o_p21, o_p22);
                    $display("   exp: %0d %0d %0d / %0d %0d %0d / %0d %0d %0d",
                              pix[center_idx-IMG_WIDTH-1], pix[center_idx-IMG_WIDTH], pix[center_idx-IMG_WIDTH+1],
                              pix[center_idx-1],           pix[center_idx],           pix[center_idx+1],
                              pix[center_idx+IMG_WIDTH-1], pix[center_idx+IMG_WIDTH], pix[center_idx+IMG_WIDTH+1]);
                    errors = errors + 1;
                end else begin
                    $display("PASS  @%0t: center_idx=%0d window matches expected 3x3 block",
                              $time, center_idx);
                end
            end
        end
    endtask

    // ---- Stimulus + checking ----
    integer t;
    initial begin
        errors  = 0;
        rst_n   = 1'b0;
        i_valid = 1'b0;
        i_pixel  = {DATA_WIDTH{1'b0}};

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // feed the whole test image, one pixel per cycle, then hold
        // i_valid low for a few extra cycles to let the last few pixels
        // drain through the pipeline far enough to be checked.
        for (t = 0; t < NUM_PIXELS + FLUSH_CYCLES; t = t + 1) begin
            @(posedge clk);
            if (t < NUM_PIXELS) begin
                i_valid <= 1'b1;
                i_pixel  <= pix[t];
            end else begin
                i_valid <= 1'b0;
            end
            #1;

            // pixel currently at the window's center, given the module's
            // fixed (IMG_WIDTH + 3)-cycle latency to p11.
            idx = t - IMG_WIDTH - 3;
            check_window(idx);
        end

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** %0d TEST(S) FAILED ***\n", errors);

        $stop;
    end

endmodule