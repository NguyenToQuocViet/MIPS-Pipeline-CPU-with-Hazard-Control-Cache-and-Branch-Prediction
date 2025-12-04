`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 08:45:08 AM
// Design Name: 
// Module Name: DCACHE
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


module DCACHE(
    //SYSTEM INTERFACE
    input wire          clk,
    input wire          rst_n,

    //CPU INTERFACE
    input wire          mem_read_in,      
    input wire          mem_write_in,     
    input wire [3:0]    mem_byte_en_in,   
    input wire [31:0]   mem_addr_in,
    input wire [31:0]   mem_wdata_in,
    
    output wire [31:0]  mem_rdata_out,
    output wire         mem_ready_out,

    //BUS ARBITER INTERFACE
    output wire         dcache_req_out,  
    output wire [31:0]  dcache_addr_out,  
    input wire          arb_ready_in,     
    input wire [255:0]  mem_data_in,      

    output wire         wb_empty_out,     
    output wire [67:0]  wb_data_to_arb_out, 
    input wire          wb_pop_en_in      
);

    //INTERNAL WIRES
    //Controller <-> Arrays
    wire [4:0]      s_idx;
    wire [21:0]     s_tag_in;
    wire [255:0]    s_data_in;
    wire [3:0]      s_way_we;
    wire [2:0]      s_lru_in;
    wire            s_lru_we;

    wire [21:0]     s_tag_out_0;
    wire [21:0]     s_tag_out_1;
    wire [21:0]     s_tag_out_2;
    wire [21:0]     s_tag_out_3;
    
    wire            s_valid_out_0;
    wire            s_valid_out_1;
    wire            s_valid_out_2;
    wire            s_valid_out_3;
    
    wire [255:0]    s_data_out_0;
    wire [255:0]    s_data_out_1;
    wire [255:0]    s_data_out_2;
    wire [255:0]    s_data_out_3;
    
    wire [2:0]      s_lru_out;

    //Controller <-> Write Buffer
    wire         s_wb_req;
    wire         s_wb_full;
    wire [31:0]  s_wb_addr;
    wire [31:0]  s_wb_data;
    wire [3:0]   s_wb_be;
    wire [67:0]  s_wb_data_combined;
    
    assign s_wb_data_combined = {s_wb_addr, s_wb_data, s_wb_be};
    
    // Controller
    dcache_ctrl dcache_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n), 
        
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in), 
        .addr_in(mem_addr_in), 
        .data_to_write_in(mem_wdata_in), 
        .mem_byte_en_in(mem_byte_en_in),
        .cache_ready_out(mem_ready_out), 
        .data_read_out(mem_rdata_out), 
        
        .tag_out_0(s_tag_out_0), 
        .tag_out_1(s_tag_out_1), 
        .tag_out_2(s_tag_out_2), 
        .tag_out_3(s_tag_out_3),
        
        .valid_out_0(s_valid_out_0), 
        .valid_out_1(s_valid_out_1), 
        .valid_out_2(s_valid_out_2), 
        .valid_out_3(s_valid_out_3),
        
        .data_out_0(s_data_out_0), 
        .data_out_1(s_data_out_1), 
        .data_out_2(s_data_out_2), 
        .data_out_3(s_data_out_3),
        .lru_out_in(s_lru_out), 
        
        .wb_full_in(s_wb_full), 
        .wb_req_out(s_wb_req), 
        .wb_addr_out(s_wb_addr), 
        .wb_data_out(s_wb_data), 
        .wb_byte_en_out(s_wb_be), 
        
        .dcache_mem_ready_in(arb_ready_in),   
        .dcache_rdata_in(mem_data_in),  
        .dcache_read_req_out(dcache_req_out), 
        .dcache_addr_out(dcache_addr_out),

        .array_idx_out(s_idx), 
        .array_tag_in(s_tag_in), 
        .array_data_in(s_data_in), 
        .array_way_we_out(s_way_we), 
        .array_lru_in(s_lru_in), 
        .array_lru_we_out(s_lru_we)
    );

    // Write Buffer 
    write_buffer write_buffer_inst (
        .clk(clk), 
        .rst_n(rst_n), 
        
        .push_en_in(s_wb_req), 
        .data_in(s_wb_data_combined), 
        .full_out(s_wb_full), 
        .pop_en_in(wb_pop_en_in), 
        .data_out(wb_data_to_arb_out), 
        .empty_out(wb_empty_out)
    );

    // Arrays
    tag_array tag_array_inst (
        .clk(clk), 
        .rst_n(rst_n), 
        
        .idx_in(s_idx), 
        .tag_in(s_tag_in), 
        .wr_en_in(s_way_we), 
        
        .tag_out_0(s_tag_out_0), 
        .tag_out_1(s_tag_out_1), 
        .tag_out_2(s_tag_out_2), 
        .tag_out_3(s_tag_out_3)
    );

    valid_array valid_array_inst (
        .clk(clk), 
        .rst_n(rst_n), 
        .idx_in(s_idx), 
        .wr_en_in(s_way_we), 
        
        .valid_out_0(s_valid_out_0), 
        .valid_out_1(s_valid_out_1), 
        .valid_out_2(s_valid_out_2), 
        .valid_out_3(s_valid_out_3)
    );

    data_array data_array_inst (
        .clk(clk), 
        .rst_n(rst_n), 
        
        .idx_in(s_idx), 
        .wr_en_in(s_way_we), 
        .data_in(s_data_in), 
        
        .data_out_0(s_data_out_0), 
        .data_out_1(s_data_out_1), 
        .data_out_2(s_data_out_2), 
        .data_out_3(s_data_out_3)
    );

    lru_array lru_array_inst (
        .clk(clk), 
        .rst_n(rst_n),
         
        .idx_in(s_idx), 
        .wr_en_in(s_lru_we), 
        .lru_in(s_lru_in), 
        .lru_out(s_lru_out)
    );

endmodule