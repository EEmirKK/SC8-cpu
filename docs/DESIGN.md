# SC8 — Single-Cycle 8-Instruction CPU

A custom-designed CPU implementing a self-defined 8-instruction ISA, written in
Verilog and deployed on a DE0-Nano FPGA with memory-mapped UART I/O and onboard
LED status output.

## Architecture Overview

The processor uses a single-cycle design: each instruction completes fetch,
decode, execute, memory access, and writeback within a single clock cycle,
with no overlap between instructions. This avoids the hazard detection,
forwarding, and pipeline register logic required by a pipelined design, at
the cost of clock speed. For this project, correctness and completeness were
prioritised over performance.

## Instruction Set

The ISA consists of eight instructions, selected to demonstrate the core
capabilities expected of a functioning processor: data movement, arithmetic,
logic operations, control flow, and program termination.

| Instruction | Opcode | Format | Operation |
|-------------|--------|--------|-----------|
| LOAD        | 000    | I-type | Rd ← Mem[Rs + offset] |
| STORE       | 001    | I-type | Mem[Rs + offset] ← Rt |
| ADD         | 010    | R-type | Rd ← Rs + Rt |
| SUB         | 011    | R-type | Rd ← Rs − Rt |
| AND         | 100    | R-type | Rd ← Rs & Rt |
| OR          | 101    | R-type | Rd ← Rs \| Rt |
| BEQ         | 110    | I-type | if Rs == Rt, PC ← PC + offset |
| HALT        | 111    | —      | Stop execution |

An unconditional JUMP instruction was considered and excluded: BEQ with a
register compared against itself produces equivalent behaviour, and omitting
JUMP keeps the decode logic smaller.

Dedicated immediate-arithmetic instructions (e.g. ADDI, ANDI, ORI) were also
considered and excluded, to keep the opcode space at eight instructions and
avoid the wider immediate field they would require. Getting a constant value
into a register is still achievable via LOAD from a preloaded memory location;
this costs an extra instruction and temporarily occupies a register, a
trade-off accepted given the small size of the target test program.

A 3-bit opcode field was chosen as the minimum required to encode eight
instructions (2³ = 8), with no unused encoding space.

## Instruction Encoding

Instructions are 16 bits wide. This width accommodates an opcode, register
fields, and a usable offset, while keeping the datapath narrow enough to
remain straightforward to implement and debug. An 8-bit format would not
leave sufficient room for both register fields and an offset; a 32-bit
format was judged unnecessary for an eight-register machine.

Two instruction formats are used:

**R-type** (ADD, SUB, AND, OR)
```
[15:13] opcode | [12:10] Rd | [9:7] Rs | [6:4] Rt | [3:0] unused
```

**I-type** (LOAD, STORE, BEQ)
```
[15:13] opcode | [12:10] Rd/Rt | [9:7] Rs (base/compare) | [6:0] signed offset
```

HALT requires only the opcode field; remaining bits are unused.

### Register Field Width

Register fields are 3 bits wide, providing eight addressable registers (R0–R7).
An earlier version of this design used 2-bit fields (four registers), traded
directly against a wider branch offset. That version was revisited against
reference microarchitecture material (UCL ELEC0004), which uses a similar
single-cycle structure at a larger scale (16 registers, 24-bit instructions).
Rather than adopt that scale wholesale, eight registers was chosen as a
middle point: real headroom over the original four-register design, without
the branch-offset cost of a full-width immediate field, and without departing
from the 16-bit instruction width already established.

R0 is hardwired to always read as the constant 0; writes to R0 are ignored by
the register file. This mirrors the x0 register convention used in RISC-V and
in the ELEC0004 reference material. At only a handful of registers, reserving
one by software convention alone would be fragile (a stray write could
silently corrupt every zero-comparison in a program) and comparatively
expensive (a full register out of a small total). Enforcing it in hardware
removes both risks at the cost of a few lines of logic in the register file.
This also provides a natural way to test for zero (e.g. for loop termination
via BEQ) without a dedicated comparison instruction.

### Why R-type Needs Three Register Fields and I-type Needs Two

R-type instructions (ADD, SUB, AND, OR) read two source registers and write a
third, distinct destination register — three simultaneous register roles are
required. I-type instructions never need three at once: LOAD reads one base
register and writes one destination; STORE reads one base register and one
value register; BEQ reads two registers for comparison and writes none. In
every I-type case, at most two register roles are needed, so the second
field is reused as either a destination (LOAD) or a second source (STORE,
BEQ) depending on the instruction, rather than reserving a dedicated third
field that most I-type instructions would leave unused.

### Offset Width

The I-type offset is 7 bits, signed, giving a range of approximately −64 to
+63 instructions. This is the field width remaining once the opcode and two
3-bit register fields are subtracted from the 16-bit instruction word. This
is narrower than the 9-bit offset available under the earlier four-register
design, a direct trade-off for the wider register fields, but remains
sufficient for the target test program's loop size.

Offsets are relative (PC ← PC + offset) rather than absolute addresses. This
differs from the ELEC0004 reference design, which uses an absolute jump
target. Relative offsets were kept because they allow code to be relocated
in memory without recalculating branch targets, matching the convention used
in RISC-V; this is a deliberate deviation from the reference material rather
than an oversight.

## Instruction Memory

Instruction memory is implemented as a fixed ROM (`reg [15:0] instr_mem
[0:31]`), populated via `$readmemh` or an `initial` block. Test programs are
hand-assembled into hexadecimal rather than produced by a toolchain. This is
a deliberate, disclosed simplification given the project timeline, not an
oversight.

## Output

Program output is observed via two channels: a memory-mapped UART peripheral
transmitting to a connected PC, and onboard LEDs on the DE0-Nano reflecting
processor status (e.g. register values, PC, HALT state). Both were judged
in-scope, as neither requires additional driver logic beyond output pin
assignment.

## Decisions Log

- Verilog was selected over VHDL/SystemVerilog because of prior familiarity
  from the Digital Electronics module, avoiding time lost to relearning
  syntax under a fixed deadline.
- The project is named SC8 (Single-Cycle, 8-instruction).
- Register field width was widened from 2 bits (4 registers) to 3 bits (8
  registers) after comparing the design against UCL ELEC0004 reference
  microarchitecture material, trading branch offset range for register
  headroom. See "Register Field Width" above.
- R0 was hardwired to the constant 0, following the same convention used in
  RISC-V and in the ELEC0004 reference material. See "Register Field Width"
  above.

## Deferred to a Later Phase

The following were considered and deliberately excluded from the initial
build, to be revisited once the core CPU is complete and any related
application has been submitted:

- **Minimal assembler** (mnemonic → hex, written in Python). Would
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

## Debugging Log

(Entries to be added during development: what failed, what was initially
suspected, and the actual root cause.)
