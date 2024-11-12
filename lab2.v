// Variant 1 : y = a ^ 2 + b ^ (1/3)
// Restrictions: 1 summation, 2 multiplications

module summ (
    input clk,
    input rst,
    input start,
    input [15:0] a,
    input [15:0] b,
    output reg ready,
    output reg [15:0] y
);
    always @(posedge clk) begin
        if (rst) begin
            y <= 16'd0;
            ready <= 1'b0;
        end else if (start) begin
            y <= a + b;
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end
endmodule

module mult(
    input clk,
    input rst,
    input start,
    input [15:0] a_in,
    input [15:0] b_in,
    output reg [15:0] f_out,
    output reg ready
);
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;
    
    reg state;
    reg [15:0] sum;
    reg [15:0] counter;
    
    reg summ_start;
    wire summ_ready;
    wire [15:0] summ_y;
    reg [15:0] summ_a, summ_b;
    
    summ summ_inst (
        .clk(clk),
        .rst(rst),
        .start(summ_start),
        .a(summ_a),
        .b(summ_b),
        .ready(summ_ready),
        .y(summ_y)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sum <= 16'd0;
            counter <= 16'd0;
            f_out <= 16'd0;
            ready <= 1'b0;
            summ_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        sum <= 16'd0;
                        counter <= 16'd0;
                        summ_a <= 16'd0;
                        summ_b <= a_in;
                        summ_start <= 1'b1;
                        state <= WORK;
                        ready <= 1'b0;
                    end
                end
                WORK: begin
                    summ_start <= 1'b0; // Deassert start after one cycle
                    if (summ_ready) begin
                        sum <= summ_y;
                        counter <= counter + 1;
                        if (counter + 1 < b_in) begin
                            summ_a <= summ_y;
                            summ_b <= a_in;
                            summ_start <= 1'b1;
                        end else begin
                            f_out <= summ_y;
                            ready <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule

module clock_gen(
    output reg clk
);
    assign clk = 1'b0;
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

