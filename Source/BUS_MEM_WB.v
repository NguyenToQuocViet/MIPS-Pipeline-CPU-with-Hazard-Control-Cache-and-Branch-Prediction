`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2025 04:28:46 PM
// Design Name: 
// Module Name: BUS_MEM_WB
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

module BUS_MEM_WB(
    clk, rst_n, 
    mem_wb_write_en, mem_wb_flush_en,
    
    // Data Inputs (Từ MEM Stage)
    mem_data_in, 
    alu_result_in, 
    dest_reg_in,
    
    // Control Inputs (Pass-through)
    mem_to_reg_in, 
    reg_write_in,
    
    // Data Outputs (Tới WB Stage)
    mem_data_out, 
    alu_result_out, 
    dest_reg_out,
    
    // Control Outputs (Tới WB Stage)
    mem_to_reg_out, 
    reg_write_out
);

    // --- INPUTS ---
    input wire          clk;
    input wire          rst_n;
    input wire          mem_wb_write_en; // Tín hiệu cho phép ghi (thường là !stall)
    input wire          mem_wb_flush_en; // Tín hiệu xóa pipeline (nếu có exception)
    
    input wire [31:0]   mem_data_in;     // Dữ liệu đọc từ D-Cache
    input wire [31:0]   alu_result_in;   // Kết quả ALU (hoặc Address)
    input wire [4:0]    dest_reg_in;     // Địa chỉ thanh ghi đích
    
    input wire          mem_to_reg_in;   // 1: Chọn Mem, 0: Chọn ALU
    input wire          reg_write_in;    // 1: Cho phép ghi vào RegFile

    // --- OUTPUTS ---
    output reg [31:0]   mem_data_out;
    output reg [31:0]   alu_result_out;
    output reg [4:0]    dest_reg_out;
    
    output reg          mem_to_reg_out;
    output reg          reg_write_out;

    // --- LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        // 1. Reset hoặc Flush
        if (!rst_n || mem_wb_flush_en) begin
            mem_data_out    <= 32'd0;
            alu_result_out  <= 32'd0;
            dest_reg_out    <= 5'd0;
            mem_to_reg_out  <= 1'd0;
            reg_write_out   <= 1'd0;
        end 
        // 2. Stall (Giữ nguyên giá trị cũ)
        else if (!mem_wb_write_en) begin
            mem_data_out    <= mem_data_out;
            alu_result_out  <= alu_result_out;
            dest_reg_out    <= dest_reg_out;
            mem_to_reg_out  <= mem_to_reg_out;
            reg_write_out   <= reg_write_out;
        end 
        // 3. Normal Operation (Cập nhật giá trị mới)
        else begin
            mem_data_out    <= mem_data_in;
            alu_result_out  <= alu_result_in;
            dest_reg_out    <= dest_reg_in;
            mem_to_reg_out  <= mem_to_reg_in;
            reg_write_out   <= reg_write_in;
        end
    end

endmodule
