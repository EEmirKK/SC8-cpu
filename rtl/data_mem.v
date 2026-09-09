module data_mem #(
    parameter INIT_FILE = "data.hex"
) (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  addr,
    input  wire [15:0] wr_data,
    output wire [15:0] rd_data
);

    reg [15:0] mem [0:31];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wr_data;
        end
    end

    assign rd_data = mem[addr];

endmodule