module crc8 (
    input reg[7:0] y_in,
    input wire start,
    input wire rst,
    input wire clk,
    output reg ready,
    output reg busy,
    output reg[7:0] crc_result
);
    reg [7:0] crc_reg;
    reg [7:0] data_buf;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            crc_reg <= 8'h00;
            busy <= 1'b0;
            ready <= 1'b1;
        end else if (data_valid) begin
            busy <= 1'b1;
            data_buf = y_in;
            crc_reg = crc_reg ^ data_buf; // Шаг 3: сложение по модулю 2
            for (i = 0; i < 8; i = i + 1) begin // Шаги 4-9: обработка каждого бита
                if (crc_reg[7]) begin
                    crc_reg = (crc_reg << 1) ^ 8'h31; // Порождающий полином 0x31
                end else begin
                    crc_reg = crc_reg << 1;
                end
            end
            busy <= 1'b0;
            ready <= 1'b1;
        end
    end

    assign crc_result = crc_reg;
endmodule