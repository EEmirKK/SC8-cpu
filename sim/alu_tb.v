module alu_tb;

    reg  [15:0] a, b;
    reg  [1:0]  alu_op;
    wire [15:0] result;

    alu uut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    initial begin
        // --- Test 1: ADD ---
        a = 16'd5;
        b = 16'd3;
        alu_op = 2'b00;
        #1;  // let the combinational logic settle
        if (result == 16'd8)
            $display("PASS: Test 1 - ADD: 5 + 3 = %d", result);
        else
            $display("FAIL: Test 1 - ADD: expected 8, got %d", result);

        // --- Test 2: SUB ---
        a = 16'd5;
        b = 16'd3;
        alu_op = 2'b01;
        #1;
        if (result == 16'd2)
            $display("PASS: Test 2 - SUB: 5 - 3 = %d", result);
        else
            $display("FAIL: Test 2 - SUB: expected 2, got %d", result);

        // --- Test 3: AND ---
        a = 16'b1100;
        b = 16'b1010;
        alu_op = 2'b10;
        #1;
        if (result == 16'b1000)
            $display("PASS: Test 3 - AND: 1100 & 1010 = %b", result);
        else
            $display("FAIL: Test 3 - AND: expected 1000, got %b", result);

        // --- Test 4: OR ---
        a = 16'b1100;
        b = 16'b1010;
        alu_op = 2'b11;
        #1;
        if (result == 16'b1110)
            $display("PASS: Test 4 - OR: 1100 | 1010 = %b", result);
        else
            $display("FAIL: Test 4 - OR: expected 1110, got %b", result);

        $stop;
    end

endmodule