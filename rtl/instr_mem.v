module instr_mem (
    input [4:0]  pc,      // address to fetch (PC value)
    output [15:0] instr      // instruction word at that address
);

    reg [15:0] mem [0:31];  // 32 instruction slots, 16 bits each

    initial begin
        $readmemh("program.hex", mem);
    end

    assign instr = mem[pc];

endmodule