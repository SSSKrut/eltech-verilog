module lfsr_8bit (
  input clk,
  input rst,
  input load1,
  input [7:0] seed1,
  input load2,
  input [7:0] seed2,
  output reg [7:0] lfsr1_out,
  output reg [7:0] lfsr2_out
);

  reg [7:0] lfsr1;
  reg [7:0] lfsr2;

  // LFSR1: y = 1 + x + x^2 + x^4 + x^8
  always @(posedge clk) begin
    if (rst) begin
      lfsr1 <= 8'b00000001; // Initial value (can be changed)
      lfsr1_out <= 8'b00000001;
    end else if (load1) begin
      lfsr1 <= seed1;
      lfsr1_out <= seed1;
    end else begin
      lfsr1 <= {lfsr1[6:0], lfsr1[7] ^ lfsr1[6] ^ lfsr1[5] ^ lfsr1[3]};
      lfsr1_out <= lfsr1;
    end
  end

  // LFSR2: y = 1 + x^2 + x^3 + x^5 + x^8
  always @(posedge clk) begin
    if (rst) begin
      lfsr2 <= 8'b00000001; // Initial value (can be changed)
      lfsr2_out <= 8'b00000001;
    end else if (load2) begin
      lfsr2 <= seed2;
      lfsr2_out <= seed2;
    end else begin
      lfsr2 <= {lfsr2[6:0], lfsr2[7] ^ lfsr2[5] ^ lfsr2[4] ^ lfsr2[2]};
      lfsr2_out <= lfsr2;
    end
  end

endmodule