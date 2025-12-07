`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 09:16:11 AM
// Design Name: 
// Module Name: IF
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


module IF(
    //SYSTEM SIGNALS
    input wire clk,
    input wire rst_n,
    
    //HDU INTERFACE
    input wire pc_write_en,
    input wire pc_redirect,
    input wire [31:0] pc_redirect_addr,
    
    //BPU INTERFACE
    input wire predicted_taken,
    input wire [31:0] predicted_addr,
    
    //ICACHE INTERFACE
    input wire cache_ready,
    input wire [31:0] instr_in,
    output wire [31:0] pc_current_out,
    
    //PIPELINE INTERFACE
    output wire [31:0] instr_out,
    output wire predicted_taken_out,
    output wire [31:0] pc_plus4_out
);

    //LOGIC
    reg  [31:0] pc_reg;
    wire [31:0] pc_plus4;
    wire        pc_stall;
    wire [31:0] next_pc;
        
    //PC+4
    assign pc_plus4 = pc_reg + 4;
        
    //Stall
    assign pc_stall = (!pc_write_en) || (!cache_ready);
    
    //Next PC
    assign next_pc =    pc_redirect     ? pc_redirect_addr :    //Priority 1: flush -> redirect (branch predict wrong) 
                        pc_stall        ? pc_reg           :    //Priority 2: stall pipeline
                        predicted_taken ? predicted_addr   :    //Priority 3: get predicted address from BTB
                        pc_plus4;                               //Default
                        
    //PC update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'hBFC00000;
        end else begin
            pc_reg <= next_pc;
        end
    end
    
    assign pc_current_out = pc_reg;
    assign pc_plus4_out = pc_plus4;
    assign instr_out = instr_in;
    assign predicted_taken_out = predicted_taken;
endmodule
