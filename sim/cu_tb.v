module cu_tb;

    reg  [2:0] opcode;
    wire       reg_we;
    wire       mem_we;
    wire [1:0] alu_op;
    wire       alu_src;

    cu uut (
        .opcode(opcode),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .alu_op(alu_op),
        .alu_src(alu_src)
    );

    initial begin
        // --- LOAD ---
        opcode = 3'b000;
        #1;
        if (reg_we == 1 && mem_we == 0 && alu_op == 2'b00 && alu_src == 1)
            $display("PASS: LOAD - correct control signals");
        else
            $display("FAIL: LOAD - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- STORE ---
        opcode = 3'b001;
        #1;
        if (reg_we == 0 && mem_we == 1 && alu_op == 2'b00 && alu_src == 1)
            $display("PASS: STORE - correct control signals");
        else
            $display("FAIL: STORE - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- ADD ---
        opcode = 3'b010;
        #1;
        if (reg_we == 1 && mem_we == 0 && alu_op == 2'b00 && alu_src == 0)
            $display("PASS: ADD - correct control signals");
        else
            $display("FAIL: ADD - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- SUB ---
        opcode = 3'b011;
        #1;
        if (reg_we == 1 && mem_we == 0 && alu_op == 2'b01 && alu_src == 0)
            $display("PASS: SUB - correct control signals");
        else
            $display("FAIL: SUB - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- AND ---
        opcode = 3'b100;
        #1;
        if (reg_we == 1 && mem_we == 0 && alu_op == 2'b10 && alu_src == 0)
            $display("PASS: AND - correct control signals");
        else
            $display("FAIL: AND - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- OR ---
        opcode = 3'b101;
        #1;
        if (reg_we == 1 && mem_we == 0 && alu_op == 2'b11 && alu_src == 0)
            $display("PASS: OR - correct control signals");
        else
            $display("FAIL: OR - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- BEQ ---
        opcode = 3'b110;
        #1;
        if (reg_we == 0 && mem_we == 0 && alu_op == 2'b01 && alu_src == 0)
            $display("PASS: BEQ - correct control signals");
        else
            $display("FAIL: BEQ - got reg_we=%b mem_we=%b alu_op=%b alu_src=%b",
                      reg_we, mem_we, alu_op, alu_src);

        // --- HALT ---
        opcode = 3'b111;
        #1;
        if (reg_we == 0 && mem_we == 0)
            $display("PASS: HALT - correct control signals (alu_op/alu_src don't-care)");
        else
            $display("FAIL: HALT - got reg_we=%b mem_we=%b", reg_we, mem_we);

        $stop;
    end

endmodule