module sc8_top #(
    parameter INSTR_FILE = "program.hex",
    parameter DATA_FILE  = "data.hex"
) (
    input  wire clk,
    input  wire reset,
    output wire uart_tx_out
);

    // Fetched instruction from instruction memory
    wire [15:0] instr;

    // Decoded fields
    wire [2:0] opcode   = instr[15:13];
    wire [2:0] rd_field = instr[12:10];
    wire [2:0] rs_field = instr[9:7];
    wire [2:0] rt_field = instr[6:4];
    wire signed [6:0] offset_field = instr[6:0];
    
    wire is_itype = (opcode == 3'b000) || (opcode == 3'b001) || (opcode == 3'b110); // LOAD, STORE, BEQ
    wire [2:0] rt_addr_actual = is_itype ? rd_field : rt_field;
    // Fetch stage: PC + instruction memory
    wire [4:0] pc_val;
    wire branch_taken;
    wire is_halt = (opcode == 3'b111);

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .branch_offset(offset_field),
        .pc_out(pc_val),
        .halt(is_halt)
    );

    instr_mem #(.INIT_FILE(INSTR_FILE)) instr_mem_inst (
        .pc(pc_val),
        .instr(instr)
    );

    // Decode stage: control unit
    wire reg_we;
    wire mem_we;
    wire [1:0] alu_op;
    wire alu_src;

    cu cu_inst (
        .opcode(opcode),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .alu_op(alu_op),
        .alu_src(alu_src)
    );

    // wb_data declared here, used by rf_inst below, driven later by the writeback mux
    wire [15:0] wb_data;

    // Register file
    wire [15:0] rs_data;
    wire [15:0] rt_data;

    register_file rf_inst (
        .clk(clk),
        .reset(reset),
        .we(reg_we),
        .rd_addr(rd_field),
        .rs_addr(rs_field),
        .rt_addr(rt_addr_actual),
        .wr_data(wb_data),
        .rs_data(rs_data),
        .rt_data(rt_data)
    );

    // ALU, with alu_src mux selecting its second input
    wire [15:0] alu_b;
    wire [15:0] alu_result;

    assign alu_b = alu_src ? {{9{offset_field[6]}}, offset_field} : rt_data;

    alu alu_inst (
        .a(rs_data),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

    // Data memory
    wire [15:0] mem_rd_data;

    data_mem #(.INIT_FILE(DATA_FILE)) data_mem_inst (
        .clk(clk),
        .we(mem_we),
        .addr(alu_result[4:0]),
        .wr_data(rt_data),
        .rd_data(mem_rd_data)
    );

    // Writeback mux
    wire we_from_mem = (opcode == 3'b000);
    assign wb_data = we_from_mem ? mem_rd_data : alu_result;

    // Branch: BEQ + ALU zero flag, feeds back to PC
    wire is_beq = (opcode == 3'b110);
    wire alu_zero = (alu_result == 16'd0);
    assign branch_taken = is_beq && alu_zero;

    // --- UART output ---
    wire baud_tick;
    wire uart_busy;

    baud_gen baud_gen_inst (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick)
    );

    // Trigger: STORE to data memory address 31 sends the low byte over UART
    wire uart_store = mem_we && (alu_result[4:0] == 5'd31);

    uart_tx uart_tx_inst (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(uart_store),
        .tx_data(rt_data[7:0]),
        .tx(uart_tx_out),
        .tx_busy(uart_busy)
    );

endmodule
