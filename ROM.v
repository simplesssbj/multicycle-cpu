module instruction_memory #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 256
)(
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] instruction
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    initial begin
    $readmemh("Program.hex", mem);    end

    assign instruction = mem[addr];

endmodule