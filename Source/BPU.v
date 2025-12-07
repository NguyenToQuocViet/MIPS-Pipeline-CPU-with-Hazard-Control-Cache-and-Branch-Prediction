`timescale 1ns / 1ps
module BPU(
    input wire          clk,
    input wire          rst_n, 
    
    input wire [31:0]   pc_current_in,      
    output reg          pred_taken_out,     
    output reg [31:0]   pred_target_out,
    
    input wire          update_en_in,           
    input wire [31:0]   branch_pc_in,           
    input wire          branch_actual_taken_in, 
    input wire [31:0]   branch_target_in        
);

    (* ram_style = "distributed" *)
    reg [1:0] bht [0:1023];
    
    (* ram_style = "block" *)
    reg [31:0] btb [0:1023];
    
    wire [9:0] read_idx  = pc_current_in[11:2];
    wire [9:0] write_idx = branch_pc_in[11:2];
    
    integer i;
    
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            bht[i] = 2'b01;
            btb[i] = 32'd0;
        end
    end
    
    // Predict Logic 
    always @(*) begin
        pred_taken_out  = 1'b0;
        pred_target_out = 32'd0;
        
        if (bht[read_idx][1] == 1'b1) begin
            pred_taken_out  = 1'b1;
            pred_target_out = btb[read_idx];
        end
    end
    
    // Update Logic 
    always @(posedge clk) begin
        if (update_en_in) begin
            if (branch_actual_taken_in) 
                btb[write_idx] <= branch_target_in;

            case (bht[write_idx])
                2'b00: bht[write_idx] <= (branch_actual_taken_in) ? 2'b01 : 2'b00;
                2'b01: bht[write_idx] <= (branch_actual_taken_in) ? 2'b10 : 2'b00;
                2'b10: bht[write_idx] <= (branch_actual_taken_in) ? 2'b11 : 2'b01;
                2'b11: bht[write_idx] <= (branch_actual_taken_in) ? 2'b11 : 2'b10;
            endcase
        end
    end
endmodule