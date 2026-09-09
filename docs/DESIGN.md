# SC8 — Single-Cycle 8-Instruction CPU

A custom-designed CPU implementing a self-defined 8-instruction ISA, written in
Verilog and deployed on a DE0-Nano FPGA with memory-mapped UART I/O and onboard
LED status output.

## Module Overview

| File | Purpose | Status |
|------|---------|--------|
| rtl/register_file.v | 8x16-bit register file. R0 hardwired to 0 (write-blocked and read-overridden). Synchronous reset clears all registers to 0 at startup. | Done, verified |
| rtl/alu.v | ADD/SUB/AND/OR, purely combinational. | Done, verified |
| rtl/instr_mem.v | Instruction ROM (32 x 16-bit), loaded via `$readmemh` from program.hex. | Done, verified |
| rtl/pc.v | Program counter. Synchronous reset, default increment, signed branch offset, halt-freeze. | Done, verified |
| rtl/data_mem.v | Data RAM (32 x 16-bit), loaded via `$readmemh` from data.hex. | Done, verified |
| rtl/cu.v | Opcode decode into reg_we, mem_we, alu_op, alu_src. | Done, verified |
| rtl/sc8_top.v | Top-level datapath. Wires all modules together, decodes instruction fields, resolves alu_src, rt_addr, branch_taken, halt, and writeback muxes. | Done, verified end-to-end against program.hex |
| rtl/baud_gen.v | UART baud rate tick generator (50 MHz system clock to 9600 baud). | In progress |
| rtl/uart_tx.v | UART transmitter, driven by baud_gen ticks. | Not started |
| quartus/ | Quartus project files, target device (Cyclone IV, EP4CE22F17C6), pin assignments. | Project created. Pin assignment and synthesis not yet done |

This table tracks structure and status only. Reasoning for individual design
choices is documented in the sections below. This table is not a substitute
for them.

## Architecture Overview

The processor uses a single-cycle design. Each instruction completes fetch,
decode, execute, memory access, and writeback within a single clock cycle,
with no overlap between instructions. This avoids the hazard detection,
forwarding, and pipeline register logic required by a pipelined design, at
the cost of clock speed. For this project, correctness and completeness were
prioritised over performance.

The five stages map onto the datapath as follows. Fetch is the PC plus
instruction memory. Decode is the field extraction plus the control unit.
Execute is the register file read plus the ALU. Memory is the data memory
access (LOAD/STORE only). Writeback is the mux selecting what value is
actually written back into the register file. In a single-cycle design these
stages have no register boundaries between them and resolve within one clock
cycle, so they appear in the RTL as one continuous chain of combinational
logic rather than as physically separated blocks.

## Instruction Set

The ISA consists of eight instructions, selected to demonstrate the core
capabilities expected of a functioning processor. data movement, arithmetic,
logic operations, control flow, and program termination.

| Instruction | Opcode | Format | Operation |
|-------------|--------|--------|-----------|
| LOAD        | 000    | I-type | Rd ← Mem[Rs + offset] |
| STORE       | 001    | I-type | Mem[Rs + offset] ← Rt |
| ADD         | 010    | R-type | Rd ← Rs + Rt |
| SUB         | 011    | R-type | Rd ← Rs − Rt |
| AND         | 100    | R-type | Rd ← Rs & Rt |
| OR          | 101    | R-type | Rd ← Rs | Rt |
| BEQ         | 110    | I-type | if Rs == Rt, PC ← PC + offset |
| HALT        | 111    | —      | Stop execution |

An unconditional JUMP instruction was considered and excluded. BEQ with a
register compared against itself produces equivalent behaviour, and omitting
JUMP keeps the decode logic smaller.

Dedicated immediate-arithmetic instructions (e.g. ADDI, ANDI, ORI) were also
considered and excluded, to keep the opcode space at eight instructions and
avoid the wider immediate field they would require. Getting a constant value
into a register is still achievable via LOAD from a preloaded memory location.
This costs an extra instruction and temporarily occupies a register, a
trade-off accepted given the small size of the target test program.

A 3-bit opcode field was chosen as the minimum required to encode eight
instructions (2^3 = 8), with no unused encoding space.

## Instruction Encoding

Instructions are 16 bits wide. This width accommodates an opcode, register
fields, and a usable offset, while keeping the datapath narrow enough to
remain straightforward to implement and debug. An 8-bit format would not
leave sufficient room for both register fields and an offset. A 32-bit
format was judged unnecessary for an eight-register machine.

Two instruction formats are used.

