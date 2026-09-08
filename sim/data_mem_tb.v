module data_mem_tb;

    reg         clk;
    reg         we;
    reg  [4:0]  addr;
    reg  [15:0] wr_data;
    wire [15:0] rd_data;

    data_mem uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // --- Test 1: preload check ---
        we = 0;
        addr = 5'd0;
        #1;
        if (rd_data == 16'd3)
            $display("PASS: Test 1 - address 0 preloaded with 3");
        else
            $display("FAIL: Test 1 - expected 3, got %d", rd_data);

        // --- Test 2: write then read back ---
        we = 1;
        addr = 5'd5;
        wr_data = 16'd77;
        @(posedge clk);

        we = 0;
        #1;
        if (rd_data == 16'd77)
            $display("PASS: Test 2 - address 5 correctly holds 77");
        else
            $display("FAIL: Test 2 - expected 77, got %d", rd_data);

        // --- Test 3: write blocked when we=0 ---
        we = 0;
        addr = 5'd5;
        wr_data = 16'd99;
        @(posedge clk);   // we=0, so this should NOT write

        addr = 5'd5;
        #1;
        if (rd_data == 16'd77)
            $display("PASS: Test 3 - write correctly blocked when we=0 (still 77)");
        else
            $display("FAIL: Test 3 - expected 77, got %d", rd_data);
        $stop;
    end

endmodule