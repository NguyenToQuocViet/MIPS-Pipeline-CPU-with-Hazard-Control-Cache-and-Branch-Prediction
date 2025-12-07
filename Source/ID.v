`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 03:38:37 PM
// Design Name: 
// Module Name: ID
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


module ID(
    //SYSTEM INTERFACE
    input wire          clk,
    input wire          rst_n,

    //IF STAGE INTERFACE
    input wire [31:0]   instr_in,

    //WB STAGE INTERFACE 
    input wire          wb_reg_write_en,
    input wire [4:0]    wb_write_addr,
    input wire [31:0]   wb_write_data,

    //PIPELINE DATA OUTPUT INTERFACE
    output wire [31:0]  id_reg_data1,
    output wire [31:0]  id_reg_data2,
    output wire [31:0]  id_sign_ext_imm,
    output wire [4:0]   id_rs_addr,
    output wire [4:0]   id_rt_addr,
    output wire [4:0]   id_rd_addr,
    output wire [4:0]   id_shamt,

    //CONTROL SIGNALS INTERFACE
    output wire         reg_dst,
    output wire         ALU_src,
    output wire         mem_to_reg,
    output wire         reg_write,
    output wire         mem_read,
    output wire         mem_write,
    output wire         branch,
    output wire         jump,
    output wire         use_shamt,
    output wire [3:0]   alu_control
);
    
    //LOGIC
    wire [5:0] opcode;
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [4:0] shamt;
    wire [5:0] funct;
    wire [15:0]immediate;
    
    //Hardwire the signals
    assign opcode   = instr_in[31:26];
    assign rs       = instr_in[25:21];
    assign rt       = instr_in[20:16];
    assign rd       = instr_in[15:11];
    assign shamt    = instr_in[10:6];
    assign funct    = instr_in[5:0];
    assign immediate = instr_in[15:0];
    
    //Control Unit
    control_unit control_unit_1 (
        .opcode     (opcode),
        .funct      (funct),
        
        .reg_dst    (reg_dst),
        .ALU_src    (ALU_src),
        .mem_to_reg (mem_to_reg),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .use_shamt  (use_shamt),
        .alu_control(alu_control)
    );
    
    //Register File
    register_file register_file_1 (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .reg_write_en   (wb_reg_write_en),
        .write_addr     (wb_write_addr),
        .write_data     (wb_write_data),
        
        .read_addr_1    (rs),
        .read_data_1    (id_reg_data1), 
        
        .read_addr_2    (rt),
        .read_data_2    (id_reg_data2)  
    );
    
    //Sign Extend
    sign_ext sign_ext_1 (
        .imm_in         (immediate),
        
        .imm_out        (id_sign_ext_imm) 
    );
    
    //gui cac dia chi cho stage sau
    assign id_rs_addr = rs;
    assign id_rt_addr = rt;
    assign id_rd_addr = rd;
    assign id_shamt   = shamt;
endmodule
