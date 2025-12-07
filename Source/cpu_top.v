`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2025 10:29:11 AM
// Design Name: 
// Module Name: cpu_top
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


module cpu_top(
    input wire          clk,
    input wire          rst_n,

    // --- EXTERNAL MEMORY INTERFACE (To Main Memory/Testbench) ---
    input wire [255:0]  mem_rdata_in,   // Dữ liệu đọc từ RAM (Block 256-bit)
    input wire          mem_wait_in,    // RAM báo bận (Latency simulation)
    
    output wire         mem_req_out,    // Yêu cầu truy cập RAM
    output wire         mem_we_out,     // Write Enable
    output wire [31:0]  mem_addr_out,   // Địa chỉ RAM
    output wire [31:0]  mem_wdata_out,  // Dữ liệu ghi (32-bit)
    output wire [3:0]   mem_be_out      // Byte Enable
);

    // ======================================================================
    // 1. INTERNAL WIRES DECLARATION
    // ======================================================================

    // --- BPU Signals (NEW) ---
    wire        bpu_pred_taken;      // Output của BPU -> Input của IF
    wire [31:0] bpu_pred_target;     // Output của BPU -> Input của IF

    // --- IF Stage Signals ---
    wire [31:0] if_pc_current;
    wire [31:0] if_pc_plus4;
    wire        if_cache_ready;      // I-Cache Ready
    
    // --- IF Pass-through Signals (NEW) ---
    wire [31:0] if_instr_pass;       // Lệnh đi xuyên qua IF (Cache -> IF -> Bus)
    wire        if_pred_taken_pass;  // Dự đoán đi xuyên qua IF (BPU -> IF -> Bus)

    // --- I-CACHE Signals ---
    wire [31:0] icache_data_out;     // Instruction fetched (Raw output form Cache)
    wire        icache_bus_req;
    wire [31:0] icache_bus_addr;
    wire        icache_bus_ready;    // Arbiter -> ICache
    wire [255:0] icache_bus_data;    // Arbiter -> ICache

    // --- BUS IF/ID Signals ---
    wire [31:0] if_id_instr;
    wire [31:0] if_id_pc_plus4;
    wire        if_id_pred_taken;

    // --- HDU Control Signals ---
    wire        hdu_pc_write_en;
    wire        hdu_if_id_write_en;
    wire        hdu_if_id_flush_en;
    wire        hdu_id_ex_write_en;
    wire        hdu_id_ex_flush_en;
    wire        hdu_ex_mem_write_en;
    wire        hdu_ex_mem_flush_en;
    wire        hdu_mem_wb_write_en;
    wire        hdu_pc_redirect;
    wire [31:0] hdu_pc_redirect_addr;
    
    // --- ID Stage Signals ---
    wire [31:0] id_reg_data1;
    wire [31:0] id_reg_data2;
    wire [31:0] id_imm_ext;
    wire [4:0]  id_rs, id_rt, id_rd, id_shamt;
    // Control Signals from ID
    wire        ctrl_reg_dst, ctrl_alu_src, ctrl_mem_to_reg, ctrl_reg_write;
    wire        ctrl_mem_read, ctrl_mem_write, ctrl_branch, ctrl_jump;
    wire        ctrl_use_shamt;
    wire [3:0]  ctrl_alu_control;
    
    // Calculated Jump Target (Glue Logic)
    wire [31:0] id_jump_target_calc;
    assign id_jump_target_calc = {if_id_pc_plus4[31:28], if_id_instr[25:0], 2'b00};

    // --- BUS ID/EX Signals ---
    wire [31:0] id_ex_reg_data1, id_ex_reg_data2, id_ex_imm, id_ex_pc_plus4;
    wire        id_ex_pred_taken;
    wire [4:0]  id_ex_rs, id_ex_rt, id_ex_rd, id_ex_shamt;
    // Control Signals at ID/EX
    wire        id_ex_reg_dst, id_ex_alu_src, id_ex_mem_to_reg, id_ex_reg_write;
    wire        id_ex_mem_read, id_ex_mem_write, id_ex_branch, id_ex_jump, id_ex_use_shamt;
    wire [3:0]  id_ex_alu_control;

    // --- FU Signals ---
    wire [1:0]  fwd_a;
    wire [1:0]  fwd_b;

    // --- EX Stage Signals ---
    wire [31:0] ex_alu_result;
    wire [31:0] ex_branch_target;
    wire        ex_zero_flag;
    wire [31:0] ex_reg_data2_fwd; // Data to store (after forwarding)
    wire [4:0]  ex_rd_final;
    wire        ex_branch_out_sig; // Branch control signal passed through EX
    
    // Branch Taken Logic (Glue Logic)
    // Mặc định hỗ trợ BEQ: Taken = Branch_En AND Zero_Flag
    wire        ex_branch_taken_actual;
    assign ex_branch_taken_actual = ex_branch_out_sig && ex_zero_flag;

    // --- BUS EX/MEM Signals ---
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_branch_target;
    wire [31:0] ex_mem_reg_data2;
    wire [4:0]  ex_mem_rd;
    wire        ex_mem_zero;
    wire        ex_mem_mem_to_reg, ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_branch;

    // --- MEM Stage & D-CACHE Signals ---
    wire [31:0] mem_data_out; // Data read from Cache
    wire [31:0] mem_alu_result_pass;
    wire [4:0]  mem_dest_reg_pass;
    wire        mem_to_reg_pass, mem_reg_write_pass;
    wire        mem_stall_req; // Cache Miss Stall

    // D-Cache <-> Bus Interface
    wire        dcache_bus_read_req;
    wire [31:0] dcache_bus_addr;
    wire        dcache_bus_ready; // Arbiter -> DCache
    wire [255:0] dcache_bus_data; // Arbiter -> DCache
    
    // Write Buffer Interface
    wire        wb_empty_sig;
    wire [67:0] wb_data_to_arb;
    wire        wb_pop_en;

    // D-Cache Internal Interface (Between MEM and DCACHE module)
    wire        mem_to_cache_read_en;
    wire        mem_to_cache_write_en;
    wire [3:0]  mem_to_cache_byte_en;
    wire [31:0] mem_to_cache_addr;
    wire [31:0] mem_to_cache_wdata;
    wire [31:0] cache_to_mem_rdata;
    wire        cache_to_mem_ready;

    // --- BUS MEM/WB Signals ---
    wire [31:0] mem_wb_mem_data;
    wire [31:0] mem_wb_alu_result;
    wire [4:0]  mem_wb_dest_reg;
    wire        mem_wb_mem_to_reg;
    wire        mem_wb_reg_write;

    // --- WB Stage Signals ---
    wire [31:0] wb_final_data;
    wire [4:0]  wb_final_addr;
    wire        wb_final_write_en;


    // ======================================================================
    // 2. MODULE INSTANTIATIONS
    // ======================================================================

    // ------------------------- BPU (NEW) -------------------------
    (* dont_touch = "true" *)
    BPU branch_predictor (
        .clk                    (clk),
        .rst_n                  (rst_n),
        
        // Read Port (IF Stage)
        .pc_current_in          (if_pc_current),    // PC đang chạy ở IF
        .pred_taken_out         (bpu_pred_taken),   // Dự đoán: Có nhảy không?
        .pred_target_out        (bpu_pred_target),  // Đích đến là đâu?
        
        // Update Port (EX Stage) - Học từ kết quả thực tế
        .update_en_in           (ex_branch_out_sig),      // Chỉ update khi lệnh ở EX là Branch
        .branch_pc_in           (id_ex_pc_plus4 - 32'd4), // Tính lại PC gốc của lệnh Branch đang ở EX
        .branch_actual_taken_in (ex_branch_taken_actual), // Kết quả thực tế (từ ALU)
        .branch_target_in       (ex_branch_target)        // Địa chỉ đích thực tế (từ ALU)
    );

    // ------------------------- IF STAGE -------------------------
    (* dont_touch = "true" *)
    IF if_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        // Inputs from HDU
        .pc_write_en        (hdu_pc_write_en),
        .pc_redirect        (hdu_pc_redirect),
        .pc_redirect_addr   (hdu_pc_redirect_addr),
        // Inputs from BPU
        .predicted_addr     (bpu_pred_target), 
        .predicted_taken    (bpu_pred_taken),  
        // Inputs from Cache & Others
        .cache_ready        (if_cache_ready),
        .instr_in           (icache_data_out),
        
        // Outputs
        .pc_current_out     (if_pc_current),
        .pc_plus4_out       (if_pc_plus4),
        
        // Pass-through Outputs
        .instr_out          (if_instr_pass),        // Pass ra dây trung gian
        .predicted_taken_out(if_pred_taken_pass)    // Pass ra dây trung gian
    );
    
    (* dont_touch = "true" *)
    ICACHE icache_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .cpu_addr_in        (if_pc_current),
        .cpu_req_in         (1'b1), // Luôn fetch lệnh
        .cpu_data_out       (icache_data_out), // Đi vào IF để pass
        .cpu_ready_out      (if_cache_ready),
        
        // Bus Interface
        .mem_req_out        (icache_bus_req),
        .mem_addr_out       (icache_bus_addr),
        .mem_data_in        (icache_bus_data),
        .mem_ready_in       (icache_bus_ready)
    );

    // ------------------------- IF/ID BUS -------------------------
    (* dont_touch = "true" *)
    BUS_IF_ID bus_if_id (
        .clk                (clk),
        .rst_n              (rst_n),
        .if_id_write_en     (hdu_if_id_write_en),
        .if_id_flush_en     (hdu_if_id_flush_en),
        
        // Inputs (Lấy từ dây pass-through của IF)
        .instr_in           (if_instr_pass),
        .pc_plus4_in        (if_pc_plus4),
        .predicted_taken_in (if_pred_taken_pass), 
        
        // Outputs
        .if_id_instr_out    (if_id_instr),
        .if_id_pc_plus4_out (if_id_pc_plus4),
        .if_id_pred_taken_out(if_id_pred_taken)
    );

    // ------------------------- HDU (HAZARD DETECTION) -------------------------
    (* dont_touch = "true" *)
    HDU hazard_unit (
        // Inputs
        .if_id_rs           (id_rs), 
        .if_id_rt           (id_rt),
        .id_ex_rt           (id_ex_rt),
        .id_ex_mem_read     (id_ex_mem_read),
        .id_jump            (ctrl_jump),
        .id_jump_target     (id_jump_target_calc),
        .ex_branch_taken    (ex_branch_taken_actual),
        .id_ex_pred_taken   (id_ex_pred_taken),
        .ex_branch_target   (ex_branch_target),
        .ex_pc_plus4        (id_ex_pc_plus4),
        .mem_stall_req      (mem_stall_req),

        // Outputs
        .pc_write_en        (hdu_pc_write_en),
        .if_id_write_en     (hdu_if_id_write_en),
        .if_id_flush_en     (hdu_if_id_flush_en),
        .id_ex_write_en     (hdu_id_ex_write_en),
        .id_ex_flush_en     (hdu_id_ex_flush_en),
        .ex_mem_write_en    (hdu_ex_mem_write_en),
        .ex_mem_flush_en    (hdu_ex_mem_flush_en),
        .mem_wb_write_en    (hdu_mem_wb_write_en),
        .pc_redirect        (hdu_pc_redirect),
        .pc_redirect_addr   (hdu_pc_redirect_addr)
    );

    // ------------------------- ID STAGE -------------------------
    (* dont_touch = "true" *)
    ID id_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .instr_in           (if_id_instr),
        // Write Back Input
        .wb_reg_write_en    (wb_final_write_en),
        .wb_write_addr      (wb_final_addr),
        .wb_write_data      (wb_final_data),
        // Outputs
        .id_reg_data1       (id_reg_data1),
        .id_reg_data2       (id_reg_data2),
        .id_sign_ext_imm    (id_imm_ext),
        .id_rs_addr         (id_rs),
        .id_rt_addr         (id_rt),
        .id_rd_addr         (id_rd),
        .id_shamt           (id_shamt),
        // Control Signals
        .reg_dst(ctrl_reg_dst), .ALU_src(ctrl_alu_src), .mem_to_reg(ctrl_mem_to_reg), 
        .reg_write(ctrl_reg_write), .mem_read(ctrl_mem_read), .mem_write(ctrl_mem_write), 
        .branch(ctrl_branch), .jump(ctrl_jump), .use_shamt(ctrl_use_shamt), 
        .alu_control(ctrl_alu_control)
    );

    // ------------------------- ID/EX BUS -------------------------
    (* dont_touch = "true" *)
    BUS_ID_EX bus_id_ex (
        .clk(clk), .rst_n(rst_n),
        .id_ex_write_en(hdu_id_ex_write_en),
        .id_ex_flush_en(hdu_id_ex_flush_en),
        
        .reg_data1_in(id_reg_data1), .reg_data2_in(id_reg_data2), .imm_in(id_imm_ext),
        .pc_plus4_in(if_id_pc_plus4), .pred_taken_in(if_id_pred_taken),
        .rs_addr_in(id_rs), .rt_addr_in(id_rt), .rd_addr_in(id_rd), .shamt_in(id_shamt),
        
        .reg_dst_in(ctrl_reg_dst), .ALU_src_in(ctrl_alu_src), .mem_to_reg_in(ctrl_mem_to_reg),
        .reg_write_in(ctrl_reg_write), .mem_read_in(ctrl_mem_read), .mem_write_in(ctrl_mem_write),
        .branch_in(ctrl_branch), .jump_in(ctrl_jump), .use_shamt_in(ctrl_use_shamt), .alu_control_in(ctrl_alu_control),
        
        // Outputs
        .reg_data1_out(id_ex_reg_data1), .reg_data2_out(id_ex_reg_data2), .imm_out(id_ex_imm),
        .pc_plus4_out(id_ex_pc_plus4), .pred_taken_out(id_ex_pred_taken),
        .rs_addr_out(id_ex_rs), .rt_addr_out(id_ex_rt), .rd_addr_out(id_ex_rd), .shamt_out(id_ex_shamt),
        
        .reg_dst_out(id_ex_reg_dst), .ALU_src_out(id_ex_alu_src), .mem_to_reg_out(id_ex_mem_to_reg),
        .reg_write_out(id_ex_reg_write), .mem_read_out(id_ex_mem_read), .mem_write_out(id_ex_mem_write),
        .branch_out(id_ex_branch), .jump_out(id_ex_jump), .use_shamt_out(id_ex_use_shamt), .alu_control_out(id_ex_alu_control)
    );

    // ------------------------- FU (FORWARDING UNIT) -------------------------
    (* dont_touch = "true" *)
    FU forwarding_unit (
        .EX_rs              (id_ex_rs),
        .EX_rt              (id_ex_rt),
        .MEM_dest_reg       (ex_mem_rd),
        .MEM_reg_write      (ex_mem_reg_write),
        .WB_dest_reg        (mem_wb_dest_reg),
        .WB_reg_write       (mem_wb_reg_write),
        .forwardA           (fwd_a),
        .forwardB           (fwd_b)
    );

    // ------------------------- EX STAGE -------------------------
    (* dont_touch = "true" *)
    EX ex_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .reg_data1_in       (id_ex_reg_data1),
        .reg_data2_in       (id_ex_reg_data2),
        .imm_in             (id_ex_imm),
        .pc_plus4_in        (id_ex_pc_plus4),
        .rs_addr_in         (id_ex_rs),
        .rt_addr_in         (id_ex_rt),
        .rd_addr_in         (id_ex_rd),
        .shamt_in           (id_ex_shamt),
        .reg_dst_in         (id_ex_reg_dst),
        .ALU_src_in         (id_ex_alu_src),
        .mem_to_reg_in      (id_ex_mem_to_reg),
        .reg_write_in       (id_ex_reg_write),
        .mem_read_in        (id_ex_mem_read),
        .mem_write_in       (id_ex_mem_write),
        .branch_in          (id_ex_branch),
        .jump_in            (id_ex_jump),
        .use_shamt_in       (id_ex_use_shamt),
        .alu_control_in     (id_ex_alu_control),
        .forwardA           (fwd_a),
        .forwardB           (fwd_b),
        // Forwarding Inputs
        .ex_mem_result_in   (ex_mem_alu_result), 
        .mem_wb_result_in   (wb_final_data),     
        
        // Outputs
        .alu_result_out     (ex_alu_result),
        .branch_target_out  (ex_branch_target),
        .zero_flag_out      (ex_zero_flag),
        .reg_data2_fwd_out  (ex_reg_data2_fwd),
        .rd_addr_final_out  (ex_rd_final),
        
        // Pass-through Connections (Unused because of bypass)
        .mem_to_reg_out     (), 
        .reg_write_out      (),
        .mem_read_out       (),
        .mem_write_out      (),
        .branch_out         (ex_branch_out_sig)
    );

    // ------------------------- EX/MEM BUS -------------------------
    (* dont_touch = "true" *)
    BUS_EX_MEM bus_ex_mem (
        .clk(clk), .rst_n(rst_n),
        .ex_mem_write_en    (hdu_ex_mem_write_en),
        .ex_mem_flush_en    (hdu_ex_mem_flush_en),
        
        .alu_result_in      (ex_alu_result),
        .branch_target_in   (ex_branch_target),
        .zero_flag_in       (ex_zero_flag),
        .reg_data2_fwd_in   (ex_reg_data2_fwd),
        .rd_addr_final_in   (ex_rd_final),
        
        // Control Signals inputs (Bypass from ID/EX)
        .mem_to_reg_in      (id_ex_mem_to_reg), 
        .reg_write_in       (id_ex_reg_write),
        .mem_read_in        (id_ex_mem_read),
        .mem_write_in       (id_ex_mem_write),
        .branch_in          (id_ex_branch),

        // Outputs
        .alu_result_out     (ex_mem_alu_result),
        .branch_target_out  (ex_mem_branch_target),
        .reg_data2_fwd_out  (ex_mem_reg_data2),
        .rd_addr_final_out  (ex_mem_rd),
        .zero_flag_out      (ex_mem_zero),
        .mem_to_reg_out     (ex_mem_mem_to_reg),
        .reg_write_out      (ex_mem_reg_write),
        .mem_read_out       (ex_mem_mem_read),
        .mem_write_out      (ex_mem_mem_write),
        .branch_out         (ex_mem_branch)
    );

    // ------------------------- MEM STAGE -------------------------
    (* dont_touch = "true" *)
    MEM mem_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .alu_result_in      (ex_mem_alu_result),
        .reg_data2_in       (ex_mem_reg_data2),
        .dest_reg_in        (ex_mem_rd),
        .mem_read_in        (ex_mem_mem_read),
        .mem_write_in       (ex_mem_mem_write),
        .mem_to_reg_in      (ex_mem_mem_to_reg),
        .reg_write_in       (ex_mem_reg_write),
        
        // D-Cache Interface
        .dcache_en_read_out (mem_to_cache_read_en),
        .dcache_en_write_out(mem_to_cache_write_en),
        .dcache_byte_en_out (mem_to_cache_byte_en),
        .dcache_addr_out    (mem_to_cache_addr),
        .dcache_wdata_out   (mem_to_cache_wdata),
        .dcache_rdata_in    (cache_to_mem_rdata),
        .dcache_ready_in    (cache_to_mem_ready),
        
        // Outputs to WB
        .mem_data_out       (mem_data_out), 
        .alu_result_out     (mem_alu_result_pass),
        .dest_reg_out       (mem_dest_reg_pass),
        .mem_to_reg_out     (mem_to_reg_pass),
        .reg_write_out      (mem_reg_write_pass),
        
        // Hazard Output
        .mem_stall_out      (mem_stall_req)
    );

    // ------------------------- D-CACHE -------------------------
    (* dont_touch = "true" *)
    DCACHE dcache_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // CPU Interface (from MEM Stage)
        .mem_read_in        (mem_to_cache_read_en),
        .mem_write_in       (mem_to_cache_write_en),
        .mem_byte_en_in     (mem_to_cache_byte_en),
        .mem_addr_in        (mem_to_cache_addr),
        .mem_wdata_in       (mem_to_cache_wdata),
        .mem_rdata_out      (cache_to_mem_rdata),
        .mem_ready_out      (cache_to_mem_ready),
        
        // Bus Interface
        .dcache_req_out     (dcache_bus_read_req),
        .dcache_addr_out    (dcache_bus_addr),
        .arb_ready_in       (dcache_bus_ready),
        .mem_data_in        (dcache_bus_data),
        
        // Write Buffer Interface
        .wb_empty_out       (wb_empty_sig),
        .wb_data_to_arb_out (wb_data_to_arb),
        .wb_pop_en_in       (wb_pop_en)
    );

    // ------------------------- MEM/WB BUS -------------------------
    (* dont_touch = "true" *)
    BUS_MEM_WB bus_mem_wb (
        .clk(clk), .rst_n(rst_n),
        .mem_wb_write_en    (hdu_mem_wb_write_en),
        .mem_wb_flush_en    (1'b0), // No flush at WB
        
        .mem_data_in        (mem_data_out),
        .alu_result_in      (mem_alu_result_pass),
        .dest_reg_in        (mem_dest_reg_pass),
        .mem_to_reg_in      (mem_to_reg_pass),
        .reg_write_in       (mem_reg_write_pass),
        
        // Outputs
        .mem_data_out       (mem_wb_mem_data),
        .alu_result_out     (mem_wb_alu_result),
        .dest_reg_out       (mem_wb_dest_reg),
        .mem_to_reg_out     (mem_wb_mem_to_reg),
        .reg_write_out      (mem_wb_reg_write)
    );

    // ------------------------- WB STAGE -------------------------
    (* dont_touch = "true" *)
    WB wb_stage (
        .mem_data_in        (mem_wb_mem_data),
        .alu_result_in      (mem_wb_alu_result),
        .dest_reg_in        (mem_wb_dest_reg),
        .mem_to_reg_in      (mem_wb_mem_to_reg),
        .reg_write_in       (mem_wb_reg_write),
        
        // Outputs
        .wb_write_data_out  (wb_final_data),
        .wb_write_addr_out  (wb_final_addr),
        .wb_reg_write_out   (wb_final_write_en)
    );

    // ------------------------- BUS ARBITER -------------------------
    (* dont_touch = "true" *)
    BUS_ARBITER bus_arbiter (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // I-Cache Interface
        .icache_req_in      (icache_bus_req),
        .icache_addr_in     (icache_bus_addr),
        .icache_ready_out   (icache_bus_ready),
        .icache_data_out    (icache_bus_data),
        
        // D-Cache Interface
        .dcache_read_req_in (dcache_bus_read_req),
        .dcache_addr_in     (dcache_bus_addr),
        .dcache_mem_ready_out(dcache_bus_ready),
        .dcache_rdata_out   (dcache_bus_data),
        
        // Write Buffer Interface
        .wb_empty_in        (wb_empty_sig),
        .wb_data_in         (wb_data_to_arb),
        .wb_pop_en_out      (wb_pop_en),
        
        // Main Memory Interface (Connected to Top Ports)
        .mem_rdata_in       (mem_rdata_in),
        .mem_wait_in        (mem_wait_in),
        .mem_req_out        (mem_req_out),
        .mem_we_out         (mem_we_out),
        .mem_addr_out       (mem_addr_out),
        .mem_wdata_out      (mem_wdata_out),
        .mem_be_out         (mem_be_out)
    );

endmodule