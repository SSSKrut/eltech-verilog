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

module subs (
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
            y <= a - b;
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
    
    always @(posedge clk or posedge rst) begin
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
                        $display("sum = %d, counter = %d", sum, counter);
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

module cubicroot(
    input clk,
    input rst,
    input start,
    input [15:0] x_in,
    output reg [15:0] y_out,
    output reg ready
);
    // State encoding
    localparam IDLE          = 4'd0;
    localparam INIT          = 4'd1;
    localparam SHIFT_Y       = 4'd2;
    localparam COMPUTE_B1    = 4'd3;
    localparam COMPUTE_B2    = 4'd4;
    localparam COMPUTE_B3    = 4'd5;
    localparam COMPUTE_B4    = 4'd6;
    localparam SHIFT_B       = 4'd7;
    localparam COMPARE       = 4'd8;
    localparam UPDATE_X_Y    = 4'd9;
    localparam DECREMENT_S   = 4'd10;
    localparam DONE          = 4'd11;

    reg [3:0] state;
    reg [15:0] x;
    reg [15:0] y;
    reg [15:0] b;
    reg [5:0] s;
    reg [15:0] temp1, temp2, temp3;

    // Control signals for modules
    reg summ_start;
    wire summ_ready;
    wire [15:0] summ_y;
    reg [15:0] summ_a, summ_b;

    reg diff_start;
    wire diff_ready;
    wire [15:0] diff_y;
    reg [15:0] diff_a, diff_b;

    reg mult1_start, mult2_start;
    wire mult1_ready, mult2_ready;
    wire [15:0] mult1_f_out, mult2_f_out;
    reg [15:0] mult1_a_in, mult1_b_in;
    reg [15:0] mult2_a_in, mult2_b_in;

    summ summ_inst (
        .clk(clk),
        .rst(rst),
        .start(summ_start),
        .a(summ_a),
        .b(summ_b),
        .ready(summ_ready),
        .y(summ_y)
    );

    subs diff_inst (
        .clk(clk),
        .rst(rst),
        .start(diff_start),
        .a(diff_a),
        .b(diff_b),
        .ready(diff_ready),
        .y(diff_y)
    );

    mult mult1_inst (
        .clk(clk),
        .rst(rst),
        .start(mult1_start),
        .a_in(mult1_a_in),
        .b_in(mult1_b_in),
        .f_out(mult1_f_out),
        .ready(mult1_ready)
    );

    mult mult2_inst (
        .clk(clk),
        .rst(rst),
        .start(mult2_start),
        .a_in(mult2_a_in),
        .b_in(mult2_b_in),
        .f_out(mult2_f_out),
        .ready(mult2_ready)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x <= 16'd0;
            y <= 16'd0;
            s <= 6'd0;
            ready <= 1'b0;
            y_out <= 16'd0;
            summ_start <= 1'b0;
            diff_start <= 1'b0;
            mult1_start <= 1'b0;
            mult2_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        x <= x_in;
                        y <= 16'd0;
                        s <= 6'd30;
                        state <= SHIFT_Y;
                    end
                end
                SHIFT_Y: begin
                    // y = 2 * y
                    mult1_a_in <= y;
                    mult1_b_in <= 16'd2;
                    mult1_start <= 1'b1;
                    state <= COMPUTE_B1;
                end
                COMPUTE_B1: begin
                    mult1_start <= 1'b0;
                    if (mult1_ready) begin
                        y <= mult1_f_out;
                        // temp1 = y + 1
                        summ_a <= y;
                        summ_b <= 16'd1;
                        summ_start <= 1'b1;
                        state <= COMPUTE_B2;
                    end
                end
                COMPUTE_B2: begin
                    summ_start <= 1'b0;
                    if (summ_ready) begin
                        temp1 <= summ_y;
                        // temp2 = y * (y + 1)
                        mult1_a_in <= y;
                        mult1_b_in <= temp1;
                        mult1_start <= 1'b1;
                        state <= COMPUTE_B3;
                    end
                end
                COMPUTE_B3: begin
                    mult1_start <= 1'b0;
                    if (mult1_ready) begin
                        temp2 <= mult1_f_out;
                        // temp3 = 3 * temp2
                        mult1_a_in <= 16'd3;
                        mult1_b_in <= temp2;
                        mult1_start <= 1'b1;
                        state <= COMPUTE_B4;
                    end
                end
                COMPUTE_B4: begin
                    mult1_start <= 1'b0;
                    if (mult1_ready) begin
                        temp3 <= mult1_f_out;
                        // b = temp3 + 1
                        summ_a <= temp3;
                        summ_b <= 16'd1;
                        summ_start <= 1'b1;
                        state <= SHIFT_B;
                    end
                end
                SHIFT_B: begin
                    summ_start <= 1'b0;
                    if (summ_ready) begin
                        b <= summ_y << s;
                        state <= COMPARE;
                    end
                end
                COMPARE: begin
                    if (x >= b) begin
                        // x = x - b
                        diff_a <= x;
                        diff_b <= b;
                        diff_start <= 1'b1;
                        state <= UPDATE_X_Y;
                    end else begin
                        state <= DECREMENT_S;
                    end
                end
                UPDATE_X_Y: begin
                    diff_start <= 1'b0;
                    if (diff_ready) begin
                        x <= diff_y;
                        // y = y + 1
                        summ_a <= y;
                        summ_b <= 16'd1;
                        summ_start <= 1'b1;
                        state <= DECREMENT_S;
                    end
                end
                DECREMENT_S: begin
                    summ_start <= 1'b0;
                    if (summ_ready) begin
                        y <= summ_y;
                        if (s >= 6'd3) begin
                            s <= s - 6'd3;
                            state <= SHIFT_Y;
                        end else begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    y_out <= y;
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
        clk = 1'b0;
        forever #1 clk = ~clk;
    end
endmodule

module compute_y (
    input clk,
    input rst,
    input start,
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] y,
    output reg ready
);
    reg [15:0] a_squared;
    reg [15:0] b_cuberoot;
    reg [2:0] state;

    reg mult_start;
    wire mult_ready;
    wire [15:0] mult_result;

    reg cubicroot_start;
    wire cubicroot_ready;
    wire [15:0] cubicroot_result;

    reg summ_start;
    wire summ_ready;
    wire [15:0] summ_result;

    mult mult_inst (
        .clk(clk),
        .rst(rst),
        .start(mult_start),
        .a_in(a),
        .b_in(a),
        .f_out(mult_result),
        .ready(mult_ready)
    );

    cubicroot cubicroot_inst (
        .clk(clk),
        .rst(rst),
        .start(cubicroot_start),
        .x_in(b),
        .y_out(cubicroot_result),
        .ready(cubicroot_ready)
    );

    summ summ_inst (
        .clk(clk),
        .rst(rst),
        .start(summ_start),
        .a(a_squared),
        .b(b_cuberoot),
        .ready(summ_ready),
        .y(summ_result)
    );

    // State machine states
    localparam IDLE          = 3'd0;
    localparam CALC_SQUARE   = 3'd1;
    localparam CALC_CUBEROOT = 3'd2;
    localparam CALC_SUM      = 3'd3;
    localparam DONE          = 3'd4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ready <= 1'b0;
            mult_start <= 1'b0;
            cubicroot_start <= 1'b0;
            summ_start <= 1'b0;
            y <= 16'd0;
            a_squared <= 16'd0;
            b_cuberoot <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        // Start calculating a^2
                        mult_start <= 1'b1;
                        state <= CALC_SQUARE;
                    end
                end
                CALC_SQUARE: begin
                    mult_start <= 1'b0; // Deassert start after one cycle
                    if (mult_ready) begin
                        a_squared <= mult_result;
                        // Start calculating b^(1/3)
                        cubicroot_start <= 1'b1;
                        state <= CALC_CUBEROOT;
                    end
                end
                CALC_CUBEROOT: begin
                    cubicroot_start <= 1'b0; // Deassert start
                    if (cubicroot_ready) begin
                        b_cuberoot <= cubicroot_result;
                        // Start summing a_squared + b_cuberoot
                        summ_start <= 1'b1;
                        state <= CALC_SUM;
                    end
                end
                CALC_SUM: begin
                    summ_start <= 1'b0; // Deassert start
                    if (summ_ready) begin
                        y <= summ_result;
                        ready <= 1'b1;
                        state <= DONE;
                    end
                end
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

