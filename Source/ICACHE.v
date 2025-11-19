`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 05:11:41 PM
// Design Name: 
// Module Name: ICACHE
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


module ICACHE(clk, rst_n, cpu_addr_in, cpu_req_in, cpu_data_out, cpu_ready_out, mem_req_out, mem_addr_out, mem_data_in, mem_ready_in);
    //INPUTS
    input wire  clk, rst_n;
    input wire  [31:0] cpu_addr_in;
    input wire  cpu_req_in;
    
    input wire  [255:0] mem_data_in;
    input wire  mem_ready_in;
    
    //OUTPUTS
    output wire cpu_data_out;
    output wire cpu_ready_out;
    
    output wire mem_req_out;
    output wire [31:0] mem_addr_out;
    
    //LOGIC
    
    //Controller -> 4 Data
    wire [4:0]  s_idx_out;       
    wire [21:0] s_tag_in_out;   
    wire [255:0] s_data_in_out;  
    wire [3:0]  s_way_we_out;    
    wire [2:0]  s_lru_in_out;   
    wire        s_lru_we_out;    
    
    //4 Data-> Controller
    wire [21:0] s_tag_out_0;     
    wire [21:0] s_tag_out_1;
    wire [21:0] s_tag_out_2;
    wire [21:0] s_tag_out_3;

    wire        s_valid_out_0;   
    wire        s_valid_out_1;
    wire        s_valid_out_2;
    wire        s_valid_out_3;

    wire [2:0]  s_lru_out_in;    

    wire [255:0] s_data_out_0;   
    wire [255:0] s_data_out_1;
    wire [255:0] s_data_out_2;
    wire [255:0] s_data_out_3;
    
    icache_ctrl icache_ctrl_1 (
        .clk                (clk),
        .rst_n              (rst_n),
        .cpu_addr_in        (cpu_addr_in),
        .cpu_req_in         (cpu_req_in),
        .cpu_data_out       (cpu_data_out),
        .cpu_ready_out      (cpu_ready_out),
        
        .array_idx_out      (s_idx_out),
        .array_tag_in_out   (s_tag_in_out),
        .array_data_in_out  (s_data_in_out),
        .array_way_we_out   (s_way_we_out),
        .array_lru_in_out   (s_lru_in_out),
        .array_lru_we_out   (s_lru_we_out),
        
        .array_tag_out_0     (s_tag_out_0),
        .array_tag_out_1     (s_tag_out_1),
        .array_tag_out_2     (s_tag_out_2),
        .array_tag_out_3     (s_tag_out_3),

        .array_valid_out_0   (s_valid_out_0),
        .array_valid_out_1   (s_valid_out_1),
        .array_valid_out_2   (s_valid_out_2),
        .array_valid_out_3   (s_valid_out_3),

        .array_lru_out_in    (s_lru_out_in),

        .array_data_out_0    (s_data_out_0),
        .array_data_out_1    (s_data_out_1),
        .array_data_out_2    (s_data_out_2),
        .array_data_out_3    (s_data_out_3),
        
        .mem_req_out        (mem_req_out),
        .mem_addr_out       (mem_addr_out),
        .mem_data_in        (mem_data_in),
        .mem_ready_in       (mem_ready_in)
    );
    
    tag_array tag_array_1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .idx_in     (s_idx_out), 
        .tag_in     (s_tag_in_out), 
        .wr_en_in   (s_way_we_out), 
        
        .tag_out_0  (s_tag_out_0), 
        .tag_out_1  (s_tag_out_1), 
        .tag_out_2  (s_tag_out_2), 
        .tag_out_3  (s_tag_out_3)
    );
    
    valid_array valid_array_1 (
        .clk         (clk), 
        .rst_n       (rst_n),
        .idx_in      (s_idx_out),     
        .wr_en_in    (s_way_we_out), 
        
        .valid_out_0 (s_valid_out_0), 
        .valid_out_1 (s_valid_out_1), 
        .valid_out_2 (s_valid_out_2), 
        .valid_out_3 (s_valid_out_3)
    );
    
    data_array data_array_1 (
        .clk        (clk), 
        .rst_n      (rst_n),
        .idx_in     (s_idx_out), 
        .wr_en_in   (s_way_we_out), 
        
        .data_in    (s_data_in_out),
        
        .data_out_0 (s_data_out_0), 
        .data_out_1 (s_data_out_1), 
        .data_out_2 (s_data_out_2), 
        .data_out_3 (s_data_out_3)
    );
    
    lru_array lru_array_1 (
        .clk        (clk), 
        .rst_n      (rst_n), 
        .idx_in     (s_idx_out), 
        .wr_en_in   (s_lru_we_out), 
        
        .lru_in     (s_lru_in_out), 
        .lru_out    (s_lru_out_in)
    );
endmodule
