// Variant 1 : y = a ^ 2 + b ^ (1/3)
// Restrictions: 1 summation, 2 multiplications
`timescale 1ns/1ps
module mult(
    input clk,
    input rst,
    input start,
    input [7:0] a_in,
    input [7:0] b_in,
    output reg [15:0] f_out,
    output reg busy_o
);
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;
    
    reg state;
    reg [7:0] sum;
    reg [7:0] counter;
    
    reg [7:0] mult1_a_in, mult1_b_in;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sum <= 8'd0;
            counter <= 8'd0;
            f_out <= 8'd0;
            busy_o <= 1'b0;
            mult1_a_in <= 0;
            mult1_b_in <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        busy_o <= 1'b1;
                        sum <= 8'd0;
                        f_out <= 8'd0;
                        counter <= 8'd0;
                        mult1_a_in <= a_in;
                        mult1_b_in <= b_in;
                        state <= WORK;
                    end
                end
                WORK: begin
                    counter <= counter + 1;
                    if (counter < b_in) begin
                        sum <= sum + a_in;
                    end else begin
                        f_out <= sum;
                        busy_o <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

module cubicroot(
    input clk,
    input rst,
    input start,
    input [7:0] x_in,
    output reg [7:0] y_out,
    output reg busy_o
);
    // State encoding
    localparam IDLE          = 4'd0;
    localparam SHIFT_Y       = 4'd1;
    localparam COMPUTE_B1_MULT_OFF = 4'd2;
    localparam COMPUTE_B2    = 4'd3;
    localparam COMPUTE_B2_MULT_OFF    = 4'd4;
    localparam COMPUTE_B3    = 4'd5;
    localparam COMPARE      = 4'd6;
    localparam DECREMENT_S        = 4'd7;
    localparam COMPUTE_B1_MULT_OFF_WAIT = 4'd8;
    localparam COMPUTE_B2_MULT_OFF_WAIT = 4'd9;
    localparam SHIFT_Y_END = 4'd10;

    reg [7:0] x;
    reg [7:0] y;
    reg [8:0] b;
    reg [4:0] s;
    reg [3:0] state;
    reg [15:0] mult_reg;

    reg mult1_start;
    wire mult1_busy;
    wire [15:0] mult1_f_out;
    reg [7:0] mult1_a_in, mult1_b_in;
    

    mult mult1_inst (
        .clk(clk),
        .rst(rst),
        .start(mult1_start),
        .a_in(mult1_a_in),
        .b_in(mult1_b_in),
        .f_out(mult1_f_out),
        .busy_o(mult1_busy)
    );


    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            x <= 0;
            y <= 0;
            s <= 0;
            b <= 0;
            busy_o <= 0;
            y_out <= 0;
            mult1_start <= 0;
            mult_reg <= 0;
            
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        x <= x_in;
                        y <= 0;
                        s <= 5'd6;
                        state <= SHIFT_Y;
                        mult_reg <= 0;
                        b <= 0;
                        mult1_a_in <= 0;
                        mult1_b_in <= 0;
                        mult1_start <= 0;
                        busy_o <= 1'b1;
                    end
                end
                SHIFT_Y: begin
                    $display();
                    $display("-=-=-=-=-=-=-=-=-");
                    $write(" s:", s);
                    $write(" y:%d", y);
                    y <= y << 1;
                    state <= SHIFT_Y_END;
                end
                SHIFT_Y_END: begin
                    
                    mult1_a_in <= y + 1;
                    mult1_b_in <= y;
                    mult1_start <= 1;
                    state <= COMPUTE_B1_MULT_OFF;
                end
                COMPUTE_B1_MULT_OFF: begin
                    mult1_start <= 0;
                    mult_reg <= 0;
                    state <= COMPUTE_B1_MULT_OFF_WAIT;
                end
                COMPUTE_B1_MULT_OFF_WAIT: begin
                    if (!mult1_busy) begin
                        mult_reg <= mult1_f_out;
                        state <= COMPUTE_B2;
                    end
                end
                COMPUTE_B2: begin
                    $write(" mult_reg:", mult_reg);
                    mult1_a_in <= 0;
                        mult1_b_in <= 0;
                        mult1_start <= 0;
                    mult1_a_in <= 3;
                    mult1_b_in <= mult_reg;
                    mult1_start <= 1;
                    state <= COMPUTE_B2_MULT_OFF;
                end
                COMPUTE_B2_MULT_OFF: begin
                    mult1_start <= 0;
                    mult_reg <= 0;
                    state <= COMPUTE_B2_MULT_OFF_WAIT;
                end
                COMPUTE_B2_MULT_OFF_WAIT: begin
                    if (!mult1_busy) begin
                        mult_reg <= mult1_f_out;
                        state <= COMPUTE_B3;
                    end
                end
                COMPUTE_B3: begin
                    b <= (mult_reg + 1) << s;
                    mult_reg <= 0;
                    state <= COMPARE;
                end
                COMPARE: begin
                    $write(" b<<%b:", b);
                    if (x >= b) begin
                        $write(" x>=b");
                        x <= x - b;
                        y <= y + 1;
                        state <= DECREMENT_S;
                    end else begin
                        state <= DECREMENT_S;
                    end
                end 
                DECREMENT_S: begin
                    if (s >= 3) begin
                        s <= s - 3;
                        state <= SHIFT_Y;
                    end else begin
                        y_out <= y;
                        state <= IDLE;
                        busy_o <= 0;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

module clock_gen(
    output reg clk
);
    initial begin
        clk <= 1'b1;
        forever #1 clk <= ~clk;
    end
endmodule

module cubicroot_test;
    wire clk;
    reg rst;
    reg start;
    reg [7:0] x_in;
    wire [7:0] y_out;
    wire busy;

    assign ready = ~busy;

    cubicroot cubicroot_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x_in(x_in),
        .y_out(y_out),
        .busy_o(busy)
    );

    clock_gen cg_inst (
        .clk(clk)
    );

    integer i;
    reg [7:0] cube;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, cubicroot_test);
        rst <= 1;
        start <= 0;
        x_in <= 8'd0;

        #40 rst <= 0;
        $display("Cubic root test:");
        
        for (i = 0; i <= 10; i = i + 1) begin
            cube = i * i * i;
            // #10;
            
            x_in <= cube;
            start <= 1;
            #2; start <= 0;

            wait (ready);
            $display("cubicroot(%b) = %d (expected %d)", cube, y_out, i);
            #100;
        end
        for (i = 0; i <= 6; i = i + 1) begin
            cube = i * i * i;
            // #10;
            
            x_in <= cube;
            start <= 1;
            #2; start <= 0;

            wait (ready);
            $display("cubicroot(%b) = %d (expected %d)", cube, y_out, i);
            #100;
        end
        $finish;
    end
endmodule

// module mult_test;
//     wire clk;
//     reg rst;
//     reg start;
//     reg [7:0] a_in;
//     reg [7:0] b_in;
//     wire [15:0] f_out;
//     wire busy_o;

//     mult mult_inst (
//         .clk(clk),
//         .rst(rst),
//         .start(start),
//         .a_in(a_in),
//         .b_in(b_in),
//         .f_out(f_out),
//         .busy_o(busy_o)
//     );

//     clock_gen cg_inst (
//         .clk(clk)
//     );

//     integer i, j;

//     initial begin
//         rst = 1;
//         start = 0;
//         a_in = 8'd0;
//         b_in = 8'd0;

//         #20 rst = 0;
//         $display("Multiplier test:");

//         for (i = 0; i <= 12; i = i + 1) begin
//             for (j = 0; j <= 12; j = j + 1) begin
//                 #10;
//                 a_in = i;
//                 b_in = j;
//                 start = 1;
//                 #2 start = 0;

//                 wait (!busy_o);
//                 $display("%d * %d = %d", i, j, f_out);
//             end
//         end

//         $display("-=-=-=-=-=-=-=-=-=");
//         $finish;
//     end
// endmodule