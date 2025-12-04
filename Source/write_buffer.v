`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2025 02:55:14 PM
// Design Name: 
// Module Name: write_buffer
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


module write_buffer (
    //SYSTEM INTERFACE
    input  wire          clk,
    input  wire          rst_n,

    //WRITE INTERFACE (PUSH SIDE)
    input  wire          push_en_in,  
    input  wire [67:0]   data_in,     
    output reg           full_out,    

    //READ INTERFACE (POP SIDE)
    input  wire          pop_en_in, 
    output wire [67:0]   data_out,    
    output reg           empty_out    
);
    
    //LOGIC
    reg [67:0] fifo_mem [0:3];  //mang 68 bit (do rong 4)
  
    reg [1:0]  head_ptr;    //write pointer
    reg [1:0]  tail_ptr;    //read pointer
    
    reg [2:0] count_reg;    
    
    wire push_event;
    wire pop_event;
    
    //push and pop
    assign push_event = push_en_in && !full_out;    //push khi nhan lenh + chua day
    assign pop_event  = pop_en_in  && !empty_out;   //pop khi nhan lenh + khong rong
    
    assign data_out = fifo_mem[tail_ptr];           //data out cua pop
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr  <= 2'd0;
            tail_ptr  <= 2'd0;
            count_reg <= 3'd0;
        end else begin
            //1. Count Logic
            case ({push_event, pop_event})
                2'b00: count_reg <= count_reg;     // nothing
                2'b01: count_reg <= count_reg - 1; // pop
                2'b10: count_reg <= count_reg + 1; // push
                2'b11: count_reg <= count_reg;     // push + pop
                default: count_reg <= count_reg;
            endcase

            //2. Write Logic
            if (push_event) begin
                fifo_mem[head_ptr] <= data_in;
            end

            //3. Pointer Logic
            if (push_event) begin
                head_ptr <= head_ptr + 1'b1; 
            end
            
            if (pop_event) begin
                tail_ptr <= tail_ptr + 1'b1; 
            end
        end
    end

    always @(*) begin
        //stall
        if (count_reg == 3'd4) begin 
            full_out = 1'b1;
        end else begin
            full_out = 1'b0;
        end
        
        //empty
        if (count_reg == 3'd0) begin
            empty_out = 1'b1;
        end else begin
            empty_out = 1'b0;
        end
    end
endmodule
