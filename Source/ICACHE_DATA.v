`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 09:59:20 AM
// Design Name: 
// Module Name: ICACHE_DATA
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


module tag_array(clk, rst_n, idx_in, tag_in, wr_en_in, tag_out_0, tag_out_1, tag_out_2, tag_out_3);
    //INPUTS
    input wire          clk, rst_n;
    input wire [4:0]    idx_in;
    input wire [21:0]   tag_in;
    input wire [3:0]    wr_en_in;
    
    //OUTPUTS
    output wire [21:0] tag_out_0;
    output wire [21:0] tag_out_1;
    output wire [21:0] tag_out_2;
    output wire [21:0] tag_out_3;
    
    //Mang 4 bo nho, 22 bit 32 vi tri
    reg [21:0] tag_memory_0 [0:31];
    reg [21:0] tag_memory_1 [0:31];
    reg [21:0] tag_memory_2 [0:31];
    reg [21:0] tag_memory_3 [0:31];
    
    //Logic ghi
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            //Reset toan bo tag quan ly
            for (i = 0; i < 32; i = i + 1) begin
                tag_memory_0[i] <= 22'd0;
                tag_memory_1[i] <= 22'd0;
                tag_memory_2[i] <= 22'd0;
                tag_memory_3[i] <= 22'd0;
            end
        end else begin
            //Ghi khi co tin hieu
            if (wr_en_in[0]) 
                tag_memory_0[idx_in] <= tag_in;
            if (wr_en_in[1]) 
                tag_memory_1[idx_in] <= tag_in;
            if (wr_en_in[2]) 
                tag_memory_2[idx_in] <= tag_in;
            if (wr_en_in[3]) 
                tag_memory_3[idx_in] <= tag_in;
        end
    end
    
    //Logic doc
    assign tag_out_0 = tag_memory_0[idx_in];
    assign tag_out_1 = tag_memory_1[idx_in];
    assign tag_out_2 = tag_memory_2[idx_in];
    assign tag_out_3 = tag_memory_3[idx_in];
endmodule

module valid_array(clk, rst_n, idx_in, wr_en_in, valid_out_0, valid_out_1, valid_out_2, valid_out_3);
    //INPUTS
    input wire          clk, rst_n;
    input wire [4:0]    idx_in;
    input wire [3:0]    wr_en_in;
    
    //OUTPUTS
    output wire valid_out_0;
    output wire valid_out_1;
    output wire valid_out_2;
    output wire valid_out_3;
    
    //Mang 4 bo nho, 1 bit 32 vi tri
    reg valid_memory_0 [0:31];
    reg valid_memory_1 [0:31];
    reg valid_memory_2 [0:31];
    reg valid_memory_3 [0:31];
    
    //Logic ghi
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                valid_memory_0[i] <= 1'd0;
                valid_memory_1[i] <= 1'd0;
                valid_memory_2[i] <= 1'd0;
                valid_memory_3[i] <= 1'd0;
            end
        end else begin
            if (wr_en_in[0])
                valid_memory_0[idx_in] <= 1'd1;
            if (wr_en_in[1])
                valid_memory_1[idx_in] <= 1'd1;
            if (wr_en_in[2])
                valid_memory_2[idx_in] <= 1'd1;
            if (wr_en_in[3])
                valid_memory_3[idx_in] <= 1'd1;
        end
    end
    
    //Logic doc
    assign valid_out_0 = valid_memory_0[idx_in];
    assign valid_out_1 = valid_memory_1[idx_in];
    assign valid_out_2 = valid_memory_2[idx_in];
    assign valid_out_3 = valid_memory_3[idx_in];
endmodule

module lru_array(clk, rst_n, idx_in, wr_en_in, lru_in, lru_out);
    //INPUTS
    input wire          clk, rst_n;
    input wire [4:0]    idx_in;
    input wire          wr_en_in;
    input wire [2:0]    lru_in;
    
    //OUTPUTS
    output wire [2:0] lru_out;
    
    //Mang 3 bit, 32 vi tri
    reg [2:0] lru_memory [0:31];
    
    //Logic ghi
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                lru_memory[i] <= 3'd0;
            end
        end else begin
            if (wr_en_in)
                lru_memory[idx_in] <= lru_in;
        end
    end
    
    //Logic doc
    assign lru_out = lru_memory[idx_in];
endmodule

module data_array(clk, rst_n, idx_in, wr_en_in, data_in, data_out_0, data_out_1, data_out_2, data_out_3);
    //INPUTS
    input wire          clk, rst_n;
    input wire [4:0]    idx_in;
    input wire [3:0]    wr_en_in; 
    input wire [255:0]  data_in;
    
    //OUTPUTS
    output wire [255:0] data_out_0;
    output wire [255:0] data_out_1;
    output wire [255:0] data_out_2;
    output wire [255:0] data_out_3;
    
    //4 mang bo nho, 256 bit 32 vi tri
    reg [255:0] data_memory_0 [0:31];
    reg [255:0] data_memory_1 [0:31];
    reg [255:0] data_memory_2 [0:31];
    reg [255:0] data_memory_3 [0:31];
    
    //Logic ghi
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                data_memory_0[i] <= 256'd0;
                data_memory_1[i] <= 256'd0;
                data_memory_2[i] <= 256'd0;
                data_memory_3[i] <= 256'd0;
            end
        end else begin
            if (wr_en_in[0])
                data_memory_0[idx_in] <= data_in;
            if (wr_en_in[1])
                data_memory_1[idx_in] <= data_in;
            if (wr_en_in[2])
                data_memory_2[idx_in] <= data_in;
            if (wr_en_in[3])
                data_memory_3[idx_in] <= data_in;
        end
    end
    
    //Logic doc
    assign data_out_0 = data_memory_0[idx_in];
    assign data_out_1 = data_memory_1[idx_in];
    assign data_out_2 = data_memory_2[idx_in];
    assign data_out_3 = data_memory_3[idx_in];
endmodule