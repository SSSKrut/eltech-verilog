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
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sum <= 8'd0;
            counter <= 8'd0;
            f_out <= 8'd0;
            busy_o <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        busy_o <= 1'b1;
                        sum <= 8'd0;
                        counter <= 8'd0;
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
module cbrt(
    input clk_i,
    input rst_i,
    input start_i,
    input [7:0] x_bi,
    output reg [7:0] y_bo,
    output reg busy_o
);
    localparam IDLE = 3'h0;
    localparam FIRST_WORK = 3'h1;
    localparam MULTIPLY_1 = 3'h2;
    localparam MULTIPLY_2 = 3'h3;
    localparam SECOND_WORK = 3'h4;
        
    reg [7:0] x;
    reg [7:0] part_result;
    reg [8:0] b;
    reg [4:0] s;
    reg [2:0] state;
    wire end_step;
    wire x_above_b;
    
    reg [7:0] mult_a;
    reg [7:0] mult_b;
    wire [15:0] mult_result;
    reg [7:0] mult_result_reg;
    wire mult_busy;
    reg mult_start;
    
    assign end_step = (s < 3);
    assign x_above_b = (x >= b);
    assign mult_done = mult_busy == 0;
    
    mult multiplier (
        .clk(clk_i),
        .rst(rst_i),
        .a_in(mult_a),
        .b_in(mult_b),
        .start(mult_start),
        .busy_o(mult_busy),
        .f_out(mult_result)
    );

    always @(posedge clk_i) begin
    if (rst_i) begin
        y_bo <= 0;
        b <= 0;
        state <= IDLE;
        mult_start <= 0;
        busy_o <= 0;
    end else begin
        case (state)
            IDLE:
                if (start_i) begin
                    state <= FIRST_WORK;
                    part_result <= 0;
                    x <= x_bi;
                    s <= 5'd6;
                    busy_o <= 1;
                end
            FIRST_WORK:
                begin
                    part_result = part_result << 1;
                    mult_a <= 3;
                    mult_b <= part_result;
                    mult_start <= 1;
                    state <= MULTIPLY_1;
                end
            MULTIPLY_1:
                begin
                    mult_start <= 0;
                    mult_result_reg <= mult_result;
                    if (mult_done) begin
                        mult_a <= mult_result;
                        mult_b <= part_result + 1;
                        mult_result_reg <= 0;
                        mult_start <= 1;
                        state <= MULTIPLY_2;
                    end
                end
            MULTIPLY_2:
                begin
                    mult_start <= 0;
                    mult_result_reg <= mult_result;
                    if (mult_done) begin
                        b <= (mult_result + 1) << s;
                        mult_result_reg <= 0;
                        state <= SECOND_WORK;
                    end
                end
            SECOND_WORK:
                begin
                    if (x_above_b) begin
                        x <= x - b;
                        part_result = part_result + 1;
                    end

                    
                    if (end_step) begin
                        // y_bo <= {4'b0, part_result[3:0]};
                        y_bo <= part_result;
                        state <= IDLE;
                        busy_o <= 0;
                    end else begin
                        s <= s - 3;
                        state <= FIRST_WORK;
                    end
                end
            endcase
        end
    end

endmodule

module test_cbrt;

    reg clk_i;
    reg rst_i;
    reg start_i;
    reg [7:0] x_bi;
    wire [7:0] y_bo;
    wire busy_o;

    cbrt uut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .x_bi(x_bi),
        .y_bo(y_bo),
        .busy_o(busy_o)
    );

    initial begin
        // Initialize inputs
        clk_i = 0;
        rst_i = 0;
        start_i = 0;
        x_bi = 0;

        // Apply reset
        rst_i = 1;
        #10;
        rst_i = 0;
        #10;

        // Test case 1: Cube root of 27 (should be 3)
        x_bi = 8'd27;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 27, Expected Output: 3, Actual Output: %d", y_bo);

        // Test case 2: Cube root of 64 (should be 4)
        x_bi = 8'd64;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 64, Expected Output: 4, Actual Output: %d", y_bo);

        // Test case 3: Cube root of 125 (should be 5)
        x_bi = 8'd125;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 125, Expected Output: 5, Actual Output: %d", y_bo);

        // Test case 4: Cube root of 8 (should be 2)
        x_bi = 8'd8;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 8, Expected Output: 2, Actual Output: %d", y_bo);

        // Test case 5: Cube root of 1 (should be 1)
        x_bi = 8'd1;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 1, Expected Output: 1, Actual Output: %d", y_bo);

        // Test case 6: Cube root of 0 (should be 0)
        x_bi = 8'd0;
        start_i = 1;
        #10;
        start_i = 0;
        wait (busy_o == 0);
        #10;
        $display("Input: 0, Expected Output: 0, Actual Output: %d", y_bo);

        $stop;
    end

    // Clock generation
    always #5 clk_i = ~clk_i;

endmodule