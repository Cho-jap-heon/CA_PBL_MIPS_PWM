//==============================================================================
// MIPS Processor Testbench (Class 12 - Sync with Class 11)
//==============================================================================
// Description:
// Top-level testbench for verifying the MIPS processor with MMIO.
// Monitors:
// - Program Counter (PC)
// - ALU Results
// - Memory-Mapped PWM output
//==============================================================================
`timescale 1ns / 1ps

module mips_tb;
    reg         clk;
    reg         rst_n;
    reg  [7:0]  switches;
    wire        pwm_out;
    
    // Debug Monitoring
    wire [31:0] pc_out;
    wire [31:0] alu_result;
    
    // Unit Under Test (UUT)
    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .pwm_out(pwm_out),
        .pc_out(pc_out),
        .alu_result(alu_result)
    );
    
    // Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Trace Generation
    initial begin
        $dumpfile("mips.vcd");
        $dumpvars(0, mips_tb);
    end
    
    task check_duty;
        input [7:0] expected;
        begin
            #300;
            if (uut.u_datapath.u_data_mem.pwm_duty !== expected) begin
                $display("FAIL: switches=%0d, duty=%0d, expected=%0d",
                         switches, uut.u_datapath.u_data_mem.pwm_duty, expected);
                $fatal(1);
            end
            $display("PASS: switches=%0d -> duty=%0d", switches, expected);
        end
    endtask

    // Profile B: drive several switch values and verify MMIO propagation.
    initial begin
        rst_n = 0;
        switches = 8'd0;
        #20;
        rst_n = 1;

        check_duty(8'd0);
        #2700;
        switches = 8'd64;
        check_duty(8'd64);
        #2700;
        switches = 8'd128;
        check_duty(8'd128);
        #2700;
        switches = 8'd255;
        check_duty(8'd255);
        #2700;

        if (uut.u_datapath.u_data_mem.pwm_en !== 1'b1) begin
            $display("FAIL: PWM enable was not set");
            $fatal(1);
        end

        $display("PASS: Profile B MMIO and PWM simulation completed");
        $finish;
    end
endmodule
