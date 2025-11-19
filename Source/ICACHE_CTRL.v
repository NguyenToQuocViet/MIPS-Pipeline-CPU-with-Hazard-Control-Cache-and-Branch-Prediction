`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 09:52:13 AM
// Design Name: 
// Module Name: ICACHE_CTRL
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


module icache_ctrl(clk, rst_n, cpu_addr_in, cpu_req_in, cpu_data_out, cpu_ready_out, array_idx_out, array_tag_in_out, array_data_in_out,
array_way_we_out, array_lru_in_out, array_lru_we_out, array_tag_out_0, array_tag_out_1, array_tag_out_2, array_tag_out_3, array_valid_out_0,
array_valid_out_1, array_valid_out_2, array_valid_out_3, array_lru_out_in, array_data_out_0, array_data_out_1, array_data_out_2, array_data_out_3,
mem_req_out, mem_addr_out, mem_data_in, mem_ready_in);
    //CPU Interface
    input wire        clk;
    input wire        rst_n;
    input wire [31:0] cpu_addr_in;
    input wire        cpu_req_in;
    output wire[31:0] cpu_data_out;
    output wire       cpu_ready_out;
    
    //DATA Input Interface
    output wire   [4:0]  array_idx_out;
    output wire   [21:0] array_tag_in_out;
    output reg    [255:0] array_data_in_out;
    output reg    [3:0]  array_way_we_out;
    output reg    [2:0]  array_lru_in_out;
    output reg           array_lru_we_out;
    
    //DATA Output Interface
    input wire     [21:0] array_tag_out_0;
    input wire     [21:0] array_tag_out_1;
    input wire     [21:0] array_tag_out_2;
    input wire     [21:0] array_tag_out_3;

    input wire            array_valid_out_0;
    input wire            array_valid_out_1;
    input wire            array_valid_out_2;
    input wire            array_valid_out_3;

    input wire     [2:0]  array_lru_out_in;

    input wire     [255:0] array_data_out_0;
    input wire     [255:0] array_data_out_1;
    input wire     [255:0] array_data_out_2;
    input wire     [255:0] array_data_out_3;

    //Memory Interface
    output reg          mem_req_out;
    output reg  [31:0]  mem_addr_out;
    input wire  [255:0] mem_data_in;
    input wire          mem_ready_in;
    
    //Tach cac bit trong addr
    wire [21:0] addr_tag;
    wire [4:0]  addr_index;
    wire [4:0]  addr_offset;
    
    assign addr_tag    = cpu_addr_in[31:10];
    assign addr_index  = cpu_addr_in[9:5];
    assign addr_offset = cpu_addr_in[4:0];
    
    assign array_idx_out = addr_index;
    assign array_tag_in_out = addr_tag;
      
    //Hit logic
    wire hit_way_0;
    wire hit_way_1;
    wire hit_way_2;
    wire hit_way_3;
    
    assign hit_way_0 = (addr_tag == array_tag_out_0) && (array_valid_out_0);
    assign hit_way_1 = (addr_tag == array_tag_out_1) && (array_valid_out_1);
    assign hit_way_2 = (addr_tag == array_tag_out_2) && (array_valid_out_2);
    assign hit_way_3 = (addr_tag == array_tag_out_3) && (array_valid_out_3);
    
    //Data Selection
    wire [255:0] selected_data_line;
    
    assign selected_data_line = (hit_way_0) ? array_data_out_0:
                                (hit_way_1) ? array_data_out_1:
                                (hit_way_2) ? array_data_out_2:
                                (hit_way_3) ? array_data_out_3:
                                256'd0;
                                
    reg [31:0] instruction_word;
    
    always @(*) begin
        case(addr_offset[4:2])
            3'b000: instruction_word = selected_data_line[31:0];  
            3'b001: instruction_word = selected_data_line[63:32];  
            3'b010: instruction_word = selected_data_line[95:64];  
            3'b011: instruction_word = selected_data_line[127:96]; 
            3'b100: instruction_word = selected_data_line[159:128];
            3'b101: instruction_word = selected_data_line[191:160];
            3'b110: instruction_word = selected_data_line[223:192];
            3'b111: instruction_word = selected_data_line[255:224];
            default: instruction_word = 32'd0;
        endcase
    end
    
    assign cpu_data_out = instruction_word;
    
    //Hit
    wire is_hit;
    
    assign is_hit = hit_way_0 | hit_way_1 | hit_way_2 | hit_way_3;
    
    //Cache MISS logic
        //FSM
    reg [1:0] state_reg;
    reg [1:0] next_state;
    
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] MISS_REQ_MEM = 2'b01;
    localparam [1:0] MISS_WAIT_MEM = 2'b10;
    localparam [1:0] MISS_REFILL = 2'b11;
            
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= next_state;
        end
    end
        //State Logic
    always @(*) begin
        //default
        next_state = state_reg;
        
        case (state_reg)
            IDLE: begin
                if (cpu_req_in && !is_hit)
                    next_state = MISS_REQ_MEM;
                //Cache HIT thi cu giu nguyen IDLE
            end
            
            MISS_REQ_MEM: begin
                next_state = MISS_WAIT_MEM;
                //Logic xu ly req sang Mem xu ly rieng
            end
            
            MISS_WAIT_MEM: begin
                if (mem_ready_in)
                    next_state = MISS_REFILL;
            end
            
            MISS_REFILL: begin
                next_state = IDLE;
                //Logic thay the Cache xu ly rieng
            end
            
            default: next_state = IDLE;
        endcase 
    end
    
        //Ready logic
    assign cpu_ready_out = (state_reg == IDLE) && is_hit;
    
        //FSM Output
    wire [3:0] victim_way_oh;
    reg [2:0] next_lru_bits;
    
    always @(*) begin
        //default
        mem_req_out = 1'b0;
        mem_addr_out = 32'd0;
        
        array_way_we_out    = 4'b0000;
        array_data_in_out   = 256'd0; 
        
        array_lru_we_out    = 1'b0; 
        array_lru_in_out    = next_lru_bits;
        
        case (state_reg)
            IDLE: begin
                if (is_hit && cpu_req_in) begin
                    array_lru_we_out = 1'b1;
                end
            end
        
            MISS_REQ_MEM: begin
                mem_req_out = 1'b1;
                mem_addr_out = {addr_tag, addr_index, 5'b00000};
            end
        
            MISS_WAIT_MEM: begin
            end
        
            MISS_REFILL: begin
                array_data_in_out = mem_data_in;
                array_way_we_out = victim_way_oh;
                array_lru_we_out = 1'b1;
            end
            
            default:;
        endcase
    end
    
        //LRU Update
    assign victim_way_oh[0] = (!array_lru_out_in[2] && !array_lru_out_in[1]); 
    assign victim_way_oh[1] = (!array_lru_out_in[2] &&  array_lru_out_in[1]); 
    assign victim_way_oh[2] = ( array_lru_out_in[2] && !array_lru_out_in[0]); 
    assign victim_way_oh[3] = ( array_lru_out_in[2] &&  array_lru_out_in[0]); 
    
    always @(*) begin
        //default
        next_lru_bits = array_lru_out_in;
        
        if (state_reg == IDLE) begin 
            if (hit_way_0)      next_lru_bits = {1'b1, 1'b1, array_lru_out_in[0]}; 
            else if (hit_way_1) next_lru_bits = {1'b1, 1'b0, array_lru_out_in[0]}; 
            else if (hit_way_2) next_lru_bits = {1'b0, array_lru_out_in[1], 1'b1}; 
            else if (hit_way_3) next_lru_bits = {1'b0, array_lru_out_in[1], 1'b0}; 
        end else if (state_reg == MISS_REFILL) begin 
            if (victim_way_oh[0])      next_lru_bits = {1'b1, 1'b1, array_lru_out_in[0]}; 
            else if (victim_way_oh[1]) next_lru_bits = {1'b1, 1'b0, array_lru_out_in[0]}; 
            else if (victim_way_oh[2]) next_lru_bits = {1'b0, array_lru_out_in[1], 1'b1};
            else if (victim_way_oh[3]) next_lru_bits = {1'b0, array_lru_out_in[1], 1'b0}; 
        end
    end
endmodule