module crc8 (
    input [7:0] y_in,
    input wire start,
    input wire rst,
    input wire clk,
    output reg ready,
    output reg[7:0] crc_result
);

    reg [7:0] crc; 
    reg [3:0] bit_count; 
    reg busy; 

    // Полином CRC8: x^8 + x^4 + x^3 + x^2 + 1
    localparam POLY = 8'b10011011;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00; 
            bit_count <= 4'd0; 
            ready <= 1'b0; 
            busy <= 1'b0; 
        end else if (start && !busy) begin
            crc <= 8'h00; 
            bit_count <= 4'd0;
            busy <= 1'b1; 
            ready <= 1'b0;
        end else if (busy) begin
            if (bit_count < 8) begin
                // Обработка каждого бита входного значения
                crc <= {crc[6:0], 1'b0} ^ (y_in[7 - bit_count] ? POLY : 8'h00);
                bit_count <= bit_count + 1;
            end else begin
                crc_result <= crc; 
                ready <= 1'b1; 
                busy <= 1'b0; 
            end
        end
    end
    
endmodule