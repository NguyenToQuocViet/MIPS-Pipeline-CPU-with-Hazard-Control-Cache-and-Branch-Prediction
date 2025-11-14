# MIPS Pipeline CPU with Hazard Control, Cache, and Branch Prediction

## 1. Overview
This project implements a complete **MIPS 32-bit pipelined CPU**, including all core components of a modern in-order processor:
- 5-stage pipeline (IF–ID–EX–MEM–WB)
- Hazard control (forwarding, stall, pipeline flush)
- 4KB Instruction Memory + 4KB Data Memory with 8-cycle latency
- Instruction Cache & Data Cache (multi-way associative with PLRU replacement)
- Dynamic Branch Prediction (BTB + BHT 2-bit saturating counter)

The CPU supports a full subset of MIPS integer instructions (R/I/J types), handles load-use hazards and memory/cache delays, predicts branch behavior, and performs write-back to the register file.

---

## 2. Feature List

### 2.1 Pipeline Architecture
- 5 stages: **IF, ID, EX, MEM, WB**
- Pipeline registers: **IF/ID, ID/EX, EX/MEM, MEM/WB**
- Full control-signal propagation across stages
- Instruction size: 32 bits
- PC: 12-bit, default reset value = `0x000`

### 2.2 Supported Instructions
**R-type:** `add, addu, sub, subu, and, or, xor, nor, slt, sltu, sll, srl, sra, jr`  
**I-type:** `lw, lh, lhu, lb, lbu, sw, sh, sb, addi, addiu, andi, ori, xori, slti, sltiu, lui, beq, bne`  
**J-type:** `j, jal`  
**Syscall:** used to terminate program execution.

---

## 3. Memory Subsystem

### 3.1 Instruction Memory
- Capacity: 4KB (1024 words × 32-bit)
- Read-only
- Latency: **8 cycles**
- Synchronous read with `mem_read_req` and `mem_read_valid` handshake
- Addressing: byte address mapped to word index

### 3.2 Data Memory
- Capacity: 4KB (1024 words × 32-bit)
- Read/Write
- Same 8-cycle latency as instruction memory
- Supports byte / half-word / word access
- Stack and data share the same memory space
- Default stack pointer `$sp = 4096`

---

## 4. Cache System

### 4.1 Instruction Cache (I-Cache)
- Capacity: 256B
- Block size: 8B (2 instructions)
- 2-way set associative: 16 sets, 32 blocks
- Address format:
  - Tag: 5 bits
  - Index: 4 bits
  - Word offset: 1 bit
- Replacement: PLRU (1 bit per set)
- States: `IDLE`, `MEM_READ`
- Behavior:
  - **Hit:** 1 cycle, read instruction from cache
  - **Miss:** go to `MEM_READ`, send read to Instruction Memory, wait 8 cycles, fill 1 block (2 instructions), then return to `IDLE`
  - Total miss penalty ≈ 9 cycles (1 control + 8 memory)

### 4.2 Data Cache (D-Cache)
- Capacity: 256B
- Block size: 4B (1 word)
- 4-way set associative: 16 sets, 64 blocks
- Address format:
  - Tag: 6 bits (`addr[11:6]`)
  - Index: 4 bits (`addr[5:2]`)
  - Byte offset: 2 bits (`addr[1:0]`)
- Each line: `{valid, dirty, tag, data[31:0]}`
- Replacement: 4-way PLRU (3 bits/set)
- Write policy: Write-back + Write-allocate
- States: `IDLE`, `MEM_READ`, `MEM_WRITE_BACK`

#### 4.2.1 Read Path
- In `IDLE`:
  - On `cpu_read_req`: decode address, read set, compare tags across 4 ways
  - If **hit**:
    - Extract byte/half/word using `byte offset` and `mem_size`
    - Apply sign-extend or zero-extend according to `mem_unsigned`
    - Return data in 1 cycle, `dcache_hit = 1`, `dcache_stall = 0`
    - Update PLRU state
  - If **miss**:
    - Select victim via PLRU
    - If victim `dirty = 1` → go to `MEM_WRITE_BACK`
    - Else → go to `MEM_READ`
    - Set `dcache_stall = 1`

