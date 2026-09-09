module sc8_top_tb;

    reg  clk;
    reg  reset;
    wire uart_tx_out;

    sc8_top uut (
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

        repeat (35) @(posedge clk);

        // Existing check: final sum correctly stored in data memory
        if (uut.data_mem_inst.mem[2] == 16'd6)
            $display("PASS: final sum in data memory address 2 = %d", uut.data_mem_inst.mem[2]);
        else
            $display("FAIL: expected 6, got %d", uut.data_mem_inst.mem[2]);

        // New check: address 31 also received the value (STORE wrote it,
        // same as any normal RAM address, independent of UART triggering)
        if (uut.data_mem_inst.mem[31] == 16'd6)
            $display("PASS: value also written to data memory address 31 = %d", uut.data_mem_inst.mem[31]);
        else
            $display("FAIL: expected 6 at address 31, got %d", uut.data_mem_inst.mem[31]);

        $stop;
    end

endmodule