module top(
    input wire [15:0] SW,
    input wire CLK100MHZ,
    input wire RST_BTN, //reset
    input wire START_BTN, //start
    input wire TEST_BTN, //test_btn
    output wire DONE, //ready
    output wire [15:0] LED
);
    reg[7:0] a_input;
    reg[7:0] b_input;
    reg[7:0] y_out;
    wire dut_start;

    dut uut (
        .clk(CLK100MHZ),
        .rst(RST_BTN),
        .start(dut_start),
        .a(a_input),
        .b(b_input),
        .y(y_out),
        .ready(DONE)
    );
    
    reg[7:0] a_lfsr;
    reg[7:0] b_lfsr;
    reg[7:0] bist_out;
    reg[7:0] test_mode_ctr;
    wire test_mode;
    wire bist_dut_start;
    wire bist_crc_start;
    
    bist_controller uut (
        .start(TEST_BTN),
        .rst(RST_BTN),
        .clk(CLK100MHZ),
        .test_mode(test_mode),
        .dut_start(bist_dut_start),
        .crc_start(bist_crc_start),
        .a_lfsr(a_lfsr),
        .b_lfsr(b_lfsr),
        .test_mode_ctr(test_mode_ctr)
    );

    reg[7:0] crc_result;

    crc8 uut (
        .y_in(y_out),
        .start(bist_crc_start),
        .rst(RST_BTN),
        .clk(CLK100MHZ),
        .crc_result(crc_result)
    )
    
    always @(posedge CLK100MHZ) begin
        if (bist_test) begin
            a_input <= a_lfsr;
            b_input <= b_lfsr;
            dut_start <= bist_dut_start;
            LEDS[15:8] <= test_mode_ctr;
            LEDS[7:0] <= crc_result;
        end else begin
            a_input <= SW[15:8];
            b_input <= SW[7:0];
            dut_start <= START_BTN;
            LEDS <= y_out;
        end
    end
    
endmodule