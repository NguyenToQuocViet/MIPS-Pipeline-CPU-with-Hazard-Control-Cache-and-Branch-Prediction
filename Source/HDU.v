`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 08:38:13 AM
// Design Name: 
// Module Name: HDU
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


module HDU(
    //IF INTERFACE
    output reg          pc_write_en,
    output reg          pc_redirect,
    output reg [31:0]   pc_redirect_addr,

    //ID INTERFACE
    input  wire [4:0]   if_id_rs,
    input  wire [4:0]   if_id_rt,
    input  wire         id_jump,
    input  wire [31:0]  id_jump_target,
    output reg          if_id_write_en,
    output reg          if_id_flush_en,

    //EX INTERFACE
    input  wire [4:0]   id_ex_rt,
    input  wire         id_ex_mem_read,     //Check Load-Use
    input  wire         id_ex_pred_taken,
    input  wire         ex_branch_taken,
    input  wire [31:0]  ex_branch_target,
    input  wire [31:0]  ex_pc_plus4,      
    output reg          id_ex_write_en,
    output reg          id_ex_flush_en,

    //MEM INTERFACE
    input  wire         mem_stall_req,      //Cache Miss
    output reg          ex_mem_write_en,
    output reg          ex_mem_flush_en,

    //WB INTERFACE
    output reg          mem_wb_write_en
);
    
    // Logic comparison
    wire branch_mispredict = (ex_branch_taken != id_ex_pred_taken);
    wire load_use_hazard   = id_ex_mem_read &&y ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt));

    always @(*) begin
        pc_write_en      = 1'b1;
        if_id_write_en   = 1'b1;
        if_id_flush_en   = 1'b0;
        id_ex_write_en   = 1'b1;
        id_ex_flush_en   = 1'b0;
        ex_mem_write_en  = 1'b1;
        ex_mem_flush_en  = 1'b0;
        mem_wb_write_en  = 1'b1;
        
        pc_redirect      = 1'b0;
        pc_redirect_addr = 32'd0;

        //Priority 1: Memory Stall
        if (mem_stall_req) begin
            pc_write_en      = 1'b0;
            if_id_write_en   = 1'b0;
            id_ex_write_en   = 1'b0;
            ex_mem_write_en  = 1'b0;
            mem_wb_write_en  = 1'b0;
        end
        
        //Priority 2: Branch Misprediction
        else if (branch_mispredict) begin
            id_ex_flush_en   = 1'b1;
            if_id_flush_en   = 1'b1;
            ex_mem_flush_en  = 1'b1;
            
            pc_redirect      = 1'b1;
            pc_redirect_addr = ex_branch_taken ? ex_branch_target : ex_pc_plus4;
        end

        //Priority 3: Jump
        else if (id_jump) begin
            if_id_flush_en   = 1'b1;
            pc_redirect      = 1'b1;
            pc_redirect_addr = id_jump_target;
        end

        //Priority 4: Load-Use Hazard
        else if (load_use_hazard) begin
            pc_write_en      = 1'b0;
            if_id_write_en   = 1'b0;
            id_ex_flush_en   = 1'b1; // Insert Bubble
        end
    end
endmodule
