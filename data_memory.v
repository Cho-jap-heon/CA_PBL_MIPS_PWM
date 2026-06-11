//==============================================================================
// Data Memory with MMIO (Memory-Mapped I/O)
//==============================================================================
// Description:
// Standard RAM for data storage, plus memory-mapped registers for I/O.
// 
// Address Map:
// - 0x000 - 0x08F: Internal RAM (256 words, though only 0-63 used here)
// - 0x090        : Switches (Read-Only)
// - 0x098        : PWM Duty Cycle (Write-Only)
// - 0x09C        : PWM Enable (Write-Only)
//==============================================================================
`timescale 1ns / 1ps

module data_memory (
    input  wire        clk,
    input  wire        rst_n,           // Added for PWM reset
    input  wire        mem_write_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [7:0]  switches,
    output wire        pwm_out,
    
    output reg  [31:0] read_data
);
    // 1. Internal RAM (Synchronous Write, Asynchronous Read)
    reg [31:0] ram [0:63]; // 64 words for simplicity (reduce simulation memory)
    wire [31:0] ram_out;
    assign ram_out = ram[addr[7:2]]; // Word-aligned address

    // 2. MMIO Registers
    reg [7:0] pwm_duty;
    reg       pwm_en;

    // PWM Controller Instance
    pwm_controller u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .enable(pwm_en),
        .duty_cycle(pwm_duty),
        .pwm_out(pwm_out)
    );

    // Synchronous Writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_duty <= 8'h00;
            pwm_en   <= 1'b0;
        end else if (mem_write_en) begin
            case (addr)
                32'h00000098: pwm_duty <= write_data[7:0];
                32'h0000009c: pwm_en <= write_data[0];
                default:      ram[addr[7:2]] <= write_data;
            endcase
        end
    end

    // Asynchronous/Combinational Reads
    always @(*) begin
        case (addr)
            32'h00000090: read_data = {24'b0, switches};
            32'h00000098: read_data = {24'b0, pwm_duty};
            32'h0000009c: read_data = {31'b0, pwm_en};
            default:      read_data = ram_out;
        endcase
    end

endmodule
