`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 10:43:12 AM
// Design Name: 
// Module Name: cpu_wrapper
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


module top_wrapper(
    input wire clk,             // Clock 125MHz (từ chân H16)
    input wire rst_n,           // Reset (Switch 0)
    input wire mem_wait_in,     // Giả lập Delay (Switch 1 - Gạt xuống để chạy)
    
    // Output ra LED để debug
    output wire [3:0] led_debug, // 4 LED đơn (Hiện 4 bit cuối của PC)
    output wire led_mem_req      // LED RGB Blue (Báo CPU đang đọc RAM)
    );

    // --- 1. INTERNAL SIGNALS (Dây nối trong bụng chip) ---
    // CPU Interface
    wire [255:0] cpu_mem_rdata;
    wire [31:0]  cpu_mem_addr;
    wire         cpu_mem_req;
    
    // RAM Interface
    wire [5:0]   ram_addr; // Địa chỉ cho RAM (Depth 64 -> cần 6 bit)

    // --- 2. INSTANTIATE CPU (CON TIM) ---
    cpu_top my_cpu (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // Memory Interface (Nối vào BRAM)
        .mem_rdata_in   (cpu_mem_rdata),
        .mem_wait_in    (mem_wait_in),  // Có thể dùng SW1 để pause CPU
        .mem_req_out    (cpu_mem_req),
        .mem_addr_out   (cpu_mem_addr),
        
        // Các chân Write (Không dùng vì đang test ROM)
        .mem_we_out     (), 
        .mem_wdata_out  (),
        .mem_be_out     ()
    );

    // --- 3. ADDRESS MAPPING (QUAN TRỌNG) ---
    // CPU dùng địa chỉ Byte (0, 32, 64...).
    // RAM 256-bit dùng địa chỉ Index (0, 1, 2...).
    // Mỗi dòng RAM chứa 32 bytes (256 bits).
    // => Ta bỏ 5 bit cuối của địa chỉ CPU (2^5 = 32).
    assign ram_addr = cpu_mem_addr[10:5]; 

    // --- 4. INSTANTIATE BLOCK RAM (BỘ NÃO) ---
    blk_mem_gen_0 my_bram (
        .clka   (clk),          // Dùng chung clock với CPU
        .addra  (ram_addr),     // Địa chỉ đã convert
        .douta  (cpu_mem_rdata) // Dữ liệu lệnh bắn về CPU
    );

    // --- 5. HIỂN THỊ RA LED (ĐỂ BIẾT NÓ ĐANG CHẠY) ---
    // Lấy bit [5:2] của PC để xem nó đếm (PC nhảy 0, 4, 8, 12...)
    // Vì cpu_mem_addr là output của CPU nối thẳng ra RAM
    assign led_debug = cpu_mem_addr[5:2]; 
    assign led_mem_req = cpu_mem_req; // Đèn sáng là CPU đang đòi ăn lệnh

endmodule