`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 08:46:44 AM
// Design Name: 
// Module Name: DCACHE_CTRL
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


module dcache_ctrl(
    //SYSTEM INTERFACE
    input  wire          clk,
    input  wire          rst_n,

    //CPU INTERFACE
    input  wire          mem_read_in,   //load
    input  wire          mem_write_in,  //store
    input  wire [31:0]   addr_in,
    input  wire [31:0]   data_to_write_in,  //write data
    input  wire [3:0]    mem_byte_en_in,
    output reg           cache_ready_out,
    output reg  [31:0]   data_read_out,

    //SRAM ARRAY INTERFACE 
    output wire [4:0]    array_idx_out,    
      
    input  wire [21:0]   tag_out_0,
    input  wire [21:0]   tag_out_1,
    input  wire [21:0]   tag_out_2,
    input  wire [21:0]   tag_out_3,
    
    input  wire          valid_out_0,
    input  wire          valid_out_1,
    input  wire          valid_out_2,
    input  wire          valid_out_3,
    
    input  wire [255:0]  data_out_0,
    input  wire [255:0]  data_out_1,
    input  wire [255:0]  data_out_2,
    input  wire [255:0]  data_out_3,
    
    input  wire [2:0]    lru_out_in,
    output wire [21:0]   array_tag_in,
    output reg  [255:0]  array_data_in,
    output reg  [3:0]    array_way_we_out,   
    output reg  [2:0]    array_lru_in,
    output reg           array_lru_we_out,

    //WRITE BUFFER INTERFACE
    output reg           wb_req_out,
    output reg  [31:0]   wb_addr_out,
    output reg  [31:0]   wb_data_out,
    output reg  [3:0]    wb_byte_en_out,
    input  wire          wb_full_in,

    //BUS ARBITER INTERFACE 
    output reg           dcache_read_req_out,
    output reg  [31:0]   dcache_addr_out,
    input  wire          dcache_mem_ready_in,
    input  wire [255:0]  dcache_rdata_in
);

    //Tach cac bit trong addr
    wire [4:0] idx = addr_in[9:5];
    wire [4:0] offset = addr_in[4:0];
    wire [21:0] tag = addr_in[31:10];
    
    assign array_idx_out = idx;
    assign array_tag_in  = tag;

    //Hit logic
    wire hit_way_0;
    wire hit_way_1; 
    wire hit_way_2; 
    wire hit_way_3;
    
    assign hit_way_0 = (tag == tag_out_0) && valid_out_0;
    assign hit_way_1 = (tag == tag_out_1) && valid_out_1;
    assign hit_way_2 = (tag == tag_out_2) && valid_out_2;
    assign hit_way_3 = (tag == tag_out_3) && valid_out_3;
    
    wire is_hit; 
    wire [3:0] hit_way_oh; 
    
    assign is_hit = hit_way_0 | hit_way_1 | hit_way_2 | hit_way_3;
    assign hit_way_oh = {hit_way_3, hit_way_2, hit_way_1, hit_way_0};

    //Data selection
    wire [255:0] selected_data_line;
    assign selected_data_line = hit_way_0 ? data_out_0 :
                                hit_way_1 ? data_out_1 :
                                hit_way_2 ? data_out_2 :
                                hit_way_3 ? data_out_3 : 256'd0;

    reg [31:0] word_aligned_data;
    always @(*) begin
        case (offset[4:2])
            3'b000: word_aligned_data = selected_data_line[31:0];
            3'b001: word_aligned_data = selected_data_line[63:32];
            3'b010: word_aligned_data = selected_data_line[95:64];
            3'b011: word_aligned_data = selected_data_line[127:96];
            3'b100: word_aligned_data = selected_data_line[159:128];
            3'b101: word_aligned_data = selected_data_line[191:160];
            3'b110: word_aligned_data = selected_data_line[223:192];
            3'b111: word_aligned_data = selected_data_line[255:224];
        endcase
    end

    //Data write 
    //Luu y: ho tro byte access
    reg [255:0] write_data_line;
    always @(*) begin
        write_data_line = selected_data_line;
        
        case(offset[4:2])
            //Word 0 (Bit 0-31)
            3'b000: begin
                if (mem_byte_en_in[0]) write_data_line[7:0]   = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[15:8]  = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[23:16] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[31:24] = data_to_write_in[31:24];
            end

            //Word 1 (Bit 32-63)
            3'b001: begin
                if (mem_byte_en_in[0]) write_data_line[39:32] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[47:40] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[55:48] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[63:56] = data_to_write_in[31:24];
            end

            //Word 2 (Bit 64-95)
            3'b010: begin
                if (mem_byte_en_in[0]) write_data_line[71:64] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[79:72] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[87:80] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[95:88] = data_to_write_in[31:24];
            end

            //Word 3 (Bit 96-127)
            3'b011: begin
                if (mem_byte_en_in[0]) write_data_line[103:96]  = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[111:104] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[119:112] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[127:120] = data_to_write_in[31:24];
            end

            //Word 4 (Bit 128-159)
            3'b100: begin
                if (mem_byte_en_in[0]) write_data_line[135:128] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[143:136] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[151:144] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[159:152] = data_to_write_in[31:24];
            end

            //Word 5 (Bit 160-191)
            3'b101: begin
                if (mem_byte_en_in[0]) write_data_line[167:160] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[175:168] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[183:176] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[191:184] = data_to_write_in[31:24];
            end

            //Word 6 (Bit 192-223)
            3'b110: begin
                if (mem_byte_en_in[0]) write_data_line[199:192] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[207:200] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[215:208] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[223:216] = data_to_write_in[31:24];
            end

            //Word 7 (Bit 224-255)
            3'b111: begin
                if (mem_byte_en_in[0]) write_data_line[231:224] = data_to_write_in[7:0];
                if (mem_byte_en_in[1]) write_data_line[239:232] = data_to_write_in[15:8];
                if (mem_byte_en_in[2]) write_data_line[247:240] = data_to_write_in[23:16];
                if (mem_byte_en_in[3]) write_data_line[255:248] = data_to_write_in[31:24];
            end
        endcase
    end

    //FSM
    localparam [2:0] IDLE        = 3'b000;
    localparam [2:0] READ_REQ    = 3'b001;
    localparam [2:0] READ_REFILL = 3'b010; 
    localparam [2:0] WRITE_BUF   = 3'b011;

    reg [2:0] state_reg, next_state;
    wire is_read_miss;
    wire is_stall_wb;
    
    assign is_read_miss = mem_read_in && !is_hit;       //cung se stall nhung do read miss 
    assign is_stall_wb  = wb_full_in && mem_write_in;   //stall khi write buffer day va can write

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state_reg <= IDLE;
        else        
            state_reg <= next_state;
    end

    always @(*) begin
        next_state = state_reg;
        
        case (state_reg)
            IDLE: begin
                if (is_stall_wb)      
                    next_state = IDLE; 
                else if (is_read_miss) 
                    next_state = READ_REQ;
                else if (mem_write_in) 
                    next_state = WRITE_BUF;
                else                  
                    next_state = IDLE;
            end
            
            READ_REQ: begin
                if (dcache_mem_ready_in) 
                    next_state = READ_REFILL;
                else                     
                    next_state = READ_REQ;
            end

            READ_REFILL: begin
                next_state = IDLE; 
            end

            WRITE_BUF: begin
                next_state = IDLE; 
            end
            
            default: next_state = IDLE;
        endcase
    end

    //LRU logic
    wire [3:0] victim_way_oh;
    assign victim_way_oh[0] = (!lru_out_in[2] && !lru_out_in[1]); 
    assign victim_way_oh[1] = (!lru_out_in[2] &&  lru_out_in[1]);
    assign victim_way_oh[2] = ( lru_out_in[2] && !lru_out_in[0]);
    assign victim_way_oh[3] = ( lru_out_in[2] &&  lru_out_in[0]);

    reg [2:0] next_lru_bits;
    always @(*) begin
        next_lru_bits = lru_out_in;
        
        if ((state_reg == IDLE && mem_read_in && is_hit) || (state_reg == WRITE_BUF && is_hit)) begin
            if (hit_way_0)      
                next_lru_bits = {1'b1, 1'b1, lru_out_in[0]};
            else if (hit_way_1) 
                next_lru_bits = {1'b1, 1'b0, lru_out_in[0]};
            else if (hit_way_2) 
                next_lru_bits = {1'b0, lru_out_in[1], 1'b1};
            else if (hit_way_3) 
                next_lru_bits = {1'b0, lru_out_in[1], 1'b0};
        end
        else if (state_reg == READ_REFILL) begin
            if (victim_way_oh[0])      
                next_lru_bits = {1'b1, 1'b1, lru_out_in[0]};
            else if (victim_way_oh[1]) 
                next_lru_bits = {1'b1, 1'b0, lru_out_in[0]};
            else if (victim_way_oh[2]) 
                next_lru_bits = {1'b0, lru_out_in[1], 1'b1};
            else if (victim_way_oh[3]) 
                next_lru_bits = {1'b0, lru_out_in[1], 1'b0};
        end
    end

    //Outputs
    always @(*) begin
        cache_ready_out     = 1'b0;
        data_read_out       = word_aligned_data;
        array_data_in       = 256'd0;
        array_way_we_out    = 4'b0000;
        array_lru_in        = next_lru_bits;
        array_lru_we_out    = 1'b0;
        
        wb_req_out          = 1'b0;
        wb_addr_out         = addr_in;
        wb_data_out         = data_to_write_in;
        wb_byte_en_out      = mem_byte_en_in;
        
        dcache_read_req_out = 1'b0;
        dcache_addr_out     = {tag, idx, 5'b00000}; 

        case (state_reg)
            IDLE: begin
                if (is_stall_wb)      
                    cache_ready_out = 1'b0;
                else if (is_read_miss) 
                    cache_ready_out = 1'b0;
                else begin 
                    cache_ready_out = 1'b1; 
                    if (mem_read_in && is_hit) 
                        array_lru_we_out = 1'b1;
                end
            end
            
            READ_REQ: begin
                dcache_read_req_out = 1'b1;
                
                if (dcache_mem_ready_in) begin
                    array_data_in    = dcache_rdata_in;
                    array_way_we_out = victim_way_oh;
                    array_lru_we_out = 1'b1;
                end
            end
            
            READ_REFILL: begin
            end
            
            WRITE_BUF: begin
                cache_ready_out = 1'b1;
                wb_req_out      = 1'b1;
                
                if (is_hit) begin
                    array_data_in    = write_data_line;
                    array_way_we_out = hit_way_oh; 
                    array_lru_we_out = 1'b1;
                end
            end
        endcase
    end
endmodule
