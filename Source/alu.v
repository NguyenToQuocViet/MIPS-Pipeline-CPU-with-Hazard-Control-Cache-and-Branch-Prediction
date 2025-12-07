`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2025 01:01:23 PM
// Design Name: 
// Module Name: alu
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


module alu(
    //OPERAND INPUTS INTERFACE
    input wire [31:0]   A,
    input wire [31:0]   B,

    //CONTROL INPUT INTERFACE
    input wire [3:0]    ALU_control,

    //OUTPUTS INTERFACE
    output reg [31:0]   result,
    output reg          zero
);
    
    //LOGIC
    always @(*) begin
        case (ALU_control)
            4'b0000: result = A & B;
            4'b0001: result = A | B;
            4'b0010: result = A + B;
            4'b0011: result = A ^ B;
            4'b0100: result = B << A[4:0];
            4'b0101: result = B >> A[4:0];
            4'b0110: result = A - B;
            4'b0111: result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            4'b1100: result = ~(A | B);
            default: result = 32'hxxxxxxxx; // an toan
        endcase
        
        zero = (result == 32'd0);
    end
endmodule
