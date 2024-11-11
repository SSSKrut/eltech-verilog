`timescale 1ns / 1ps

module clk_test;
    wire clk;

    clock_gen cg_inst (
        .clk(clk)
    );

    initial begin
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
        $finish;
    end
endmodule
