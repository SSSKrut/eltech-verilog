module top(
    input wire [15:0] SW,
    input wire CLK100MHZ,
    input wire BTNC, //reset
    input wire BTNR, //start
    input wire TEST, //test_btn
    output wire DONE, //ready
    output wire [15:0] LED
);
    reg[7:0] a_input;
    reg[7:0] b_input;
    reg[7:0] y_out;
    
    dut uut (
        .clk(CLK100MHZ),
        .rst(BTNC),
        .start(BTNR),
        .a(a_input),
        .b(b_input),
        .y(y_out),
        .ready(DONE)
    );
    
    reg[7:0] a_lfsr;
    reg[7:0] b_lfsr;
    reg[7:0] bist_out;
    wire bist_test;
    
    bist_controller (
        .test(TEST),
        .bist_test(bist_test),
        .a_lfsr(a_lfsr),
        .b_lfsr(b_lfsr),
        .bist_out(bist_out)
    );
    
    always @(posedge CLK100MHZ) begin
        if (TEST) begin
            
        end else begin
            
        end
    end
    
endmodule