module uart_tx_tb;

    reg        clk;
    reg        reset;
    reg        baud_tick;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       tx_busy;

    uart_tx uut (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Task: pulse baud_tick for exactly one clock cycle, then check tx
    reg [7:0] expected;
    integer   i;
    integer   errors;

    task pulse_and_check(input [7:0] exp_value, input integer bit_num);
        begin
            baud_tick = 1;
            @(posedge clk);
            baud_tick = 0;
            #1;
            if (tx !== exp_value[0])
                begin
                    $display("FAIL: bit %0d - expected tx=%b, got tx=%b", bit_num, exp_value[0], tx);
                    errors = errors + 1;
                end
            else
                $display("PASS: bit %0d - tx=%b as expected", bit_num, tx);
        end
    endtask

    initial begin
        errors    = 0;
        reset     = 1;
        baud_tick = 0;
        tx_start  = 0;
        tx_data   = 8'h00;
        @(posedge clk);
        reset = 0;

        // Confirm idle line state before anything happens
        #1;
        if (tx !== 1'b1)
            $display("FAIL: idle - expected tx=1, got tx=%b", tx);
        else
            $display("PASS: idle - tx=1 as expected");

        // Start sending 0xA5
        tx_data  = 8'hA5;
        tx_start = 1;
        @(posedge clk);   // IDLE -> START
        tx_start = 0;

        // Start bit is visible immediately, no baud_tick needed yet
        #1;
        if (tx !== 1'b0)
            $display("FAIL: start bit - expected tx=0, got tx=%b", tx);
        else
            $display("PASS: start bit - tx=0 as expected");

        // 8 data bits, LSB first: 1,0,1,0,0,1,0,1
        pulse_and_check(8'b1, 0);
        pulse_and_check(8'b0, 1);
        pulse_and_check(8'b1, 2);
        pulse_and_check(8'b0, 3);
        pulse_and_check(8'b0, 4);
        pulse_and_check(8'b1, 5);
        pulse_and_check(8'b0, 6);
        pulse_and_check(8'b1, 7);

        // Stop bit
        pulse_and_check(8'b1, 8);

        // Stop bit is now being sent (state = STOP). One more baud_tick
        // completes the stop bit's full duration and returns to IDLE.
        pulse_and_check(8'b1, 9);

        // tx_busy should now be back to 0
        #1;
        if (tx_busy !== 1'b0)
            $display("FAIL: tx_busy should be 0 after frame complete, got %b", tx_busy);
        else
            $display("PASS: tx_busy correctly returned to 0");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $stop;
    end

endmodule