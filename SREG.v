module SREG #(
    parameter BitWidth = 8,
    parameter Numreg = 4
)(
    input clk,
    input rstn,
    input we,
    input [$clog2(Numreg)-1:0] waddr,
    input [$clog2(Numreg)-1:0] raddr1,
    input [$clog2(Numreg)-1:0] raddr2,

    input [BitWidth-1:0] wdata,

    output reg [BitWidth-1:0] rdata1,
    output reg [BitWidth-1:0] rdata2
);
    reg [BitWidth-1:0] mem [Numreg-1:0];
    integer i;

    always @(*) begin
        rdata1 = mem[raddr1];
        rdata2 = mem[raddr2];
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
             for (i = 0; i < Numreg; i = i + 1)
                mem[i] <= '0;

        end
        else if (we) begin
            mem[waddr] <= wdata;
        end
    end

endmodule