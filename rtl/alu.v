module alu (
    input [15:0] a,        // first operand
    input [15:0] b,        // second operand
    input [1:0]  alu_op,   // selects which operation to perform
    output reg [15:0] result    // output of the operation
);

    always @(*) begin
        case (alu_op)
            2'b00: result = a + b;   // ADD
            2'b01: result = a - b;   // SUB
            2'b10: result = a & b;   // AND
            2'b11: result = a | b;   // OR
        endcase
    end

endmodule