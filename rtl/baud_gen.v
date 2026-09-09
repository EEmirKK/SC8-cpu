module baud_gen (
    input clk,
    input reset,
    output reg baud_tick
);

    localparam COUNT_MAX = 5208;   // 50,000,000 / 9600, rounded

    reg [12:0] counter;   // needs to count to 5208, 13 bits (max 8191) is enough

    always @(posedge clk) begin
        if (reset) begin
            counter   <= 13'd0;
            baud_tick <= 1'b0;
        end
        else if (counter == COUNT_MAX - 1) begin
            counter   <= 13'd0;
            baud_tick <= 1'b1;   // one-cycle pulse
        end
        else begin
            counter   <= counter + 13'd1;
            baud_tick <= 1'b0;
        end
    end

endmodule