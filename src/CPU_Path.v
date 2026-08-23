`include "cpu_defs.vh"

module CPUPath_Multi #(
    parameter InsWidth  = `CPU_INS_WIDTH,
    parameter MemDepth = `CPU_MEM_DEPTH,
    parameter DataWidth = `CPU_DATA_WIDTH,
    parameter Numreg    = `CPU_NUM_REGS
)(
        input clk,
        input rstn,
        input [DataWidth-1:0] WritebackData,
        input reg_write_enable,
        input  [InsWidth-1:0]  Current_Instruction,

        output [DataWidth-1:0] ALUResultOut,
        output [2:0]           Out_OP,
        output [DataWidth-1:0] Rd,
        output [DataWidth-1:0] Rs,
        output                 ModeOut,
        output [DataWidth-1:0] Immediate_value_out
    );


    wire [2:0] OP;
    wire [1:0] TargetReg;
    wire [1:0] SourceReg;
    wire Mode;

    instruction_decoder Decode(
        .instruction(Current_Instruction),
        .opcode(OP),
        .DestReg(TargetReg),
        .SrcReg(SourceReg),
        .extra(Mode)
    );


    wire [DataWidth-1:0] ALU_OUT;
    wire [DataWidth-1:0] TargetData;
    wire [DataWidth-1:0] SourceData;

    wire [`CPU_IMMEDIATE_WIDTH-1:0] Immediate;

    assign Immediate = {OP, SourceReg};

    wire [DataWidth-1:0] ImmediateValue;

    assign ImmediateValue =
        {{(DataWidth-`CPU_IMMEDIATE_WIDTH){1'b0}}, Immediate};
        
    SREG #(
        .BitWidth(DataWidth),
        .Numreg(Numreg)
    ) regfile(
        .clk(clk),
        .rstn(rstn),
        .waddr(TargetReg),
        .raddr1(TargetReg),
        .raddr2(SourceReg),
        .wdata(WritebackData),
        .rdata1(TargetData),
        .rdata2(SourceData),
        .we(reg_write_enable)
    );




    ALU2 #(
        .WIDTH(DataWidth)
    ) alu(
        .opcode(OP),
        .A(TargetData),
        .B(SourceData),
        .Result(ALU_OUT),
        .Zero(),
        .Carry(),
        .Negative(),
        .Overflow(),
        .shift_right(SourceReg[0])
    );

    assign ALUResultOut    = ALU_OUT;
    assign Out_OP = OP;
    assign Rs = SourceData;
    assign Rd = TargetData;
    assign ModeOut = Mode;
    assign Immediate_value_out = ImmediateValue;
    endmodule