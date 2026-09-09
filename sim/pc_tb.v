module pc_tb;

    reg               clk;
    reg               reset;
    reg               branch_taken;
    reg signed [6:0]  branch_offset;
    reg               halt;
    wire [4:0]        pc_out;

    pc uut (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .branch_offset(branch_offset),
        .halt(halt),
        .pc_out(pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // --- Test 1: reset forces PC to 0 ---
        reset = 1;
        branch_taken = 0;
        branch_offset = 7'd0;
        halt = 0;
        @(posedge clk);
        #1;
        if (pc_out == 5'd0)
            $display("PASS: Test 1 - reset forces PC to 0");
        else
            $display("FAIL: Test 1 - expected 0, got %d", pc_out);

        // --- Test 2a: default increment ---
        reset = 0;
        @(posedge clk);   // PC: 0 -> 1
        #1;
        if (pc_out == 5'd1)
            $display("PASS: Test 2a - PC incremented to 1");
        else
            $display("FAIL: Test 2a - expected 1, got %d", pc_out);

        // --- Test 2b: default increment again ---
        @(posedge clk);   // PC: 1 -> 2
        #1;
        if (pc_out == 5'd2)
            $display("PASS: Test 2b - PC incremented to 2");
        else
            $display("FAIL: Test 2b - expected 2, got %d", pc_out);

        // --- Test 3: branch taken, forward jump (positive offset) ---
        // pc_out is currently 2. Jump forward to address 7: offset = 7 - 2 = +5
        branch_taken = 1;
        branch_offset = 7'd5;
        @(posedge clk);
        #1;
        if (pc_out == 5'd7)
            $display("PASS: Test 3 - forward branch: 2 + 5 = 7");
        else
            $display("FAIL: Test 3 - expected 7, got %d", pc_out);

        // --- Test 4: branch taken, backward jump (negative offset) ---
        // pc_out is currently 7. Jump back to address 2: offset = 2 - 7 = -5
        branch_taken = 1;
        branch_offset = -7'd5;   // -5, in 7-bit signed representation
        @(posedge clk);
        #1;
        if (pc_out == 5'd2)
            $display("PASS: Test 4 - backward branch: 7 + (-5) = 2");
        else
            $display("FAIL: Test 4 - expected 2, got %d", pc_out);

        // --- Test 5: halt freezes the PC, even with branch_taken still set ---
        branch_taken = 0;
        halt = 1;
        @(posedge clk);   // should NOT increment past 2
        @(posedge clk);   // should still hold at 2
        #1;
        if (pc_out == 5'd2)
            $display("PASS: Test 5 - halt correctly froze PC at 2");
        else
            $display("FAIL: Test 5 - expected 2 (frozen), got %d", pc_out);

        $stop;
    end

endmodule