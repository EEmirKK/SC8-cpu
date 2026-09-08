module cu (
    input [2:0] opcode,       // top 3 bits of the fetched instruction
    output reg  reg_we,      // register file write enable
    output reg  mem_we,      // data memory write enable
    output reg [1:0] alu_op,  // ALU operation select
    output reg alu_src      // 0 = ALU's 2nd input from register, 1 = from offset
);

    always @(*) begin
        case (opcode)
            3'b000: begin // LOAD
                reg_we  = 1;
                mem_we  = 0;
                alu_op  = 2'b00;  // ADD (address = Rs + offset)
                alu_src = 1;      // use offset, not Rt
            end
            3'b001: begin // STORE
                reg_we  = 0;
                mem_we  = 1;
                alu_op  = 2'b00;  // ADD (address = Rs + offset)
                alu_src = 1;      // use offset, not Rt
            end
            3'b010: begin // ADD
                reg_we  = 1;
                mem_we  = 0;
                alu_op  = 2'b00;
                alu_src = 0;      // use Rt
            end
            3'b011: begin // SUB
                reg_we  = 1;
                mem_we  = 0;
                alu_op  = 2'b01;
                alu_src = 0;
            end
            3'b100: begin // AND
                reg_we  = 1;
                mem_we  = 0;
                alu_op  = 2'b10;
                alu_src = 0;
            end
            3'b101: begin // OR
                reg_we  = 1;
                mem_we  = 0;
                alu_op  = 2'b11;
                alu_src = 0;
            end
            3'b110: begin // BEQ
                reg_we  = 0;
                mem_we  = 0;
                alu_op  = 2'b01;  // SUB, to compute Rs - Rt for the zero check
                alu_src = 0;      // use Rt (comparing two registers)
            end
            3'b111: begin // HALT
                reg_we  = 0;
                mem_we  = 0;
                alu_op  = 2'b00;  // don't care, ALU output unused
                alu_src = 0;      // don't care
            end
        endcase
    end

endmodule