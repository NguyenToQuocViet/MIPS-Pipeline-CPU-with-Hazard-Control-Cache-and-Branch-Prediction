`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 04:07:17 PM
// Design Name: 
// Module Name: sign_ext
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


module sign_ext(imm_in, imm_out);
    //INPUTS
    input wire [15:0] imm_in;
    
    //OUTPUTS
    output wire [31:0] imm_out;
    
    //Logic
    assign imm_out = { {16{imm_in[15]}}, imm_in};
endmodule
