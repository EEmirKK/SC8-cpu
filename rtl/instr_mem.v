module instr_mem #(
    parameter INIT_FILE = "program.hex"
) (
    input  wire [4:0]  pc,
    output wire [15:0] instr
);

    reg [15:0] mem [0:31];

    initial begin
        $readmemh(INIT_FILE, mem);
    end
    
    assign instr = mem[pc];

endmodule