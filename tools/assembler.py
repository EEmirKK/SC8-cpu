"""
SC8 Assembler: Converts SC8 assembly mnemonics into 16-bit hex machine code.

Encoding reference (see DESIGN.md):
  R-type: [15:13] opcode | [12:10] Rd | [9:7] Rs | [6:4] Rt | [3:0] unused
  I-type: [15:13] opcode | [12:10] Rd/Rt | [9:7] Rs | [6:0] signed offset
"""

# Opcode and format for each instruction
OPCODES = {
    "LOAD":  ("000", "I"),
    "STORE": ("001", "I"),
    "ADD":   ("010", "R"),
    "SUB":   ("011", "R"),
    "AND":   ("100", "R"),
    "OR":    ("101", "R"),
    "BEQ":   ("110", "I"),
    "HALT":  ("111", "N"),  # N = no operands
}

def parse_register(token):
    """Convert 'R3' into '011' (3-bit binary string)."""
    token = token.strip().rstrip(",")
    if not token.startswith("R"):
        raise ValueError(f"Expected a register like 'R3', got '{token}'")
    reg_num = int(token[1:])
    if not (0 <= reg_num <= 7):
        raise ValueError(f"Register number out of range (0-7): {token}")
    return format(reg_num, "03b")

def parse_offset(token, bits=7):
    """Convert a decimal offset (e.g. '-5' or '31') into a signed
    two's-complement binary string of the given bit width."""
    value = int(token.strip())
    min_val = -(2 ** (bits - 1))
    max_val = (2 ** (bits - 1)) - 1
    if not (min_val <= value <= max_val):
        raise ValueError(f"Offset {value} out of range [{min_val}, {max_val}] for {bits} bits")
    if value < 0:
        value = (1 << bits) + value  # two's-complement conversion
    return format(value, f"0{bits}b")

def assemble_line(line):
    """Assemble one line of SC8 assembly into a 4-digit hex string."""
    line = line.split("#")[0].strip()   # strip comments and whitespace
    if not line:
        return None   # blank or comment-only line, nothing to assemble

    parts = line.replace(",", " ").split()
    mnemonic = parts[0].upper()
    operands = parts[1:]

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    opcode, fmt = OPCODES[mnemonic]

    if fmt == "N":   # HALT: no operands at all
        bits = opcode + "0" * 13

    elif fmt == "R":   # ADD/SUB/AND/OR: Rd, Rs, Rt
        rd = parse_register(operands[0])
        rs = parse_register(operands[1])
        rt = parse_register(operands[2])
        bits = opcode + rd + rs + rt + "0000"

    elif fmt == "I":
        if mnemonic == "BEQ":
            # BEQ Rs, Rt, offset -- operand order is reversed vs LOAD/STORE:
            # first operand is Rs, second is the Rd/Rt-shared field.
            rs = parse_register(operands[0])
            rd_rt = parse_register(operands[1])
        else:
            # LOAD Rd, Rs, offset / STORE Rt, Rs, offset
            rd_rt = parse_register(operands[0])
            rs = parse_register(operands[1])
        offset = parse_offset(operands[2])
        bits = opcode + rd_rt + rs + offset
        
    hex_str = format(int(bits, 2), "04X")
    return hex_str

def assemble_file(input_path, output_path):
    """Assemble a whole .asm file into a .hex file, one instruction per line."""
    with open(input_path, "r") as f:
        lines = f.readlines()

    hex_lines = []
    for line_num, line in enumerate(lines, start=1):
        try:
            hex_code = assemble_line(line)
        except ValueError as e:
            print(f"Error on line {line_num}: {e}")
            raise
        if hex_code is not None:
            hex_lines.append(hex_code)

    with open(output_path, "w") as f:
        for hex_code in hex_lines:
            f.write(hex_code + "\n")

    print(f"Assembled {len(hex_lines)} instructions -> {output_path}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input.asm> <output.hex>")
        sys.exit(1)
    assemble_file(sys.argv[1], sys.argv[2])