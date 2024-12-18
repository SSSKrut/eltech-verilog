module bist_controller(
    input wire start,
    input wire rst,
    input wire clk,
    input wire dut_ready,
    input wire crc_ready,
    output reg ready,
    output reg dut_start,
    output reg crc_start,
    output reg [7:0] a_lfsr,
    output reg [7:0] b_lfsr,
    output reg [7:0] test_mode_ctr
);
    localparam IDLE           = 3'd0;
    localparam CALC_LFSR      = 3'd1;
    localparam CALC_LFSR_STOP = 3'd2;
    localparam DUT_START      = 3'd3;
    localparam DUT_STOP       = 3'd4;
    localparam CRC_START      = 3'd5;
    localparam CRC_STOP       = 3'd6;
    reg [7:0] test_counter;
    reg [8:0] inner_counter;

    reg [2:0] state;
    reg lfsr_start;
    wire lfsr_ready;
    wire [7:0] lfsr_1;
    wire [7:0] lfsr_2;

    lfsr lfst_inst (
        .clk(clk),
        .rst(rst),
        .start(lfsr_start),
        .ready(lfsr_ready),
        .lfsr1_out(lfsr_1),
        .lfsr2_out(lfsr_2)
    );
    reg init;

    always @(posedge clk) begin
        if (init) begin 
            if (rst) begin
                state <= IDLE;
                inner_counter <= 0;
                test_counter <= 0;
                test_mode_ctr <= 0;
                ready <= 1;
                dut_start <= 0;
                crc_start <= 0;
            end else begin 
                case (state)
                    IDLE: begin
                        if (start) begin
                            state <= CALC_LFSR;
                            ready <= 0;
                        end 
                    end
                    CALC_LFSR: begin
                        if (lfsr_ready) begin
                            lfsr_start <= 1;
                            state <= CALC_LFSR_STOP;
                        end
                    end
                    CALC_LFSR_STOP: begin
                        lfsr_start <= 0;
                        if (lfsr_ready) begin
                            state <= DUT_START;
                        end
                    end
                    DUT_START: begin
                        a_lfsr <= lfsr_1;
                        b_lfsr <= lfsr_2;
                        if (dut_ready) begin
                            dut_start <= 1;
                            state <= DUT_STOP;
                        end
                    end
                    DUT_STOP: begin
                        dut_start <= 0;
                        if (dut_ready) begin
                            state <= CRC_START;
                        end
                    end
                    CRC_START: begin
                        if (crc_ready) begin
                            crc_start <= 1;
                            state <= CRC_STOP;
                        end
                    end
                    CRC_STOP: begin
                        crc_start <= 0;
                        if (crc_ready) begin
                            inner_counter <= inner_counter + 1;
                            if (inner_counter == 256) begin
                                inner_counter <= 0;
                                test_counter <= test_counter + 1;
                                test_mode_ctr <= test_counter;
                                state <= IDLE;
                                ready <= 1;
                            end else begin
                                state <= CALC_LFSR;
                            end
                        end
                    end
                    default: state <= IDLE;
                endcase
            end 
        end else begin
            state <= IDLE;
            inner_counter <= 0;
            test_counter <= 0;
            test_mode_ctr <= 0;
            ready <= 1;
            dut_start <= 0;
            crc_start <= 0;
        end
    end

endmodule
