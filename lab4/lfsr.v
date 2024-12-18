module lfsr (
    input clk,
    input rst,
    input start,
    output reg ready,
    output reg [7:0] lfsr1_out,
    output reg [7:0] lfsr2_out
);
    reg [7:0] lfsr1;
    reg [7:0] lfsr2;
    reg init;

    parameter INIT_LFSR1 = 50; // Начальное значение для LFSR1
    parameter INIT_LFSR2 = 100; // Начальное значение для LFSR2

    parameter POLY_LFSR1 = 8'b10111000; // Пример полинома для LFSR1 (x^8 + x^6 + x^5 + x^3 + 1)
    parameter POLY_LFSR2 = 8'b10011000; // Пример полинома для LFSR2 (x^8 + x^5 + x^4 + x^2 + 1)

    always @(posedge clk) begin
      if (init) begin
          if (rst) begin
              lfsr1 <= INIT_LFSR1; 
              lfsr2 <= INIT_LFSR2; 
              lfsr1_out <= lfsr1;
              lfsr2_out <= lfsr2;
              init <= 1;
              ready <= 1;
          end else if (start) begin
              ready <= 0;
              lfsr1 <= {lfsr1[6:0], ^(lfsr1 & POLY_LFSR1)};
              lfsr2 <= {lfsr2[6:0], ^(lfsr2 & POLY_LFSR2)};
              lfsr1_out <= lfsr1;
              lfsr2_out <= lfsr2;
              ready <= 1;
          end
      end else begin
        lfsr1 <= INIT_LFSR1; 
        lfsr2 <= INIT_LFSR2; 
        lfsr1_out <= lfsr1;
        lfsr2_out <= lfsr2;
        init <= 1;
        ready <= 1;
      end
    end

endmodule
