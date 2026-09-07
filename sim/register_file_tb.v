module register_file_tb;

    reg         clk;
    reg         we;
    reg  [2:0]  rd_addr, rs_addr, rt_addr;
    reg  [15:0] wr_data;
    wire [15:0] rs_data, rt_data;

    register_file uut (
        .clk(clk),
        .we(we),
        .rd_addr(rd_addr),
        .rs_addr(rs_addr),
        .rt_addr(rt_addr),
        .wr_data(wr_data),
        .rs_data(rs_data),
        .rt_data(rt_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // --- Test 1: normal write, then read back ---
        we      = 1;
        rd_addr = 3'b011;   // R3
        wr_data = 16'd24;
        @(posedge clk);     // wait for the write to actually happen

        we      = 0;
        rs_addr = 3'b011;   // read back R3
        #1;                 // let the combinational read settle
        if (rs_data == 16'd24)
            $display("PASS: Test 1 - R3 correctly holds 24");
        else
            $display("FAIL: Test 1 - expected 24, got %d", rs_data);

        // --- Test 2: attempting to write to R0 is ignored ---
        we      = 1;
        rd_addr = 3'b000;   // try to write to R0
        wr_data = 16'd99;   // a value that should NEVER actually land in R0
        @(posedge clk);

        we      = 0;
        rs_addr = 3'b000;
        #1;
        if (rs_data == 16'd0)
            $display("PASS: Test 2 - write to R0 was correctly ignored");
        else
            $display("FAIL: Test 2 - R0 changed to %d, write should have been blocked", rs_data);

        $stop;
    end

endmodule