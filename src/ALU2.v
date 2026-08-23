`include "cpu_defs.vh"

module ALU2 #(
    parameter WIDTH = `CPU_DATA_WIDTH
)(
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [2:0] opcode,
    input shift_right,
    
    output reg [WIDTH-1:0] Result,
    output Zero,
    output reg Carry,
    output Negative,
    output reg Overflow
);

always @(*) begin
    Result = '0;
    Carry = 0;
    Overflow = 0;
    case (opcode)
        `OP_ADD: begin
            {Carry, Result} = {1'b0, A} + {1'b0, B};

            Overflow =
                (A[WIDTH-1] == B[WIDTH-1]) &&
                (Result[WIDTH-1] != A[WIDTH-1]);
        end

        `OP_SUB: begin
            {Carry, Result} =
                {1'b0, A} + {1'b0, ~B} + 1'b1;

            Overflow =
                (A[WIDTH-1] != B[WIDTH-1]) &&
                (Result[WIDTH-1] != A[WIDTH-1]);
        end

        `OP_AND:
            Result = A & B;

        `OP_OR:
            Result = A | B;

        `OP_XOR:
            Result = A ^ B;

        `OP_SHIFT: begin
            if (shift_right == `SHIFT_RIGHT)
                Result = A >> 1;
            else
                Result = A << 1;
        end

        default: begin
            Result   = '0;
            Carry    = 1'b0;
            Overflow = 1'b0;
        end
    endcase
end

assign Zero = (Result == 0);
assign Negative = Result[WIDTH-1];

endmodule