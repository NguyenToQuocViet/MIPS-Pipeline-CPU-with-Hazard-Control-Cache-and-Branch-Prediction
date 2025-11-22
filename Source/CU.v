`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 04:22:21 PM
// Design Name: 
// Module Name: CU
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


module control_unit(opcode, funct, reg_dst, ALU_src, mem_to_reg, reg_write, mem_read, mem_write, branch, jump, use_shamt, alu_control);
    //INPUTS
    input wire [5:0] opcode, funct;
    
    //OUTPUTS
    output reg reg_dst, ALU_src;
    output reg mem_to_reg, reg_write;
    output reg mem_read, mem_write;
    output reg branch, jump;
    output reg use_shamt;
    
    output reg [3:0] alu_control;
    
    //Logic
    always @(*) begin
        //default
        reg_dst      = 1'b0;
        ALU_src      = 1'b0;
        mem_to_reg   = 1'b0;
        reg_write    = 1'b0;
        mem_read     = 1'b0;
        mem_write    = 1'b0;
        branch       = 1'b0;
        jump         = 1'b0;
        use_shamt    = 1'b0;
        alu_control  = 4'b0000;
        
        case (opcode)
            6'b000000: begin    //R-Type
                reg_dst     = 1'b1;     //ghi vao rd
                ALU_src     = 1'b0;     //dung 2 thanh ghi
                reg_write   = 1'b1;     //cho phep write
                
                //giai ma funct
                case (funct) 
                    6'b100000: alu_control = 4'b0010; // add
                    6'b100010: alu_control = 4'b0110; // sub
                    6'b100100: alu_control = 4'b0000; // and
                    6'b100101: alu_control = 4'b0001; // or
                    6'b100110: alu_control = 4'b0011; // xor
                    6'b100111: alu_control = 4'b1100; // nor
                    6'b101010: alu_control = 4'b0111; // slt
                    6'b000000: begin                  // sll
                        use_shamt   = 1'b1;
                        alu_control = 4'b0100; 
                    end
                    6'b000010: begin
                        use_shamt   = 1'b1;
                        alu_control = 4'b0101;         // srl
                    end
                    
                    default:   alu_control = 4'bxxxx; // an toan
                endcase
            end
        
        6'b100011: begin    //load word
            reg_dst     = 1'b0;     //ghi vao rt
            ALU_src     = 1'b1;     //dung 1 thanh ghi + imm
            mem_to_reg  = 1'b1;     //luu mem
            reg_write   = 1'b1;     //cho phep ghi
            mem_read    = 1'b1;     //doc d-cache
            alu_control = 4'b0010;  //rs + imm
        end
        
        6'b101011: begin    //store word
            ALU_src     = 1'b1;     //dung 1 thanh ghi + imm
            mem_write   = 1'b1;     //ghi d-cache
            alu_control = 4'b0010;  //rs + imm
        end
        
        6'b000100: begin    //branch equal
            ALU_src     = 1'b0;     //dung 2 thanh ghi
            branch      = 1'b1;     //lenh re nhanh
            alu_control = 4'b0110;  //reg1 - reg2
        end
        
        6'b000010: begin    //jump
            jump        = 1'b1;     //lenh nhay
        end
        
        6'b001000: begin    //addi
            reg_dst     = 1'b0;     //ghi vao rt
            ALU_src     = 1'b1;     //dung 1 thanh ghi + imm
            mem_to_reg  = 1'b0;     //ghi data
            reg_write   = 1'b1;     //cho phep ghi
            alu_control = 4'b0010;  //reg1 + imm
        end
        
        default: begin
        end
        
        endcase 
    end
endmodule
