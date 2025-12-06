`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2025 10:47:00 AM
// Design Name: 
// Module Name: WB
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


module WB(
    //BUS MEM WB INTERFACE
    input wire [31:0]   mem_data_in, 
    input wire [31:0]   alu_result_in,  
    input wire [4:0]    dest_reg_in,     
    
    input wire          mem_to_reg_in,    
    input wire          reg_write_in,    

    //REGISTE FILE INTERFACE
    output wire [31:0]  wb_write_data_out, 
    output wire [4:0]   wb_write_addr_out, 
    output wire         wb_reg_write_out   
);
    //LOGIC

    //Data Selection
    assign wb_write_data_out = (mem_to_reg_in) ? mem_data_in : alu_result_in;

    //Address Passing
    assign wb_write_addr_out = dest_reg_in;

    //Safety Interlock
    assign wb_reg_write_out = reg_write_in && (dest_reg_in != 5'd0);
endmodule
