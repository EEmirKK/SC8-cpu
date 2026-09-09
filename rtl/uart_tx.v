module uart_tx (
    input clk,
    input reset,
    input baud_tick,  // one pulse per bit-time, from baud_gen
    input tx_start,  // pulse: begin sending tx_data
    input [7:0] tx_data,  // the byte to send
    output reg tx,  // the actual serial output line
    output reg tx_busy  // 1 while a byte is currently being sent
);

// IDLE → START → DATA (loops 8 times) → STOP → back to IDLE

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // State register (sequential)
    reg [1:0] state, next_state;
    reg [2:0] bit_index, next_bit_index;
    reg [7:0] shift_reg, next_shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
        end
        else begin
            state     <= next_state;
            bit_index <= next_bit_index;
            shift_reg <= next_shift_reg;
        end
    end

    // Next state logic (combinational)
    always @(*) begin
        next_state     = state;       // default: stay put
        next_bit_index = bit_index;
        next_shift_reg = shift_reg;

        case (state)
            IDLE: begin
                if (tx_start) begin
                    next_shift_reg = tx_data;
                    next_state     = START;
                end
            end

            START: begin
                if (baud_tick) begin
                    next_state     = DATA;
                    next_bit_index = 3'd0;
                end
            end

            DATA: begin
                if (baud_tick) begin
                    next_shift_reg = shift_reg >> 1;
                    if (bit_index == 3'd7)
                        next_state = STOP;
                    else
                        next_bit_index = bit_index + 3'd1;
                end
            end

            STOP: begin
                if (baud_tick)
                    next_state = IDLE;
            end
        endcase
    end

    // Output logic (combinational, Moore: depends only on current state)
    always @(*) begin
        case (state)
            IDLE:  tx = 1'b1;
            START: tx = 1'b0;
            DATA:  tx = shift_reg[0];
            STOP:  tx = 1'b1;
            default: tx = 1'b1;
        endcase
        tx_busy = (state != IDLE);
    end

endmodule