module sc8_top_tb;

    reg clk;
    reg reset;

    sc8_top uut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        @(posedge clk);
        reset = 0;

        repeat (30) @(posedge clk);

        if (uut.data_mem_inst.mem[2] == 16'd6)
            $display("PASS: final sum in data memory address 2 = %d", uut.data_mem_inst.mem[2]);
        else
            $display("FAIL: expected 6, got %d", uut.data_mem_inst.mem[2]);

        $stop;
    end

endmodule