**R-type** (ADD, SUB, AND, OR)
```
[15:13] opcode | [12:10] Rd | [9:7] Rs | [6:4] Rt | [3:0] unused
```

**I-type** (LOAD, STORE, BEQ)
```
[15:13] opcode | [12:10] Rd/Rt | [9:7] Rs (base/compare) | [6:0] signed offset
```

HALT requires only the opcode field. Remaining bits are unused.

### Register Field Width

Register fields are 3 bits wide, providing eight addressable registers (R0-R7).
An earlier version of this design used 2-bit fields (four registers), traded
directly against a wider branch offset. That version was revisited against
reference microarchitecture material (UCL ELEC0004), which uses a similar
single-cycle structure at a larger scale (16 registers, 24-bit instructions).
Rather than adopt that scale wholesale, eight registers was chosen as a
middle point. It gives real headroom over the original four-register design,
without the branch-offset cost of a full-width immediate field, and without
departing from the 16-bit instruction width already established.

R0 is hardwired to always read as the constant 0. Writes to R0 are ignored by
the register file. This mirrors the x0 register convention used in RISC-V and
in the ELEC0004 reference material. At only a handful of registers, reserving
one by software convention alone would be fragile (a stray write could
silently corrupt every zero-comparison in a program) and comparatively
expensive (a full register out of a small total). Enforcing it in hardware
removes both risks at the cost of a few lines of logic in the register file.
This also provides a natural way to test for zero (e.g. for loop termination
via BEQ) without a dedicated comparison instruction.

The zero-register guarantee is enforced in two independent places. Writes to
R0 are blocked in the write logic, and reads from R0 are separately forced to
0 regardless of the underlying storage. The read-side override is not
redundant with the write-side block. It also guarantees R0 reads as 0 from
the very first cycle, before any reset or write has necessarily occurred.

### Register File Reset

All 8 registers are cleared to 0 by a synchronous reset, evaluated before the
normal write logic. This was added after an integration bug (see Debugging
Log). Registers other than R0 have no defined value at power-up, so a
sequence such as subtracting a register from itself to produce zero is not
safe without it. Verilog's unknown state (x) subtracted from itself
evaluates to x, not 0. Relying on program ordering to avoid ever reading an
uninitialised register would be fragile and easy to violate by accident.
Clearing all registers at reset removes the failure mode entirely, mirroring
how real hardware requires a defined reset state rather than trusting
software convention.

### Why R-type Needs Three Register Fields and I-type Needs Two

R-type instructions (ADD, SUB, AND, OR) read two source registers and write a
third, distinct destination register. Three simultaneous register roles are
required. I-type instructions never need three at once. LOAD reads one base
register and writes one destination. STORE reads one base register and one
value register. BEQ reads two registers for comparison and writes none. In
every I-type case, at most two register roles are needed, so the second
field is reused as either a destination (LOAD) or a second source (STORE,
BEQ) depending on the instruction, rather than reserving a dedicated third
field that most I-type instructions would leave unused.

In the datapath, this means the register file's rt_addr input cannot be
wired to a single fixed bit range. For R-type instructions it must read bits
[6:4] (Rt), but for I-type instructions (LOAD, STORE, BEQ) the second
register role actually lives at the same bit position as Rd, [12:10]. A mux
in sc8_top.v selects between these two fields based on opcode before driving
rt_addr. This was missed on the first integration pass (see Debugging Log).

### Offset Width

The I-type offset is 7 bits, signed, giving a range of approximately -64 to
+63 instructions. This is the field width remaining once the opcode and two
3-bit register fields are subtracted from the 16-bit instruction word. This
is narrower than the 9-bit offset available under the earlier four-register
design, a direct trade-off for the wider register fields, but remains
sufficient for the target test program's loop size.

Offsets are relative (PC <- PC + offset) rather than absolute addresses. This
differs from the ELEC0004 reference design, which uses an absolute jump
target. Relative offsets were kept because they allow code to be relocated
in memory without recalculating branch targets, matching the convention used
in RISC-V. This is a deliberate deviation from the reference material rather
than an oversight.

The branch calculation in pc.v adds the offset to the current, un-incremented
PC value, not PC+1. Offsets in a program are therefore calculated as
target_address minus current_instruction_address. This convention was fixed
before hand-encoding program.hex's branch instructions, since the alternative
(basing the offset on PC+1) would require every offset to be one less.

## Execute Stage: ALU Input Selection

The ALU's first input is always rs_data from the register file. Every
instruction that uses the ALU reads its first operand from Rs, so no mux is
needed on this input.

