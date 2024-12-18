module top(
    input wire [15:0] SW,
    input wire CLK100MHZ,
    input wire RST_BTN, //reset
    input wire START_BTN, //start
    input wire TEST_ON_BTN, // Test mode on or start new test
    input wire TEST_OFF_BTN, // Test mode off
    output reg DONE, //ready
    output reg [15:0] LED
);

    reg [7:0] a_input;
    reg [7:0] b_input;
    wire [7:0] dut_result;
    reg dut_start;
    wire dut_ready;
    wire bist_dut_start;
    reg test_mode;
    
    dut dut_inst (
        .clk(CLK100MHZ),
        .rst(RST_BTN),
        .start(dut_start),
        .a(a_input),
        .b(b_input),
        .y(dut_result),
        .ready(dut_ready)
    );

    wire [7:0] crc_result;
    wire crc_ready;
    wire bist_crc_start;

    crc8 crc_inst (
        .y_in(dut_result),
        .start(bist_crc_start),
        .rst(RST_BTN),
        .clk(CLK100MHZ),
        .ready(crc_ready),
        .crc_result(crc_result)
    );
    
    wire [7:0] a_lfsr;
    wire [7:0] b_lfsr;
    reg bist_start;
    wire [7:0] test_mode_ctr;
    wire bist_ready;
    
    bist_controller bist_inst (
        .start(bist_start),
        .rst(RST_BTN),
        .clk(CLK100MHZ),
        .dut_ready(dut_ready),
        .crc_ready(crc_ready),
        .ready(bist_ready),
        .dut_start(bist_dut_start),
        .crc_start(bist_crc_start),
        .a_lfsr(a_lfsr),
        .b_lfsr(b_lfsr),
        .test_mode_ctr(test_mode_ctr)
    );
    
    always @(posedge CLK100MHZ) begin
        DONE <= dut_ready;
        if (TEST_OFF_BTN) begin
            test_mode <= 0;
        end
        
        if (test_mode) begin
            if (TEST_ON_BTN && bist_ready) begin 
                bist_start <= 1;
            end else begin
                bist_start <= 0;
                a_input <= a_lfsr;
                b_input <= b_lfsr;
                dut_start <= bist_dut_start;
                LED[15:8] <= test_mode_ctr;
                LED[7:0] <= crc_result;
            end
        end else begin
            if (TEST_ON_BTN) begin 
                test_mode <= 1;
            end else begin
                a_input <= SW[15:8];
                b_input <= SW[7:0];
                dut_start <= START_BTN;
                LED <= dut_result;
            end
        end
    end
    
endmodule