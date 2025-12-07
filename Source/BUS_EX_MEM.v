`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 08:27:04 AM
// Design Name: 
// Module Name: BUS_EX_MEM
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


module BUS_EX_MEM(
    //SYSTEM INTERFACE
    input wire          clk,
    input wire          rst_n,

    //HAZARD CONTROL INTERFACE
    input wire          ex_mem_write_en,
    input wire          ex_mem_flush_en,

    //PIPELINE DATA INPUT INTERFACE 
    input wire [31:0]   alu_result_in,
    input wire [31:0]   branch_target_in,
    input wire [31:0]   reg_data2_fwd_in,
    input wire [4:0]    rd_addr_final_in,
    input wire          zero_flag_in,

    //CONTROL SIGNALS INPUT INTERFACE
    input wire          mem_to_reg_in,
    input wire          reg_write_in,
    input wire          mem_read_in,
    input wire          mem_write_in,
    input wire          branch_in,

    //PIPELINE DATA OUTPUT INTERFACE 
    output reg [31:0]   alu_result_out,
    output reg [31:0]   branch_target_out,
    output reg [31:0]   reg_data2_fwd_out,
    output reg [4:0]    rd_addr_final_out,
    output reg          zero_flag_out,

    //CONTROL SIGNALS OUTPUT INTERFACE 
    output reg          mem_to_reg_out,
    output reg          reg_write_out,
    output reg          mem_read_out,
    output reg          mem_write_out,
    output reg          branch_out
);

    //LOGIC
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || ex_mem_flush_en) begin  //reset or flush  
            alu_result_out      <= 32'd0;
            branch_target_out   <= 32'd0;
            reg_data2_fwd_out   <= 32'd0;
            rd_addr_final_out   <= 5'd0;
            zero_flag_out       <= 1'd0;
            mem_to_reg_out      <= 1'd0;
            reg_write_out       <= 1'd0;
            mem_read_out        <= 1'd0;
            mem_write_out       <= 1'd0;
            branch_out          <= 1'd0;
        end else if (!ex_mem_write_en) begin    //stall
            alu_result_out      <= alu_result_out;
            branch_target_out   <= branch_target_out;
            reg_data2_fwd_out   <= reg_data2_fwd_out;
            rd_addr_final_out   <= rd_addr_final_out;
            zero_flag_out       <= zero_flag_out;
            mem_to_reg_out      <= mem_to_reg_out;
            reg_write_out       <= reg_write_out;
            mem_read_out        <= mem_read_out;
            mem_write_out       <= mem_write_out;
            branch_out          <= branch_out;
        end else begin                          //binh thuong
            alu_result_out      <= alu_result_in;
            branch_target_out   <= branch_target_in;
            reg_data2_fwd_out   <= reg_data2_fwd_in;
            rd_addr_final_out   <= rd_addr_final_in;
            zero_flag_out       <= zero_flag_in;
            mem_to_reg_out      <= mem_to_reg_in;
            reg_write_out       <= reg_write_in;
            mem_read_out        <= mem_read_in;
            mem_write_out       <= mem_write_in;
            branch_out          <= branch_in;
        end
    end
endmodule
