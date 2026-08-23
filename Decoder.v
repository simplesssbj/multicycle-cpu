`include "cpu_defs.vh"

module instruction_decoder (
    input  [`CPU_INS_WIDTH-1:0] instruction,
    output [`CPU_OPCODE_WIDTH-1:0] opcode,
    output [`CPU_REG_ADDR_WIDTH-1:0] DestReg,
    output [`CPU_REG_ADDR_WIDTH-1:0] SrcReg,
    output extra
);

    assign opcode =
        instruction[`OPCODE_MSB:`OPCODE_LSB];

    assign DestReg =
        instruction[`DEST_REG_MSB:`DEST_REG_LSB];

    assign SrcReg =
        instruction[`SRC_REG_MSB:`SRC_REG_LSB];

    assign extra =
        instruction[`MODE_BIT];

endmodule