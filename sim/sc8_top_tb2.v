module sc8_top_tb2;

    reg  clk;
    reg  reset;
    wire uart_tx_out;

    sc8_top #(
        .INSTR_FILE("program2.hex"),
        .DATA_FILE("data2.hex")
    ) uut (
        .clk(clk),
        .reset(reset),
        .uart_tx_out(uart_tx_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        @(posedge clk);
        reset = 0;

        repeat (40) @(posedge clk);

        // Print everything - visually check against the hand-calculated
        // expected values: R3=22, R4=14, R5=22, R6=3, R7=14
        $display("R1=%d R2=%d R3=%d R4=%d R5=%d R6=%d R7=%d",
            uut.rf_inst.registers[1], uut.rf_inst.registers[2],
            uut.rf_inst.registers[3], uut.rf_inst.registers[4],
            uut.rf_inst.registers[5], uut.rf_inst.registers[6],
            uut.rf_inst.registers[7]);

        // Automated check: proves BEQ did NOT branch when R1 != R2.
        // If BEQ were broken (always branching), R3 would still be 8,
        // not 22, since address 5 (ADD R3,R3,R4) would have been skipped.
        if (uut.rf_inst.registers[3] == 16'd22)
            $display("PASS: BEQ-not-taken path executed correctly (R3=22)");
        else
            $display("FAIL: BEQ-not-taken - expected R3=22, got %d", uut.rf_inst.registers[3]);

        // Automated check: proves LOAD/STORE with a non-zero base register
        // works, not just the R0-base case every other test has used.
        if (uut.rf_inst.registers[7] == 16'd14)
            $display("PASS: non-zero-base LOAD/STORE round trip correct (R7=14)");
        else
            $display("FAIL: non-zero-base round trip - expected R7=14, got %d", uut.rf_inst.registers[7]);

        $stop;
    end

endmodule