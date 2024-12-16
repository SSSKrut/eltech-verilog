// Variant 1 : y = a ^ 2 + b ^ (1/3)
// Restrictions: 1 summation, 2 multiplications
`timescale 1ns/1ps
module mult(
    input clk,
    input rst,
    input start,
    input [7:0] a_in,
    input [7:0] b_in,
    output reg [7:0] f_out,
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
    reg [7:0] mult_reg;

    reg mult1_start;
    wire mult1_busy;
    wire [7:0] mult1_f_out;
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
                    if (x >= b) begin
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

module compute_y (
    input clk,
    input rst,
    input start,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] y,
    output reg ready
);
    reg [7:0] a_squared;
    reg [7:0] b_cuberoot;
    reg [2:0] state;

    reg mult_start;
    wire mult_ready;
    wire [7:0] mult_result;

    reg cubicroot_start;
    wire cubicroot_ready;
    wire [7:0] cubicroot_result;

    mult mult_inst (
        .clk(clk),
        .rst(rst),
        .start(mult_start),
        .a_in(a),
        .b_in(a),
        .f_out(mult_result),
        .busy_o(mult_ready)
    );

    cubicroot cubicroot_inst (
        .clk(clk),
        .rst(rst),
        .start(cubicroot_start),
        .x_in(b),
        .y_out(cubicroot_result),
        .busy_o(cubicroot_ready)
    );


    // State machine states
    localparam IDLE          = 3'd0;
    localparam CALC_SQUARE   = 3'd1;
    localparam CALC_CUBEROOT = 3'd2;
    localparam CALC_SUM      = 3'd3;
    localparam DONE          = 3'd4;
    localparam IDLE_MULT_OFF = 3'd5;
    localparam CALC_SQUARE_CUBICROOT_STOP = 3'd6;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            ready <= 1'b0;
            mult_start <= 1'b0;
            cubicroot_start <= 1'b0;
            y <= 8'd0;
            a_squared <= 8'd0;
            b_cuberoot <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        // Start calculating a^2
                        mult_start <= 1'b1;
                        state <= IDLE_MULT_OFF;
                    end
                end
                IDLE_MULT_OFF: begin
                    mult_start <= 0;
                    state <= CALC_SQUARE;
                end
                CALC_SQUARE: begin
                    if (!mult_ready) begin
                        a_squared <= mult_result;
                        // Start calculating b^(1/3)
                        cubicroot_start <= 1'b1;
                        state <= CALC_SQUARE_CUBICROOT_STOP;
                    end
                end
                CALC_SQUARE_CUBICROOT_STOP: begin
                    cubicroot_start <= 0;
                    state <= CALC_CUBEROOT;
                end
                CALC_CUBEROOT: begin
                    if (!cubicroot_ready) begin
                        b_cuberoot <= cubicroot_result;
                        state <= CALC_SUM;
                    end
                end
                CALC_SUM: begin
                        y <= b_cuberoot + a_squared;
                        state <= DONE;
                end
                DONE: begin
                    ready <= 1'b1;
                    state <= IDLE;
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
        clk <= 1'b0;
        forever #5 clk <= ~clk; // 100MHz clock: period = 10ns, half-period = 5ns
    end

endmodule
module mult_test;
    wire clk;
    reg rst;
    reg start;
    reg [7:0] a_in;
    reg [7:0] b_in;
    wire [7:0] f_out;
    wire busy_o;
    
    mult mult_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_in(a_in),
        .b_in(b_in),
        .f_out(f_out),
        .busy_o(busy_o)
    );

    clock_gen cg_inst (
        .clk(clk)
    );

    integer i, j;

    initial begin
        rst = 1;
        start = 0;
        a_in = 8'd0;
        b_in = 8'd0;

        #20 rst = 0;
        $display("Multiplier test:");

        for (i = 0; i <= 12; i = i + 1) begin
            for (j = 0; j <= 12; j = j + 1) begin
                #10;
                a_in = i;
                b_in = j;
                start = 1;
                #2 start = 0;

                wait (!busy_o);
                $display("%d * %d = %d", i, j, f_out);
            end
        end

        $display("-=-=-=-=-=-=-=-=-=");

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
        #150000;
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
            $display("cubicroot(%d) = %d (expected %d)", cube, y_out, i);
            #100;
        end
        for (i = 0; i <= 6; i = i + 1) begin
            cube = i * i * i;
            // #10;
            
            x_in <= cube;
            start <= 1;
            #2; start <= 0;

            wait (ready);
            $display("cubicroot(%d) = %d (expected %d)", cube, y_out, i);
            #100;
        end

        $display("-=-=-=-=-=-=-=-=-=");
    end
endmodule

module compute_y_test;
    wire clk;
    reg rst;
    reg start;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] y;
    wire ready;

    compute_y uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .y(y),
        .ready(ready)
    );

    clock_gen cg_inst (
        .clk(clk)
    );

    integer i, j;
    integer real_y;

    initial begin
        // $dumpfile("test.vcd");
        // $dumpvars(0, compute_y_test);
        #250000;
        rst <= 1;
        start <= 0;
        a <= 8'd0;
        b <= 8'd0;
        #20 rst <= 0;
        $display("Function test:");
                

        for (i = 0; i <= 12; i = i + 1) begin
            for (j = 0; j <= 12; j = j + 1) begin
                real_y = i * i + j ** 0.33;
                #10;
                a <= i;
                b <= j;
                start <= 1;
                #10 start = 0;
                
                wait (ready);
                $display("y = %d (Expected: %d^2 + %d^(1/3) = %d + %d = %d)", y, a, b, i * i, j ** 0.33, real_y);
                #10;
            end
            
        end
        

        $finish;
    end
    
endmodule