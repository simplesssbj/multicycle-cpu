`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ============================================================
// CPU operational configuration
// ============================================================

`define CPU_INS_WIDTH       8
`define CPU_DATA_WIDTH      8
`define CPU_MEM_DEPTH       128

`define CPU_OPCODE_WIDTH    3
`define CPU_IMMEDIATE_WIDTH 5

`define CPU_RESET_ADDRESS   0


// ============================================================
// Register-file configuration
// ============================================================

`define CPU_NUM_REGS        4
`define CPU_REG_ADDR_WIDTH  2

`define REG_R0              2'b00
`define REG_R1              2'b01
`define REG_R2              2'b10
`define REG_R3              2'b11


// ============================================================
// Instruction-field positions
// ============================================================
//
// Register/control format:
//
// [7:5] Opcode
// [4:3] Destination register
// [2:1] Source register
// [0]   Mode = 0
//
// Immediate format:
//
// [7:5] Immediate[4:2]
// [4:3] Destination register
// [2:1] Immediate[1:0]
// [0]   Mode = 1
//

`define OPCODE_MSB          7
`define OPCODE_LSB          5

`define DEST_REG_MSB        4
`define DEST_REG_LSB        3

`define SRC_REG_MSB         2
`define SRC_REG_LSB         1

`define MODE_BIT            0


// ============================================================
// Instruction modes
// ============================================================

`define MODE_REGISTER       1'b0
`define MODE_IMMEDIATE      1'b1


// ============================================================
// Opcodes
// ============================================================

`define OP_ADD              3'b000
`define OP_SUB              3'b001
`define OP_AND              3'b010
`define OP_OR               3'b011
`define OP_XOR              3'b100
`define OP_SHIFT            3'b101
`define OP_JMP              3'b110
`define OP_BRZ              3'b111


// ============================================================
// Shift direction
// ============================================================
//
// For the SHIFT instruction, instruction[1] determines direction.
//

`define SHIFT_LEFT          1'b0
`define SHIFT_RIGHT         1'b1

`endif