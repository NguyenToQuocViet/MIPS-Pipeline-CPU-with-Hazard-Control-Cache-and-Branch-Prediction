`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 04:14:04 PM
// Design Name: 
// Module Name: Register
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


module register_file(clk, rst_n, reg_write_en, read_addr_1, read_addr_2, write_addr, write_data, read_data_1, read_data_2);
    //INPUTS
    input wire clk, rst_n;
    input wire reg_write_en;
    input wire [4:0] read_addr_1, read_addr_2, write_addr;
    
    input wire [31:0] write_data;
    
    //OUTPUTS
    output wire [31:0] read_data_1, read_data_2;
    
    //Logic
    reg [31:0] reg_file [0:31];
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_file[i] <= 32'd0;
            end
        end else begin
            if (reg_write_en && write_addr != 5'd0) begin
                reg_file[write_addr] <= write_data;
            end
        end
    end
    
    assign read_data_1 = (read_addr_1 == 5'd0) ? 32'd0 : reg_file[read_addr_1];
    assign read_data_2 = (read_addr_2 == 5'd0) ? 32'd0 : reg_file[read_addr_2];
endmodule