- In `MEM_READ`:
  - Issue `mem_read_req` to Data Memory
  - Wait for `mem_read_valid` (8-cycle latency)
  - Fill victim line (update `valid`, `tag`, `data`, `dirty = 0`)
  - Extract and return the required data to CPU
  - Clear stall and go back to `IDLE`

#### 4.2.2 Write Path
- In `IDLE`:
  - On `cpu_write_req`: decode address, check tags
  - If **write hit**:
    - Update the correct bytes/half/word in the cache line
    - Set `dirty = 1`, update PLRU
    - `dcache_hit = 1`, `dcache_stall = 0` (1 cycle)
  - If **write miss**:
    - Select victim via PLRU
    - If victim is **clean** (`dirty = 0`):
      - Perform fast write-allocate: treat as new line
      - Set `valid = 1`, new `tag`, `dirty = 1`
      - Write CPU data directly into the cache line
      - Typically 1 cycle (no memory access on miss)
    - If victim is **dirty**:
      - Go to `MEM_WRITE_BACK`, `dcache_stall = 1`

- In `MEM_WRITE_BACK`:
  - Send victim block to Data Memory with `mem_write_req`
  - Wait for `mem_write_back_valid` (≈ 8 cycles)
  - Clear `dirty` bit of victim
  - Return to `IDLE` and immediately perform write-allocate as above
  - Clear stall after complete replacement and write

#### 4.2.3 Latency Summary (assuming memory latency = 8 cycles)
- Read:
  - Hit: 1 cycle
  - Miss, victim clean: ≈ 9 cycles
  - Miss, victim dirty: ≈ 18 cycles
- Write:
  - Hit: 1 cycle
  - Miss, victim clean: ≈ 1 cycle (fast write-allocate)
  - Miss, victim dirty: ≈ 9 cycles (write-back + CPU write)

---

## 5. Branch Prediction Unit (BPU)

### 5.1 Structures
- **Branch Target Buffer (BTB):**
  - 32 entries
  - Fields per entry: `{valid, tag[4:0], target[9:0]}`
- **Branch History Table (BHT):**
  - 16 entries
  - Index: `PC[5:2]`
  - 2-bit saturating counter per entry

### 5.2 Prediction in IF Stage
- For a given PC:
  - Lookup BTB by index
  - If BTB **miss** → default next PC = `PC + 4`
  - If BTB **hit**:
    - Use BHT state:
      - `2'b10` or `2'b11`: predict taken → next PC = BTB target
      - `2'b00` or `2'b01`: predict not taken → next PC = `PC + 4`

### 5.3 Update in MEM Stage
- After branch is resolved:
  - Detect actual taken/not-taken and whether instruction is a branch
  - If misprediction:
    - Flush pipeline
    - Redirect PC to correct target address
  - BTB update:
    - On BTB miss and branch is taken: allocate new entry
    - On BTB hit and branch is taken but predicted not taken: update target if needed
    - On BTB hit and instruction is not a branch: invalidate entry
  - BHT update:
    - For every branch:
      - If actually taken → saturating counter = min(counter + 1, `2'b11`)
      - If not taken → saturating counter = max(counter - 1, `2'b00`)

---

## 6. Hazard Control

### 6.1 Forwarding Unit
- EX stage forwarding:
  - For ALU operands, forward from:
    - EX/MEM stage result
    - MEM/WB stage result
- ID stage forwarding:
  - Forward WB stage data directly to register file read outputs to avoid read-after-write delay

### 6.2 Stall Logic
- Load-use hazard:
  - When an instruction in EX is a load and next instruction uses its result:
    - Insert 1 bubble between ID and EX
    - Hold PC and IF/ID
