`define PRINT_STATUS \
    $display("SWL   R | LEDL  R | LED Full"); \
    $display("%d %d | %d %d | %d", SW[15:8], SW[7:0], LED[15:8], LED[7:0], LED); \
    $display("RST_BTN is %d", RST_BTN); \
    $display("START_BTN is %d", START_BTN); \
    $display("TEST_ON_BTN is %d", TEST_ON_BTN); \
    $display("TEST_RUN_BTN is %d", TEST_RUN_BTN); \
    $display("TEST_OFF_BTN is %d", TEST_OFF_BTN); \
    $display("DONE is %d", DONE); \
    $display("====================================");


module top_test;
    reg [15:0] SW;
    reg CLK100MHZ;
    reg RST_BTN;
    reg START_BTN;
    reg TEST_ON_BTN;
    reg TEST_RUN_BTN;
    reg TEST_OFF_BTN;

    wire DONE;
    wire [15:0] LED;

    top top_inst (
        .SW(SW),
        .CLK100MHZ(CLK100MHZ),
        .RST_BTN(RST_BTN),
        .START_BTN(START_BTN),
        .TEST_ON_BTN(TEST_ON_BTN),
        .TEST_RUN_BTN(TEST_RUN_BTN),
        .TEST_OFF_BTN(TEST_OFF_BTN),
        .DONE(DONE),
        .LED(LED)
    );

    initial begin
        CLK100MHZ <= 0;
        forever #5 CLK100MHZ <= ~CLK100MHZ;
    end

    initial begin
        RST_BTN <= 1;
        START_BTN <= 0;
        TEST_ON_BTN <= 0;
        TEST_RUN_BTN <= 0;
        TEST_OFF_BTN <= 0;
        SW <= 16'h0000;
        #100;
        `PRINT_STATUS;

        RST_BTN <= 0;
        SW[15:8] <= 8'hFF;
        START_BTN <= 1; #10;
        `PRINT_STATUS;

        START_BTN <= 0; #10;
        `PRINT_STATUS;
        
        wait(DONE);
        `PRINT_STATUS;

        $finish;
    end
endmodule

