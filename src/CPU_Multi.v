`include "cpu_defs.vh"

module CPU_Multi #(
    parameter InsWidth  = `CPU_INS_WIDTH,
    parameter MemDepth = `CPU_MEM_DEPTH,
    parameter DataWidth = `CPU_DATA_WIDTH,
    parameter Numreg    = `CPU_NUM_REGS,
    parameter Num_states = 3
)(
    input clk,
    input rstn
);

    localparam AddrWidth = $clog2(MemDepth);

    localparam JMP = `OP_JMP;
    localparam BRZ = `OP_BRZ;


    localparam FETCH     = 2'b00;
    localparam EXECUTE   = 2'b01;
    localparam WRITEBACK = 2'b10;



    reg [AddrWidth-1:0] PC_Counter;
    wire [2:0] OP;
    wire [DataWidth-1:0] Rs;
    wire [DataWidth-1:0] Rd;
    wire Mode;
    wire WE;
    wire [InsWidth-1:0] MemoryInstruction;
    reg  [InsWidth-1:0] InstructionRegister;

    wire [DataWidth-1:0] ImmediateValue;
    wire [DataWidth-1:0] ALUResultOut;

    reg  [DataWidth-1:0] ExecutionResult;

    reg [$clog2(Num_states)-1:0] current_state, Next_state;


    instruction_memory #(
        .ADDR_WIDTH($clog2(MemDepth)),
        .DATA_WIDTH(InsWidth),
        .MEM_DEPTH(MemDepth)
    )IM(
        .addr(PC_Counter),
        .instruction(MemoryInstruction)
    );

    
    CPUPath_Multi #(
        .InsWidth(InsWidth),
        .MemDepth(MemDepth),
        .DataWidth(DataWidth),
        .Numreg(Numreg)
    ) datapath (
        .clk(clk),
        .rstn(rstn),
        .Current_Instruction(InstructionRegister),
        .reg_write_enable(WE),
        .WritebackData(ExecutionResult),
        .ALUResultOut(ALUResultOut),
        .Out_OP(OP),
        .Rd(Rd),
        .Rs(Rs),
        .ModeOut(Mode),
        .Immediate_value_out(ImmediateValue)
    );





    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            PC_Counter<=0;
            current_state<=FETCH;
            InstructionRegister<=0;
            ExecutionResult<=0;
        end
        else begin

            current_state<=Next_state;

            case (current_state)
                FETCH: begin
                InstructionRegister<= MemoryInstruction;
                if(PC_Counter == MemDepth-1)
                    PC_Counter <= PC_Counter;
                else
                    PC_Counter <= PC_Counter+1'b1;
            end 
                EXECUTE:begin
                    if (Mode==`MODE_IMMEDIATE) begin
                        ExecutionResult<=ImmediateValue;
                    end else begin
                        if (OP <= `OP_SHIFT) begin
                            ExecutionResult<=ALUResultOut;
                        end else if (OP == `OP_JMP) begin
                            PC_Counter<=Rs[AddrWidth-1:0];
                        end else if (OP == BRZ && Rd == 0) begin
                            PC_Counter<=Rs[AddrWidth-1:0];                            
                        end
                    end
                end
                WRITEBACK:begin
                end
            endcase        
        end
    end

    always @(*) begin
        case (current_state)
            FETCH: 
                Next_state = EXECUTE;
            EXECUTE: if (Mode == `MODE_REGISTER && (OP == `OP_BRZ || OP == `OP_JMP)) begin
                Next_state = FETCH;
            end else begin
                Next_state = WRITEBACK;
            end
            WRITEBACK:
                Next_state = FETCH;
            default: begin
                Next_state = FETCH;
            end
        endcase
    end

    assign WE = (current_state == WRITEBACK);
endmodule