- Cache stall:
  - On I-cache or D-cache miss:
    - Stall appropriate pipeline stages until `valid` signal from memory/cache

### 6.3 Flush Logic
- On `j`, `jal`, `jr`:
  - Flush wrong-path instructions
- On branch misprediction (`beq`, `bne`):
  - Flush pipeline and restart from correct PC

---

## 7. Pipeline Stage Descriptions

### 7.1 Instruction Fetch (IF)
- Responsibilities:
  - Maintain PC register
  - Select next PC based on:
    - Branch prediction (BTB + BHT)
    - Jump / Jump Register (`j`, `jal`, `jr`)
    - Flush requests
    - Default `PC + 4`
  - Send read request to I-cache
  - Receive instruction and valid signal

- Dataflow:
  - If prediction incorrect and branch is taken:
    - PC is set to actual branch target from EX/MEM
  - If prediction incorrect and branch not taken:
    - PC is set to `PC + 4`
  - If BTB predicts taken and hits:
    - PC is set to BTB target
  - On stall/flush:
    - PC may be held or blocked

### 7.2 Instruction Decode (ID)
- Responsibilities:
  - Decode instruction fields: `opcode, rs, rt, rd, shamt, funct, immediate`
  - Sign/zero extend immediate
  - Generate control signals
  - Compute `branch target` and `jump target`
  - Detect syscall
  - Read register file

### 7.3 Execute (EX)
- Responsibilities:
  - Perform ALU operations:
    - Add/Sub, AND/OR/XOR/NOR, SLT/SLTU, shifts
  - Evaluate branch conditions
  - Contain an optimization to detect repeated instructions:
    - If current instruction equals previous and operands unchanged, reuse previous ALU result instead of recomputing
- Dataflow:
  - Combinational ALU computes `alu_result` and `alu_zero`
  - Sequential registers store:
    - `prev_id_ex_instr`
    - `prev_alu_result`
    - `prev_alu_zero`
  - On reset: clear all previous values

### 7.4 Memory Access (MEM)
- Responsibilities:
  - Interact with D-cache for load/store
  - Pass-through control and addresses from EX/MEM
  - Use `mem_size` and `mem_unsigned` to specify load/store type
  - Provide branch resolution result to BPU update logic

### 7.5 Write-Back (WB)
- Responsibilities:
  - Select write-back data:
    - For `jal`: PC + 4 to `$ra`
    - For load: memory data
    - Otherwise: ALU result
  - Assert `reg_write` and send data to register file

---

## 8. Register File

- 32 registers, 32-bit each, with MIPS naming:
  - `0x00` `$zero` (RAZ/WI – always 0)
  - `0x01` `$at`
  - `0x02–0x03` `$v0–$v1`
  - `0x04–0x07` `$a0–$a3`
  - `0x08–0x0F` `$t0–$t7`
  - `0x10–0x17` `$s0–$s7`
  - `0x18–0x19` `$t8–$t9`
  - `0x1A–0x1C` `$k0–$k1`, `$gp`
  - `0x1D` `$sp`
  - `0x1E` `$fp`
  - `0x1F` `$ra`

---

## 9. Control Signals

Main control signals:
- `reg_dst`
- `reg_write`
- `alu_src`
- `mem_read`
- `mem_write`
- `mem_to_reg`
- `beq`, `bne`
- `jump`, `jr`, `jal`
- `lui`
- `mem_unsigned`
- `mem_size`
- `alu_ctrl` (ALU operation code)

---

## 10. Limitations

- No exception handling
- No floating-point instructions or registers
- No CP0 or system control coprocessor

---

## 11. Summary

This project provides a full implementation of an in-order pipelined MIPS CPU with:
- Realistic memory latency
- Instruction and data caches
- Dynamic branch prediction
- Forwarding and stall-based hazard control

It is suitable for educational purposes in computer architecture courses, and as a foundation for designing more complex SoCs or adding advanced features (exceptions, MMU, more predictors, etc.).
