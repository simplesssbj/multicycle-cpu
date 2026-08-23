`timescale 1ns/1ps

module tb;

    localparam InsWidth  = 8;
    localparam MemDepth = 128;
    localparam DataWidth = 8;
    localparam Numreg    = 4;
    localparam AddrWidth = $clog2(MemDepth);

    localparam FETCH     = 2'b00;
    localparam EXECUTE   = 2'b01;
    localparam WRITEBACK = 2'b10;

    localparam OP_ADD   = 3'b000;
    localparam OP_SUB   = 3'b001;
    localparam OP_AND   = 3'b010;
    localparam OP_OR    = 3'b011;
    localparam OP_XOR   = 3'b100;
    localparam OP_SHIFT = 3'b101;
    localparam OP_JMP   = 3'b110;
    localparam OP_BRZ   = 3'b111;

    reg clk;
    reg rstn;

    integer errors;
    integer cycles;
    integer loop_hits;
    integer monitoring;
    integer log_file;
    integer seen_ldi;
    integer seen_add;
    integer seen_sub;
    integer seen_and;
    integer seen_or;
    integer seen_xor;
    integer seen_shl;
    integer seen_shr;
    integer seen_jmp;
    integer seen_brz_taken;
    integer seen_brz_not_taken;

    reg [1:0] prev_state;
    reg [AddrWidth-1:0] prev_pc;
    reg [InsWidth-1:0] prev_ir;
    reg [DataWidth-1:0] prev_execution_result;

    reg [2:0] prev_op;
    reg prev_mode;
    reg [DataWidth-1:0] prev_rs;
    reg [DataWidth-1:0] prev_rd;
    reg [DataWidth-1:0] prev_alu;
    reg [DataWidth-1:0] prev_immediate;

    reg [DataWidth-1:0] prev_r0;
    reg [DataWidth-1:0] prev_r1;
    reg [DataWidth-1:0] prev_r2;
    reg [DataWidth-1:0] prev_r3;

    reg [1:0] expected_state;
    reg [AddrWidth-1:0] expected_pc;
    reg [InsWidth-1:0] expected_ir;
    reg [DataWidth-1:0] expected_execution_result;

    reg [DataWidth-1:0] expected_r0;
    reg [DataWidth-1:0] expected_r1;
    reg [DataWidth-1:0] expected_r2;
    reg [DataWidth-1:0] expected_r3;

    CPU_Multi #(
        .InsWidth(InsWidth),
        .MemDepth(MemDepth),
        .DataWidth(DataWidth),
        .Numreg(Numreg)
    ) dut (
        .clk(clk),
        .rstn(rstn)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task fail;
        input [8*120-1:0] message;
        begin
            errors = errors + 1;
            $display("ERROR at cycle %0d: %0s", cycles, message);
        end
    endtask

    always @(posedge clk) begin
        #1;

        if (!rstn) begin
            monitoring = 0;
        end
        else if (monitoring) begin
            cycles = cycles + 1;

            case (prev_state)
                FETCH:     expected_state = EXECUTE;
                EXECUTE: begin
                    if (
                        (prev_mode == 1'b0) &&
                        ((prev_op == OP_JMP) || (prev_op == OP_BRZ))
                    )
                        expected_state = FETCH;
                    else
                        expected_state = WRITEBACK;
                end
                WRITEBACK: expected_state = FETCH;
                default:   expected_state = FETCH;
            endcase

            if (dut.current_state !== expected_state) begin
                $display("State: previous=%b expected=%b actual=%b",
                         prev_state, expected_state, dut.current_state);
                fail("illegal FSM transition");
            end

            expected_pc = prev_pc;

            if (prev_state == FETCH) begin
                if (prev_pc == MemDepth-1)
                    expected_pc = prev_pc;
                else
                    expected_pc = prev_pc + 1'b1;
            end
            else if (
                (prev_state == EXECUTE) &&
                (prev_mode == 1'b0) &&
                (prev_op == OP_JMP)
            ) begin
                expected_pc = prev_rs[AddrWidth-1:0];
            end
            else if (
                (prev_state == EXECUTE) &&
                (prev_mode == 1'b0) &&
                (prev_op == OP_BRZ) &&
                (prev_rd == 0)
            ) begin
                expected_pc = prev_rs[AddrWidth-1:0];
            end

            if (dut.PC_Counter !== expected_pc) begin
                $display("PC: previous=%0d expected=%0d actual=%0d",
                         prev_pc, expected_pc, dut.PC_Counter);
                fail("incorrect PC update");
            end

            if (prev_state == FETCH)
                expected_ir = dut.IM.mem[prev_pc];
            else
                expected_ir = prev_ir;

            if (dut.InstructionRegister !== expected_ir) begin
                $display("IR: expected=%02h actual=%02h",
                         expected_ir, dut.InstructionRegister);
                fail("instruction register changed incorrectly");
            end

            expected_execution_result = prev_execution_result;

            if (prev_state == EXECUTE) begin
                if (prev_mode == 1'b1)
                    expected_execution_result = prev_immediate;
                else if (prev_op <= OP_SHIFT)
                    expected_execution_result = prev_alu;
            end

            if (dut.ExecutionResult !== expected_execution_result) begin
                $display("ExecutionResult: expected=%0d actual=%0d",
                         expected_execution_result, dut.ExecutionResult);
                fail("ExecutionResult changed incorrectly");
            end

            expected_r0 = prev_r0;
            expected_r1 = prev_r1;
            expected_r2 = prev_r2;
            expected_r3 = prev_r3;

            if (prev_state == WRITEBACK) begin
                case (prev_ir[4:3])
                    2'b00: expected_r0 = prev_execution_result;
                    2'b01: expected_r1 = prev_execution_result;
                    2'b10: expected_r2 = prev_execution_result;
                    2'b11: expected_r3 = prev_execution_result;
                endcase
            end

            if (
                (dut.datapath.regfile.mem[0] !== expected_r0) ||
                (dut.datapath.regfile.mem[1] !== expected_r1) ||
                (dut.datapath.regfile.mem[2] !== expected_r2) ||
                (dut.datapath.regfile.mem[3] !== expected_r3)
            ) begin
                $display("Expected registers: R0=%0d R1=%0d R2=%0d R3=%0d",
                         expected_r0, expected_r1, expected_r2, expected_r3);
                $display("Actual registers:   R0=%0d R1=%0d R2=%0d R3=%0d",
                         dut.datapath.regfile.mem[0],
                         dut.datapath.regfile.mem[1],
                         dut.datapath.regfile.mem[2],
                         dut.datapath.regfile.mem[3]);
                fail("register write timing/data error");
            end

            if (dut.WE !== (dut.current_state == WRITEBACK))
                fail("WE is not asserted only during WRITEBACK");

            if (prev_state == EXECUTE) begin
                if (prev_mode == 1'b1) begin
                    seen_ldi = 1;
                end
                else begin
                    case (prev_op)
                        OP_ADD: seen_add = 1;
                        OP_SUB: seen_sub = 1;
                        OP_AND: seen_and = 1;
                        OP_OR:  seen_or  = 1;
                        OP_XOR: seen_xor = 1;
                        OP_SHIFT: begin
                            if (prev_ir[1] == 1'b0)
                                seen_shl = 1;
                            else
                                seen_shr = 1;
                        end
                        OP_JMP: seen_jmp = 1;
                        OP_BRZ: begin
                            if (prev_rd == 0)
                                seen_brz_taken = 1;
                            else
                                seen_brz_not_taken = 1;
                        end
                    endcase
                end
            end

            if ((prev_state == FETCH) && ((prev_pc == 14) || (prev_pc == 19)))
                fail("branch/jump failed to skip address 14 or 19");

            if (
                (dut.current_state == FETCH) &&
                (dut.PC_Counter == 20) &&
                (dut.InstructionRegister == 8'hC6)
            )
                loop_hits = loop_hits + 1;

            $display(
                "CYCLE=%0d STATE=%b PC=%0d IR=%02h WE=%b RESULT=%0d R0=%0d R1=%0d R2=%0d R3=%0d",
                cycles,
                dut.current_state,
                dut.PC_Counter,
                dut.InstructionRegister,
                dut.WE,
                dut.ExecutionResult,
                dut.datapath.regfile.mem[0],
                dut.datapath.regfile.mem[1],
                dut.datapath.regfile.mem[2],
                dut.datapath.regfile.mem[3]
            );

             $fdisplay(
            log_file,
            "CYCLE=%0d STATE=%b PC=%0d IR=%02h WE=%b RESULT=%0d R0=%0d R1=%0d R2=%0d R3=%0d",
            cycles,
            dut.current_state,
            dut.PC_Counter,
            dut.InstructionRegister,
            dut.WE,
            dut.ExecutionResult,
            dut.datapath.regfile.mem[0],
            dut.datapath.regfile.mem[1],
            dut.datapath.regfile.mem[2],
            dut.datapath.regfile.mem[3]
        );
            prev_state            = dut.current_state;
            prev_pc               = dut.PC_Counter;
            prev_ir               = dut.InstructionRegister;
            prev_execution_result = dut.ExecutionResult;
            prev_op               = dut.OP;
            prev_mode             = dut.Mode;
            prev_rs               = dut.Rs;
            prev_rd               = dut.Rd;
            prev_alu              = dut.ALUResultOut;
            prev_immediate        = dut.ImmediateValue;
            prev_r0               = dut.datapath.regfile.mem[0];
            prev_r1               = dut.datapath.regfile.mem[1];
            prev_r2               = dut.datapath.regfile.mem[2];
            prev_r3               = dut.datapath.regfile.mem[3];
        end
    end

    initial begin
        $dumpfile("CPU_Multi.vcd");
        $dumpvars(0, tb);
        log_file = $fopen("cpu_execution.log", "w");

        if (log_file == 0) begin
            $display("ERROR: Could not open cpu_execution.log");
            $finish;
        end
        errors = 0;
        cycles = 0;
        loop_hits = 0;
        monitoring = 0;

        seen_ldi = 0;
        seen_add = 0;
        seen_sub = 0;
        seen_and = 0;
        seen_or = 0;
        seen_xor = 0;
        seen_shl = 0;
        seen_shr = 0;
        seen_jmp = 0;
        seen_brz_taken = 0;
        seen_brz_not_taken = 0;

        rstn = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rstn = 1'b1;

        #1;
        prev_state            = dut.current_state;
        prev_pc               = dut.PC_Counter;
        prev_ir               = dut.InstructionRegister;
        prev_execution_result = dut.ExecutionResult;
        prev_op               = dut.OP;
        prev_mode             = dut.Mode;
        prev_rs               = dut.Rs;
        prev_rd               = dut.Rd;
        prev_alu              = dut.ALUResultOut;
        prev_immediate        = dut.ImmediateValue;
        prev_r0               = dut.datapath.regfile.mem[0];
        prev_r1               = dut.datapath.regfile.mem[1];
        prev_r2               = dut.datapath.regfile.mem[2];
        prev_r3               = dut.datapath.regfile.mem[3];

        monitoring = 1;

        wait ((loop_hits >= 3) || (cycles >= 120));
        #2;

        if (cycles >= 120)
            fail("timeout before final self-loop");

        if (
            (dut.PC_Counter !== 7'd20) ||
            (dut.datapath.regfile.mem[0] !== 8'd7) ||
            (dut.datapath.regfile.mem[1] !== 8'd5) ||
            (dut.datapath.regfile.mem[2] !== 8'd0) ||
            (dut.datapath.regfile.mem[3] !== 8'd20)
        )
            fail("incorrect final architectural state");

        if (
            !seen_ldi || !seen_add || !seen_sub || !seen_and ||
            !seen_or || !seen_xor || !seen_shl || !seen_shr ||
            !seen_jmp || !seen_brz_taken || !seen_brz_not_taken
        ) begin
            $display(
                "Coverage: LDI=%0d ADD=%0d SUB=%0d AND=%0d OR=%0d XOR=%0d SHL=%0d SHR=%0d JMP=%0d BRZ_T=%0d BRZ_NT=%0d",
                seen_ldi, seen_add, seen_sub, seen_and, seen_or,
                seen_xor, seen_shl, seen_shr, seen_jmp,
                seen_brz_taken, seen_brz_not_taken
            );
            fail("not every ISA behavior was executed");
        end

        if (errors == 0) begin
            $display("==================================================");
            $display("ALL MULTI-CYCLE CPU TESTS PASSED");
            $display("FSM, PC, IR, writeback, branch, jump, and ISA OK");
            $display("Final: PC=20 R0=7 R1=5 R2=0 R3=20");
            $display("==================================================");
        end
        else begin
            $display("==================================================");
            $display("MULTI-CYCLE CPU TEST FAILED: %0d error(s)", errors);
            $display("==================================================");
        end

        $fclose(log_file);  
        $finish;
    end

endmodule
