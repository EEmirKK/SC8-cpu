# SC8 — Single-Cycle 8-Instruction CPU

A custom-designed CPU built from scratch in Verilog, implementing a
self-defined 8-instruction ISA, and deployed on a DE0-Nano FPGA (Cyclone IV)
with UART serial output.

## Overview

- **8 instructions**: LOAD, STORE, ADD, SUB, AND, OR, BEQ, HALT
- **8 general-purpose registers** (R0 hardwired to 0), 16-bit datapath
- **16-bit fixed-width instructions**, two formats (R-type / I-type)
- **Single-cycle** design: each instruction completes fetch through
  writeback in one clock cycle
- **UART transmit** over a memory-mapped address, so a program can send a
  result out over serial with a plain STORE
- **Deployed and verified on real hardware** (DE0-Nano)

Every design decision, the full instruction encoding, and a real debugging
log covering both simulation and hardware bugs are documented in
[`DESIGN.md`](docs/DESIGN.md).

## Repository structure

```
rtl/          Verilog source for every module (register file, ALU, PC,
              instruction/data memory, control unit, UART transmitter,
              baud rate generator, top-level datapath)
sim/          Testbenches for every module, plus two full end-to-end
              test programs run through the complete CPU
quartus/      Quartus project files and pin assignments for the DE0-Nano
tools/        A minimal Python assembler (mnemonics -> hex), verified
              byte-for-byte against the hand-encoded test programs
docs/         DESIGN.md -- full architecture, reasoning, and debugging log
*.hex         Hand-encoded and assembler-generated test programs and data
```

## Building and simulating

Simulation uses Questa. From the project root:

```
vlib work
vlog rtl/register_file.v rtl/alu.v rtl/instr_mem.v rtl/pc.v rtl/data_mem.v \
     rtl/cu.v rtl/baud_gen.v rtl/uart_tx.v rtl/sc8_top.v sim/sc8_top_tb.v
vsim sc8_top_tb
run -all
```

A second test program (`program2.hex` / `data2.hex`, covering AND, OR, a
not-taken branch, and a non-zero-base LOAD/STORE round trip) can be run the
same way with `sim/sc8_top_tb2.v`.

To generate hex from assembly instead of hand-encoding it:
```
python tools/assembler.py tools/program.asm tools/program.hex
```

Hardware deployment uses Quartus Prime Lite (Cyclone IV, EP4CE22F17C6),
programming over USB to a DE0-Nano.

## Why a custom ISA

SC8 is a self-designed ISA rather than a RISC-V subset. Every field width,
register count, and instruction was chosen deliberately and is documented
with its reasoning and trade-offs in DESIGN.md, rather than inherited from
an existing spec. See DESIGN.md's Instruction Set and Instruction Encoding
sections for the full reasoning.
