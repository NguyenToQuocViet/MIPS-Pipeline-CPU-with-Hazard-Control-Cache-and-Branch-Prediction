`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2025 01:01:05 PM
// Design Name: 
// Module Name: EX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module EX(clk, rst_n, reg_data1_in, reg_data2_in, imm_in, pc_plus4_in, rs_addr_in, rt_addr_in, 
rd_addr_in, shamt_in, reg_dst_in, ALU_src_in, mem_to_reg_in, reg_write_in, mem_read_in,
mem_write_in, branch_in, jump_in, use_shamt_in, alu_control_in, forwardA, forwardB, 
ex_mem_result_in, mem_wb_result_in, alu_result_out, branch_target_out, zero_flag_out, 
reg_data2_fwd_out, rd_addr_final_out, mem_to_reg_out, reg_write_out, mem_read_out, 
mem_write_out, branch_out);
    //INPUTS
    input wire        clk;
    input wire        rst_n;
    
    input wire [31:0] reg_data1_in;
    input wire [31:0] reg_data2_in;
    input wire [31:0] imm_in;
    input wire [31:0] pc_plus4_in;
    
    input wire [4:0]  rs_addr_in;
    input wire [4:0]  rt_addr_in;
    input wire [4:0]  rd_addr_in;
    input wire [4:0]  shamt_in;
    
    input wire        reg_dst_in;
    input wire        ALU_src_in;
    input wire        mem_to_reg_in;
    input wire        reg_write_in;
    input wire        mem_read_in;
    input wire        mem_write_in;
    input wire        branch_in;
    input wire        jump_in;
    input wire        use_shamt_in;
    input wire [3:0]  alu_control_in;
    
    input wire [1:0]  forwardA;
    input wire [1:0]  forwardB;
    input wire [31:0] ex_mem_result_in;
    input wire [31:0] mem_wb_result_in; 

    //OUTPUTS
    output wire [31:0] alu_result_out;
    output wire [31:0] branch_target_out;
    output wire        zero_flag_out;
    
    output wire [31:0] reg_data2_fwd_out;
    output wire [4:0]  rd_addr_final_out;
    
    output wire        mem_to_reg_out;
    output wire        reg_write_out;
    output wire        mem_read_out;
    output wire        mem_write_out;
    output wire        branch_out;
    
    //LOGICS
    reg [31:0] data_in_1;
    reg [31:0] data_in_2;
    
    //MUX Forwarding
    always @(*) begin
        case (forwardA)
            2'b00: data_in_1    = reg_data1_in;
            2'b10: data_in_1    = ex_mem_result_in;
            2'b01: data_in_1    = mem_wb_result_in;
            default: data_in_1  = reg_data1_in;
        endcase
        
        case (forwardB)
            2'b00: data_in_2    = reg_data2_in;
            2'b10: data_in_2    = ex_mem_result_in;
            2'b01: data_in_2    = mem_wb_result_in;
            default: data_in_2  = reg_data2_in;
        endcase
    end
    
    reg [31:0] alu_input_A;
    reg [31:0] alu_input_B;
    wire [31:0] shamt_extend;
    
    assign shamt_extend = {27'd0, shamt_in};
    
    //MUX Operands
    always @(*) begin
        if (use_shamt_in)
            alu_input_A = shamt_extend;
        else
            alu_input_A = data_in_1;
            
        if (ALU_src_in)
            alu_input_B = imm_in;
        else 
            alu_input_B = data_in_2;
    end
    
    assign reg_data2_fwd_out = data_in_2;
    
    //ALU
    alu alu_1 (
        .A              (alu_input_A),
        .B              (alu_input_B),
        .ALU_control    (alu_control_in),
        .result         (alu_result_out),
        .zero           (zero_flag_out)
    );
    
    //Branch logic
    wire [31:0] imm_shifted_left_2;
    
    assign imm_shifted_left_2 = {imm_in[29:0], 2'b00};
    assign branch_target_out = pc_plus4_in + imm_shifted_left_2;
    
    //Write
    assign rd_addr_final_out = (reg_dst_in) ? rd_addr_in : rt_addr_in;
    
    //Passthrough
    assign mem_to_reg_out = mem_to_reg_in;
    assign reg_write_out  = reg_write_in;
    assign mem_read_out   = mem_read_in;
    assign mem_write_out  = mem_write_in;
    assign branch_out     = branch_in;
endmodule
