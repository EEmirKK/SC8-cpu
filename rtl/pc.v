module pc (
    input clk,
    input reset,
    input branch_taken,  // 1 if this cycle's branch condition was true
    input signed [6:0]  branch_offset,  // signed offset from the current instruction
    output reg [4:0]  pc_out  // current PC value, fed to instruction memory
);

    always @(posedge clk) begin
        if (reset) begin
            pc_out <= 5'd0;
        end
        else if (branch_taken) begin
            // Branch target computed from the CURRENT pc_out (not PC+1),
            // so offsets are: target_address - current_instruction_address.
            pc_out <= pc_out + $signed(branch_offset);
        end
        else begin
            pc_out <= pc_out + 5'd1;   // default: move to the next instruction
        end
    end

endmodule