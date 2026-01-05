`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2026 02:40:38 PM
// Design Name: 
// Module Name: tb_alu
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

module tb_alu();
    //signals
    reg [31:0] A, B;
    reg [3:0] ALU_control;
    wire [31:0] result;
    wire zero;
    
    //dem loi
    integer errors;
    integer i;
    
    //instantiate
    alu alu_dut (
        .A              (A),
        .B              (B),
        .ALU_control    (ALU_control),
        .result         (result),
        .zero           (zero)
    );
    
    //task verify
    task verify_alu;
        input [31:0] a_in, b_in;
        input [3:0] ctrl_in;
        
        reg [31:0] expected_result;
        reg expected_zero;
        
        begin
            A = a_in;
            B = b_in;
            ALU_control = ctrl_in;
            #10;
            
            //golden model
            case (ctrl_in)
                4'b0000: expected_result = A & B;
                4'b0001: expected_result = A | B;
                4'b0010: expected_result = A + B;
                4'b0011: expected_result = A ^ B;
                4'b0100: expected_result = B << A[4:0];
                4'b0101: expected_result = B >> A[4:0];
                4'b0110: expected_result = A - B;
                4'b0111: expected_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
                4'b1100: expected_result = ~(A | B);
                default: expected_result = 32'hxxxxxxxx;
            endcase
            
            expected_zero = (expected_result == 0);
            
            //checker
            if (result != expected_result) begin
                $display("[FAILED] Ctrl=%b | A=%h | B=%h | DUT=%h | GOLD=%h", 
                         ctrl_in, A, B, result, expected_result);
                errors = errors + 1;
            end
            
            if (zero != expected_zero) begin
                $display("[FAILED ZERO] Ctrl=%b | Result=%h | DUT_Zero=%b | GOLD_Zero=%b",
                         ctrl_in, result, zero, expected_zero);
                errors = errors + 1;
            end
        end 
    endtask
    
    initial begin
        errors = 0;
        $display("========================================");
        $display("STARTING RANDOMIZED ALU TEST");
        $display("========================================");

        //DIRECTED TESTS
        $display("Corner Cases");
        verify_alu(4'b0010, 32'hFFFFFFFF, 32'h00000001); 
        verify_alu(4'b0010, 32'd0, 32'd0);               
        verify_alu(4'b0111, -5, 5);                      

        //RANDOM TESTS ---
        $display("Random Cases");
        
        repeat(100) begin
            verify_alu(4'b0010, $random, $random);
        end

        repeat(100) begin
            verify_alu(4'b0110, $random, $random);
        end

        repeat(50) verify_alu(4'b0000, $random, $random);
        repeat(50) verify_alu(4'b0001, $random, $random);
        repeat(50) verify_alu(4'b0011, $random, $random);
        repeat(50) verify_alu(4'b1100, $random, $random);

        repeat(100) begin
            verify_alu(4'b0100, $random, $random); 
            verify_alu(4'b0101, $random, $random);
        end
        
        repeat(100) begin
            verify_alu(4'b0111, $random, $random);
        end

        $display("========================================");
        if (errors == 0)
            $display("SUCCESS: ALL TESTS PASSED!");
        else
            $display("FAILURE: FOUND %d ERRORS!", errors);
        $display("========================================");
        $finish;
    end
endmodule