# Multi-Cycle CPU (Verilog)
 
A multi-cycle CPU implemented in Verilog, built around a 3-state fetch–execute–writeback control unit. Includes a datapath with ALU, register file, and status register, an instruction decoder, ROM-based instruction memory, and a testbench that runs a sample program and logs per-cycle execution state for verification.
 
## Architecture
 
- **Data width:** 8 bits
- **Instruction width:** 8 bits
- **Registers:** 4 (R0–R3)
- **Instruction memory:** 128 words (ROM)
- **Control:** 3-state FSM — `FETCH → EXECUTE → WRITEBACK → FETCH`
### Instruction format
 
Two encodings, selected by the mode bit (`instruction[0]`):
 
**Register mode** (`mode = 0`)
 
| Bits | Field |
|------|-------|
| [7:5] | Opcode |
| [4:3] | Destination register |
| [2:1] | Source register |
| [0]   | Mode (0) |
 
**Immediate mode** (`mode = 1`)
 
| Bits | Field |
|------|-------|
| [7:5] | Immediate[4:2] |
| [4:3] | Destination register |
| [2:1] | Immediate[1:0] |
| [0]   | Mode (1) |
 
### Opcodes
 
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| `000` | ADD | Add |
| `001` | SUB | Subtract |
| `010` | AND | Bitwise AND |
| `011` | OR  | Bitwise OR |
| `100` | XOR | Bitwise XOR |
| `101` | SHIFT | Shift (direction set by bit 1: 0 = left, 1 = right) |
| `110` | JMP | Jump to address in source register |
| `111` | BRZ | Branch if destination register is zero |
 
## Files
 
| File | Purpose |
|------|---------|
| `CPU_Multi.v` | Top-level CPU — FSM, instruction register, PC |
| `CPU_Path.v` | Datapath — connects ALU, register file, decoder |
| `ALU2.v` | Arithmetic/logic unit |
| `Decoder.v` | Instruction decoder |
| `SREG.v` | Status register |
| `ROM.v` | Instruction memory |
| `cpu_defs.vh` | Shared parameters, opcodes, field widths |
| `tb.v` | Testbench |
| `Program.hex` | Sample program loaded into ROM |
| `compile_cpu_multi.bat` | Compiles the design with Icarus Verilog |
 
## Running the simulation
 
Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`/`vvp`) on your PATH.
 
```powershell
compile_cpu_multi.bat
vvp cpu_multi.vvp
```
 
This compiles the design and testbench, then simulates the sample program in `Program.hex`. The testbench prints per-cycle state to the console and writes a VCD waveform file for inspection in a viewer such as GTKWave.
 
### Reading the output
 
Each cycle logs the FSM state, program counter, current instruction, write-enable signal, ALU/writeback result, and all register contents, e.g.:
 
```
CYCLE=2 STATE=10 PC=1 IR=61 WE=1 RESULT=12 R0=0 R1=0 R2=0 R3=0
```
 
- `STATE`: `00` = FETCH, `01` = EXECUTE, `10` = WRITEBACK
- `IR`: instruction register (hex)
- `WE`: register write-enable
- `RESULT`: value being written back this cycle
## License
 
No license yet — see repo for updates.
