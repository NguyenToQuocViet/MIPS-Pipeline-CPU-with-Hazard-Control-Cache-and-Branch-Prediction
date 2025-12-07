`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 03:39:24 PM
// Design Name: 
// Module Name: BUS_ID_EX
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


module BUS_ID_EX(
    //SYSTEM INTERFACE
    input wire          clk,
    input wire          rst_n,

    //HAZARD CONTROL INTERFACE 
    input wire          id_ex_write_en,
    input wire          id_ex_flush_en,

    //PIPELINE DATA INPUT INTERFACE 
    input wire [31:0]   reg_data1_in,
    input wire [31:0]   reg_data2_in,
    input wire [31:0]   imm_in,
    input wire [31:0]   pc_plus4_in,
    input wire          pred_taken_in,
    input wire [4:0]    rs_addr_in,
    input wire [4:0]    rt_addr_in,
    input wire [4:0]    rd_addr_in,
    input wire [4:0]    shamt_in,

    //CONTROL SIGNALS INPUT INTERFACE 
    input wire          reg_dst_in,
    input wire          ALU_src_in,
    input wire          mem_to_reg_in,
    input wire          reg_write_in,
    input wire          mem_read_in,
    input wire          mem_write_in,
    input wire          branch_in,
    input wire          jump_in,
    input wire          use_shamt_in,
    input wire [3:0]    alu_control_in,

    //PIPELINE DATA OUTPUT INTERFACE 
    output reg [31:0]   reg_data1_out,
    output reg [31:0]   reg_data2_out,
    output reg [31:0]   imm_out,
    output reg [31:0]   pc_plus4_out,
    output reg          pred_taken_out,
    output reg [4:0]    rs_addr_out,
    output reg [4:0]    rt_addr_out,
    output reg [4:0]    rd_addr_out,
    output reg [4:0]    shamt_out,

    //CONTROL SIGNALS OUTPUT INTERFACE 
    output reg          reg_dst_out,
    output reg          ALU_src_out,
    output reg          mem_to_reg_out,
    output reg          reg_write_out,
    output reg          mem_read_out,
    output reg          mem_write_out,
    output reg          branch_out,
    output reg          jump_out,
    output reg          use_shamt_out,
    output reg [3:0]    alu_control_out
);


    //LOGIC
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || id_ex_flush_en) begin //reset hoac flush
            reg_data1_out   <= 32'd0;
            reg_data2_out   <= 32'd0;
            imm_out         <= 32'd0;
            pc_plus4_out    <= 32'd0;
            pred_taken_out  <= 1'd0;
            rs_addr_out     <= 5'd0;
            rt_addr_out     <= 5'd0;
            rd_addr_out     <= 5'd0;
            shamt_out       <= 5'd0;
            reg_dst_out     <= 1'd0;
            ALU_src_out     <= 1'd0;
            mem_to_reg_out  <= 1'd0;
            reg_write_out   <= 1'd0;
            mem_read_out    <= 1'd0;
            mem_write_out   <= 1'd0;
            branch_out      <= 1'd0;
            jump_out        <= 1'd0;
            use_shamt_out   <= 1'd0;
            alu_control_out <= 4'd0;
        end else if (!id_ex_write_en) begin //stall
            reg_data1_out   <= reg_data1_out;
            reg_data2_out   <= reg_data2_out;
            imm_out         <= imm_out;
            pc_plus4_out    <= pc_plus4_out;
            pred_taken_out  <= pred_taken_out;
            rs_addr_out     <= rs_addr_out;
            rt_addr_out     <= rt_addr_out;
            rd_addr_out     <= rd_addr_out;
            shamt_out       <= shamt_out;
            reg_dst_out     <= reg_dst_out;
            ALU_src_out     <= ALU_src_out;
            mem_to_reg_out  <= mem_to_reg_out;
            reg_write_out   <= reg_write_out;
            mem_read_out    <= mem_read_out;
            mem_write_out   <= mem_write_out;
            branch_out      <= branch_out;
            jump_out        <= jump_out;
            use_shamt_out   <= use_shamt_out;
            alu_control_out <= alu_control_out;
        end else begin  //binh thuong
            reg_data1_out   <= reg_data1_in;
            reg_data2_out   <= reg_data2_in;
            imm_out         <= imm_in;
            pc_plus4_out    <= pc_plus4_in;
            pred_taken_out  <= pred_taken_in;
            rs_addr_out     <= rs_addr_in;
            rt_addr_out     <= rt_addr_in;
            rd_addr_out     <= rd_addr_in;
            shamt_out       <= shamt_in;
            reg_dst_out     <= reg_dst_in;
            ALU_src_out     <= ALU_src_in;
            mem_to_reg_out  <= mem_to_reg_in;
            reg_write_out   <= reg_write_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            branch_out      <= branch_in;
            jump_out        <= jump_in;
            use_shamt_out   <= use_shamt_in;
            alu_control_out <= alu_control_in;
        end
    end
endmodule
