`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 03:02:20 PM
// Design Name: 
// Module Name: BUS_IF_ID
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


module BUS_IF_ID(clk, rst_n, if_id_write_en, if_id_flush_en, instr_in, pc_plus4_in, predicted_taken_in, if_id_instr_out, if_id_pc_plus4_out, if_id_pred_taken_out);
    //INPUTS
    input wire clk, rst_n;
    input wire if_id_write_en, if_id_flush_en, predicted_taken_in;
    
    input wire [31:0] instr_in;
    input wire [31:0] pc_plus4_in;
    
    //OUTPUTS
    output wire [31:0] if_id_instr_out;
    output wire [31:0] if_id_pc_plus4_out;
    output wire        if_id_pred_taken_out;
    
    //Logic
    reg [31:0] instr;
    reg [31:0] pc_plus4;
    reg pred_taken;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr       <= 32'd0;
            pc_plus4    <= 32'd0;
            pred_taken  <= 1'd0;
        end else begin
            if (if_id_flush_en) begin
                instr       <= 32'd0;
                pc_plus4    <= 32'd0;
                pred_taken  <= 1'd0;
            end else if (!if_id_write_en) begin
                instr       <= instr;
                pc_plus4    <= pc_plus4;
                pred_taken  <= pred_taken;
            end else begin
                instr       <= instr_in;
                pc_plus4    <= pc_plus4_in;
                pred_taken  <= predicted_taken_in;
            end
        end
    end
    
    assign if_id_instr_out      = instr;
    assign if_id_pc_plus4_out   = pc_plus4;
    assign if_id_pred_taken_out = pred_taken;
endmodule
