module data_mem (
    input clk,
    input we,
    input [4:0]  addr,
    input [15:0] wr_data,
    output [15:0] rd_data
);

    reg [15:0] mem [0:31];  // 32 data words, 16 bits each

    initial begin
        $readmemh("data.hex", mem);  // preloads constants needed by the test program
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wr_data;
        end
    end

    assign rd_data = mem[addr];

endmodule