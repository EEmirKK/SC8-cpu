module baud_gen_tb;

    reg clk;
    reg reset;
    wire baud_tick;

    baud_gen uut (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer tick_count;
    integer i;

    initial begin
        reset = 1;
        tick_count = 0;
        @(posedge clk);
        reset = 0;

        // Count how many clock cycles pass before the first tick
        i = 0;
        while (baud_tick !== 1'b1) begin
            @(posedge clk);
            i = i + 1;
        end

        if (i == 5207)
            $display("PASS: Test 1 - first baud_tick occurred after %0d cycles (expected 5207)", i);
        else
            $display("FAIL: Test 1 - first baud_tick occurred after %0d cycles, expected 5207", i);

        // Confirm the counter actually resets and produces a second tick
        // at the correct interval, not just once
        @(posedge clk);   // move past the tick cycle itself
        i = 0;
        while (baud_tick !== 1'b1) begin
            @(posedge clk);
            i = i + 1;
        end

        if (i == 5207)
            $display("PASS: Test 2 - second baud_tick occurred %0d cycles later (expected 5207)", i);
        else
            $display("FAIL: Test 2 - second baud_tick occurred %0d cycles later, expected 5207", i);

        $stop;
    end

endmodule