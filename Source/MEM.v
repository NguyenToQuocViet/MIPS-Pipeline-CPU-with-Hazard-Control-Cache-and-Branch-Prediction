`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 08:38:38 AM
// Design Name: 
// Module Name: MEM
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


module MEM(
    // --- 1. SYSTEM INPUTS ---
    input wire          clk,
    input wire          rst_n,

    // --- 2. PIPELINE INPUTS (Từ BUS_EX_MEM) ---
    input wire [31:0]   alu_result_in,      // Address hoặc ALU Result
    input wire [31:0]   reg_data2_in,       // Store Data
    input wire [4:0]    dest_reg_in,        
    
    input wire          mem_read_in,        // Control: Load
    input wire          mem_write_in,       // Control: Store
    input wire          mem_to_reg_in,      
    input wire          reg_write_in,       

    // --- 3. D-CACHE INTERFACE (Giao tiếp với Module DCACHE bên ngoài) ---
    // Output tới D-Cache
    output wire         dcache_en_read_out,  // Enable Read
    output wire         dcache_en_write_out, // Enable Write
    output wire [3:0]   dcache_byte_en_out,  // Byte Enable (cho Store Byte/Word)
    output wire [31:0]  dcache_addr_out,     // Address
    output wire [31:0]  dcache_wdata_out,    // Write Data
    
    // Input từ D-Cache
    input wire [31:0]   dcache_rdata_in,     // Read Data trả về
    input wire          dcache_ready_in,     // Cache báo xong (Hit/Buffered)

    // --- 4. PIPELINE OUTPUTS (Tới BUS_MEM_WB) ---
    output wire [31:0]  mem_data_out,       // Dữ liệu Load (từ Cache)
    output wire [31:0]  alu_result_out,     // ALU Result (Pass-through)
    output wire [4:0]   dest_reg_out,       
    output wire         mem_to_reg_out,     
    output wire         reg_write_out,      
    
    // --- 5. HAZARD CONTROL ---
    output wire         mem_stall_out       // Báo Hazard Unit
);

    // --- LOGIC ---

    // 1. Mapping tín hiệu ra D-Cache
    assign dcache_en_read_out  = mem_read_in;
    assign dcache_en_write_out = mem_write_in;
    assign dcache_byte_en_out  = 4'b1111;      // Mặc định Word (4 bytes)
    assign dcache_addr_out     = alu_result_in; // ALU tính ra địa chỉ
    assign dcache_wdata_out    = reg_data2_in;  // Data store lấy từ Rt

    // 2. Nhận dữ liệu từ D-Cache
    assign mem_data_out = dcache_rdata_in;

    // 3. Pass-through các tín hiệu không dùng ở MEM
    assign alu_result_out = alu_result_in;
    assign dest_reg_out   = dest_reg_in;
    assign mem_to_reg_out = mem_to_reg_in;
    assign reg_write_out  = reg_write_in;

    // 4. Stall Logic
    // Nếu CPU muốn truy cập Memory (Read/Write) mà Cache chưa Ready -> Stall
    assign mem_stall_out = (mem_read_in || mem_write_in) && !dcache_ready_in;

endmodule