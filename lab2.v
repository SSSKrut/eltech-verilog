// Variant 1 : y = a ^ 2 + b ^ (1/3)
// Restrictions: 1 summation, 2 multiplications

module summ (
    input clk,
    input rst,

    input [15:0] a,
    input [15:0] b,

    output reg ready,
    output reg [15:0] y
);

    always @(posedge clk) begin
        if (rst) begin
            y <= 0;
            ready <= 1'b0;
        end else if (start) begin
            y <= a + b;
            ready <= 1'b1;
        end
    end
endmodule

module mult(
    input clk,
    input rst,
    
    input [15:0] a_in,
    input [15:0] b_in,
    
    output reg [15:0] f_out,
    output state
);
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;
    
    reg [15:0] a;
    reg [15:0] b;
    reg [15:0] f;
    reg state;

    always @(posedge clk) begin
        if (rst) begin
            y <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    y <= 0;
                    state <= WORK;
                    x <= x_in;
                end
                WORK: begin
                    y <= x;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

module clock_gen(
    output reg clk
);
    reg clk = 1'b0;
    always begin
        #1 clk = ~clk;
    end
endmodule

module finalblock(
    input wire clk,
    input wire rst,

    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] y
);

    wire [7:0] x2;
    wire [7:0] b13;
    wire [7:0] y1;
    wire [7:0] y2;

    assign x2 = x * x;
    assign b13 = b * b * b;
    assign y1 = x2 + b13;
    assign y2 = y1 + 1;

    assign y = y2;

endmodule

