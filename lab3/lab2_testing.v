

module clk_test;
    wire clk;

    clock_gen cg_inst (
        .clk(clk)
    );

    initial begin
        $display("Clock test:");
        #1
        $display("clk = %b", clk);
        #1
        $display("clk = %b", clk);
        #1
        $display("clk = %b", clk);
        #1
        $display("clk = %b", clk);
        #1
        $display("clk = %b", clk);
        #1
        $display("clk = %b", clk);
        $display("-=-=-=-=-=-=-=-=-=");
    end
endmodule

module mult_test;
    wire clk;
    reg rst;
    reg start;
    reg [15:0] a_in;
    reg [15:0] b_in;
    wire [15:0] f_out;
    wire ready;

    mult mult_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_in(a_in),
        .b_in(b_in),
        .f_out(f_out),
        .ready(ready)
    );

    clock_gen cg_inst (
        .clk(clk)
    );

    initial begin
        rst = 1;
        start = 0;
        a_in = 16'd0;
        b_in = 16'd0;

        #20 rst = 0;
        $display("Multiplier test:");

        // Test case 1:
        #10;
        a_in = 16'd3;
        b_in = 16'd4;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("3 * 4 = %d", f_out);

        // Test case 2:
        #1
        a_in = 16'd5;
        b_in = 16'd6;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("5 * 6 = %d", f_out);

        // Test case 3:
        #1
        a_in = 16'd255;
        b_in = 16'd255;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("255 * 255 = %d", f_out);

        // Test case 4:
        #1
        a_in = 16'd0;
        b_in = 16'd10;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("0 * 10 = %d", f_out);

        // Test case 5:
        #1
        a_in = 16'd0;
        b_in = 16'd0;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("0 * 0 = %d", f_out);

        // Test case 6:
        #1
        a_in = 16'd2;
        b_in = 16'd9;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("2 * 9 = %d", f_out);

        $display("-=-=-=-=-=-=-=-=-=");
    end
endmodule

module cubicroot_test;
    wire clk;
    reg rst;
    reg start;
    reg [15:0] x_in;
    wire [15:0] y_out;
    wire ready;

    cubicroot cubicroot_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x_in(x_in),
        .y_out(y_out),
        .ready(ready)
    );

    clock_gen cg_inst (
        .clk(clk)
    );

    initial begin
        rst = 1;
        start = 0;
        x_in = 16'd0;

        #40 rst = 0;
        $display("Cubic square test:");

        #1
        x_in = 16'd9;
        start = 1;
        #2 start = 0;

        wait (ready);
        $display("cubicroot(27) = %d", y_out);
        $finish;
    end
endmodule

module compute_y_test;
    reg clk;
    reg rst;
    reg start;
    reg [15:0] a;
    reg [15:0] b;
    wire [15:0] y;
    wire ready;

    // Instantiate the compute_y module
    compute_y uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .y(y),
        .ready(ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        a = 16'd0;
        b = 16'd0;
        #20 rst = 0; // Release reset after 20ns

        // Test case 1
        #10;
        a = 16'd4;
        b = 16'd27; // Cube root of 27 is 3
        start = 1;
        #10 start = 0; // Deassert start

        // Wait for computation to complete
        wait (ready);
        #10;
        $display("y = %d (Expected: 4^2 + 27^(1/3) = 16 + 3 = 19)", y);

        // Test case 2
        #10;
        a = 16'd5;
        b = 16'd8; // Cube root of 8 is 2
        start = 1;
        #10 start = 0;

        wait (ready);
        #10;
        $display("y = %d (Expected: 5^2 + 8^(1/3) = 25 + 2 = 27)", y);

        $finish;
    end
endmodule