The ALU's second input is selected by alu_src, a control unit output.
alu_src = 0 (ADD, SUB, AND, OR, BEQ) means the second input is rt_data from
the register file. alu_src = 1 (LOAD, STORE) means the second input is the
instruction's 7-bit signed offset field, sign-extended to 16 bits.

This reuses the ALU's existing ADD path for LOAD/STORE address calculation
(Rs + offset) and its SUB path for BEQ's equality check (Rs - Rt, branch
taken if the result is zero) rather than building dedicated address or
comparator hardware. Sign extension of the offset is done by replicating its
sign bit (offset[6]) into the upper 9 bits before concatenating with the
original 7 bits, so a negative offset is interpreted correctly rather than
being corrupted by simple zero-padding.

## Program Termination

HALT (opcode 111) does not merely disable register and memory writes. It
must also stop the PC from advancing, since instruction memory beyond the
loaded program is uninitialised. pc.v has a dedicated halt input that
freezes pc_out at its current value once HALT is decoded, overriding both
the default increment and any branch. Without this, the PC would continue
fetching unknown instructions after HALT, corrupting already-correct
register and memory state (see Debugging Log).

## Instruction Memory

Instruction memory is implemented as a fixed ROM (reg [15:0] instr_mem
[0:31]), populated via $readmemh or an initial block. Test programs are
hand-assembled into hexadecimal rather than produced by a toolchain. This is
a deliberate, disclosed simplification given the project timeline, not an
oversight.

The current test program (program.hex) sums a counter counting down from 3
to 0 into an accumulator, storing the result to data memory address 2. It
exercises LOAD, ADD, SUB, both BEQ roles (conditional exit and unconditional
loop-back), STORE, and HALT. AND and OR are not exercised by this program.
They are verified independently in alu_tb.v and cu_tb.v.

## Testing

Two integrated test programs were used to test the full datapath end to end, 
beyond the individual module testbenches (register_file_tb.v, alu_tb.v, etc.).

**program.hex / data.hex** — the primary test program. Sums a counter
counting down from 3 to 0 into an accumulator, storing the result to data
memory address 2 and echoing it to UART via address 31. Exercises LOAD,
ADD, SUB, both BEQ roles (conditional exit and unconditional loop-back),
STORE, and HALT.

**program2.hex / data2.hex** — a second program covering what the first
does not: AND, OR, BEQ's not-taken path, and a LOAD/STORE round trip using
a non-zero base register (rather than R0, as every address calculation in
the first program uses). Checked with sc8_top_tb2.v, which prints all
computed registers and asserts on the two results that would most likely
expose a real bug: the BEQ-not-taken outcome and the non-zero-base address
calculation.

Both programs load via sc8_top's INSTR_FILE/DATA_FILE parameters, which
default to program.hex/data.hex so the primary testbench and eventual
hardware deployment are unaffected by the second program's existence.

## Output

Program output is observed via two channels. a memory-mapped UART peripheral
transmitting to a connected PC, and onboard LEDs on the DE0-Nano reflecting
processor status (e.g. register values, PC, HALT state). Both were judged
in-scope, as neither requires additional driver logic beyond output pin
assignment.

### UART Baud Rate Generation

The DE0-Nano's onboard oscillator runs at 50 MHz, connected to a fixed pin
(R8) per the board's user manual. UART requires both ends of the connection
to agree on a fixed bit rate, called the baud rate. 9600 baud was chosen as
a common, reliable rate for a simple project. The system clock cannot drive
UART bit transmission directly, since 50 MHz is far faster than any
receiving terminal could interpret as individual bits.

A baud rate generator (baud_gen.v) produces a single-cycle pulse (baud_tick)
once every 50,000,000 / 9600, approximately 5208, system clock cycles, using
a free-running counter. This tick, not the system clock, paces the UART
transmitter's bit timing. The counter is 13 bits wide (2^13 = 8192), the
smallest power of two able to count up to 5208.

This introduces a small rounding error: the exact ratio is 5208.33, but the
counter only counts whole cycles, so each tick is short by about 0.33 cycles.
This error accumulates at a constant rate over time, so the percentage error 
stays fixed at roughly 0.006% indefinitely rather than growing worse. This 
is well within UART's typical few-percent tolerance for baud error, so a 
plain free-running counter is sufficient here.

## Decisions Log

- 2026-09-07: Verilog was selected over VHDL/SystemVerilog because of prior
  familiarity from the Digital Electronics module, avoiding time lost to
  relearning syntax under a fixed deadline.
