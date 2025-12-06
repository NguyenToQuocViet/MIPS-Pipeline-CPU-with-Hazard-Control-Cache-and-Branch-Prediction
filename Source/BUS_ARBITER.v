`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2025 03:20:19 PM
// Design Name: 
// Module Name: BUS_ARBITER
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


module BUS_ARBITER(
    //SYSTEM INTERFACE
    input wire          clk,
    input wire          rst_n,
    
    //I-CACHE INTERFACE
    input wire          icache_req_in,      
    input wire [31:0]   icache_addr_in,     
    output reg          icache_ready_out,   
    output wire [255:0] icache_data_out,    

    //D-CACHE INTERFACE
    input wire          dcache_read_req_in,
    input wire [31:0]   dcache_addr_in,     
    output reg          dcache_mem_ready_out,
    output wire [255:0] dcache_rdata_out,   
    
    //WRITE BUFFER INTERFACE
    input wire          wb_empty_in,         
    input wire [67:0]   wb_data_in,
    output reg          wb_pop_en_out,       

    //MAIN MEMORY INTERFACE
    input wire [255:0]  mem_rdata_in,      
    input wire          mem_wait_in,      
    output reg          mem_req_out,        
    output reg          mem_we_out,         
    output reg [31:0]   mem_addr_out,       
    output reg [31:0]   mem_wdata_out,      
    output reg [3:0]    mem_be_out         
);

    localparam STATE_IDLE       = 2'd0;
    localparam STATE_D_READ     = 2'd1; 
    localparam STATE_I_READ     = 2'd2; 
    localparam STATE_WRITE      = 2'd3; 
    
    reg [1:0] state_reg, state_next;
    
    //decode data
    wire [31:0] wb_addr = wb_data_in[67:36];
    wire [31:0] wb_data = wb_data_in[35:4];
    wire [3:0]  wb_be   = wb_data_in[3:0];
    
    //fsm
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state_reg <= STATE_IDLE;
        else        
            state_reg <= state_next;
    end
    
    always @(*) begin
    //default
        state_next           = state_reg;
        dcache_mem_ready_out = 1'b0;
        icache_ready_out     = 1'b0;
        wb_pop_en_out        = 1'b0;
        
        mem_req_out   = 1'b0;
        mem_we_out    = 1'b0; 
        mem_addr_out  = 32'b0;
        mem_wdata_out = 32'b0;
        mem_be_out    = 4'b0;

        case (state_reg)
            STATE_IDLE: begin
                if (dcache_read_req_in) //priority 1: dcache read 
                    state_next = STATE_D_READ; 
                else if (icache_req_in) //priority 2: icache read
                    state_next = STATE_I_READ; 
                else if (!wb_empty_in)  //pririty 3: write buffer write (chi write khi nao ranh)
                    state_next = STATE_WRITE;  
                else                         
                    state_next = STATE_IDLE;
            end
            
            STATE_D_READ: begin
                mem_req_out   = 1'b1;   //signal xin du lieu tu mem
                mem_we_out    = 1'b0;   //read
                mem_addr_out  = dcache_addr_in; //dcache
                
                if (!mem_wait_in) begin //neu hit -> tra ve ngay
                    dcache_mem_ready_out = 1'b1; 
                    state_next           = STATE_IDLE;
                end
            end
            
            STATE_I_READ: begin
                mem_req_out   = 1'b1;   //signal xin du lieu tu mem
                mem_we_out    = 1'b0;   //read
                mem_addr_out  = icache_addr_in; //icache

                if (!mem_wait_in) begin //neu hit -> tra ve ngay
                    icache_ready_out = 1'b1;
                    state_next       = STATE_IDLE;
                end
            end
            
            STATE_WRITE: begin
                mem_req_out   = 1'b1;   
                mem_we_out    = 1'b1;   //write
                
                //write data
                mem_addr_out  = wb_addr;
                mem_wdata_out = wb_data;
                mem_be_out    = wb_be;
                
                if (!mem_wait_in) begin //neu hit -> tra ve ngay
                    wb_pop_en_out = 1'b1; //xoa buffer
                    state_next    = STATE_IDLE;
                end
            end
            
            default: state_next = STATE_IDLE;
        endcase
    end 
    
    //data tu cache 
    assign dcache_rdata_out = mem_rdata_in; 
    assign icache_data_out  = mem_rdata_in;
endmodule