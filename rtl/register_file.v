module register_file (
    input  wire        clk,
    input  wire        reset,       // clears all registers to 0 at startup
    input  wire        we,          // write enable: 1 = perform write this cycle
    input  wire [2:0]  rd_addr,     // destination register (write)
    input  wire [2:0]  rs_addr,     // source register 1 (read)
    input  wire [2:0]  rt_addr,     // source register 2 (read)
    input  wire [15:0] wr_data,     // value to write into rd_addr
    output wire [15:0] rs_data,     // value read from rs_addr
    output wire [15:0] rt_data      // value read from rt_addr
);
 
    reg [15:0] registers [0:7];  // 8 registers, 16 bits each; registers[0] hardwired to always behave as 0
 
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            // Clear all registers to a known value (0) at startup, so no
            // register is ever read while still in Verilog's unknown ('x')
            // state. Without this, tricks like "SUB R2,R2,R2" to zero a
            // register are unsafe: x - x evaluates to x, not 0.
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'd0;
        end
        else if (we && rd_addr != 3'b000) begin
            // Writes to R0 are silently ignored. Hardware-enforced zero register,
            // mirrors RISC-V's x0 / ELEC0004's convention (see DESIGN.md).
            registers[rd_addr] <= wr_data;
        end
    end
 
    // Reads are combinational (no clock needed) - required so the ALU can use
    // the value in the same cycle it's read, per the single-cycle design.
    // R0 always reads as 0 regardless of what's stored there, since writes
    // to it are blocked above anyway - this just makes that guarantee explicit
    // on the read side too.
    assign rs_data = (rs_addr == 3'b000) ? 16'd0 : registers[rs_addr];
    assign rt_data = (rt_addr == 3'b000) ? 16'd0 : registers[rt_addr];
 
endmodule