- 2026-09-07: The project is named SC8 (Single-Cycle, 8-instruction).
- 2026-09-08: Register field width was widened from 2 bits (4 registers) to
  3 bits (8 registers) after comparing the design against UCL ELEC0004
  reference microarchitecture material, trading branch offset range for
  register headroom. See "Register Field Width" above.
- 2026-09-08: R0 was hardwired to the constant 0, following the same
  convention used in RISC-V and in the ELEC0004 reference material. See
  "Register Field Width" above.
- 2026-09-09: 9600 baud was chosen for UART as a simple, reliable,
  commonly-used rate for a project at this scale.

## Deferred to a Later Phase

The following were considered and deliberately excluded from the initial
build, to be revisited once the core CPU is complete and any related
application has been submitted.

- **Minimal assembler** (mnemonic to hex, written in Python). Would
  demonstrate understanding of the software side of the hardware/software
  interface, but is not required to demonstrate a working CPU.
- **Dedicated immediate-arithmetic instructions** (ADDI, ANDI, ORI). Would
  remove the need to route constants through memory via LOAD, at the cost of
  a wider opcode field and reduced register-field or offset space.
- **Subroutine calls** (CALL/RET with a stack pointer). A natural extension
  once branching exists, required for real programs beyond simple loops, but
  a genuine feature addition requiring a new register and push/pop logic.
- **Software reference model** of the ISA (Python or C), used as a golden
  model for cross-verifying RTL behaviour. A standard industry technique,
  but one that would compete directly with RTL development time within the
  build window.
- **RV32I (RISC-V base integer ISA) implementation**, as a separate, second
  project, to complement this custom-ISA build with an implementation of a
  standardised real-world specification.
- **UART receive**, to allow loading register/data contents at runtime
  rather than only at synthesis time. The current build is transmit-only.
  The program and its inputs are fixed when the design is synthesised.

## Debugging Log

- 2026-09-08: Missing comma between rt_addr and wr_data in
  register_file.v's port list caused a vlog syntax error on first compile
  attempt. Fixed by adding the comma.
- 2026-09-08: ALU. no bugs encountered. Verified ADD/SUB/AND/OR against
  known operand pairs on first run.
- 2026-09-08: PC. initial design used an unsigned branch_offset, which
  would have silently miscalculated backward (negative) branches. Fixed by
  declaring branch_offset as signed and wrapping it in $signed() during the
  branch calculation. A dedicated backward-branch test (offset -5) was
  added specifically to catch this, since a forward-only test would have
  passed even with the broken unsigned version.
- 2026-09-08: data_mem. a testbench check for write blocked when we=0
  initially used an untouched memory address, which held Verilog's unknown
  state (x) rather than a defined value. Comparing against x evaluates to
  x, which an if-statement treats as false, producing a false FAIL. Fixed
  by testing against an address already set to a known value earlier in
  the same test.
- 2026-09-09: Integration. STORE/BEQ initially wrote to the wrong register,
  because the I-type second register role was read from a fixed bit
  position ([6:4]) that's only valid for R-type instructions. Fixed by
  muxing the register file's rt_addr between rd_field (I-type) and
  rt_field (R-type), based on opcode.
- 2026-09-09: Integration. after HALT executed, the PC kept incrementing
  into uninitialized instruction memory, fetching unknown (x) instructions
  that corrupted already-correct results. Fixed by adding a halt signal to
  pc.v that freezes the PC once HALT is decoded.
- 2026-09-09: Integration. SUB R2,R2,R2 (intended to zero the accumulator)
  produced x, not 0, because R2 held Verilog's unknown state at power-up.
  x minus x evaluates to x, not 0. Fixed by adding a reset to
  register_file.v that explicitly clears all 8 registers to 0 at startup,
  rather than relying on program logic to avoid ever using an undefined
  register.
- 2026-09-09: baud_gen testbench Test 1 (first tick after reset) measured
  5209 cycles instead of the expected 5207, while Test 2 (steady-state
  tick-to-tick interval) correctly measured 5207, confirming the module's
  actual behavior is correct.
- 2026-09-09: sc8_top.v instantiated the control unit as "control_unit
  cu_inst", the module's name before it was renamed to "cu". This had been
  silently masked because the Questa work library, never cleared since the
  start of the project, retained a stale compiled "control_unit" definition
  from before the rename, so the mismatch never surfaced. Deleting the work
  library to force a clean rebuild (while debugging an unrelated stale hex
  file issue) exposed it. Fixed by updating the instantiation to "cu cu_inst".
  Both test programs were rerun against the clean build to confirm nothing
  else had been relying on stale cached modules.
