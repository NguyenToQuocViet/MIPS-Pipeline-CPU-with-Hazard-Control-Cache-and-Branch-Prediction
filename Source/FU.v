`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2025 11:04:46 AM
// Design Name: 
// Module Name: FU
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


module FU(
    //EX INTERFACE
    input wire [4:0] EX_rs,
    input wire [4:0] EX_rt,
     
    //MEM INTERFACE
    input wire [4:0] MEM_dest_reg,
    input wire       MEM_reg_write,
    
    //WB INTERFACE
    input wire [4:0] WB_dest_reg,
    input wire       WB_reg_write,
       
    //OUTPUT
    output reg [1:0] forwardA, 
    output reg [1:0] forwardB
);
    
    //LOGIC
    
    //Forward Table:
    //00: rs/rt
    //10: EX/MEM forwarding
    //01: MEM/WB forwarding
    //11: not use
       
    always @(*) begin
        //default
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        //forwardA
        if (MEM_reg_write && (MEM_dest_reg == EX_rs) && (MEM_dest_reg != 5'd0))
            forwardA = 2'b10;
        else if (WB_reg_write && (WB_dest_reg == EX_rs) && (WB_dest_reg != 5'd0))
            forwardA = 2'b01;
            
        //forwardB
        if (MEM_reg_write && (MEM_dest_reg == EX_rt) && (MEM_dest_reg != 5'd0))
            forwardB = 2'b10;
        else if (WB_reg_write && (WB_dest_reg == EX_rt) && (WB_dest_reg != 5'd0))
            forwardB = 2'b01;
    end
endmodule
