class CPU
  getter running
  getter reg
  getter mem
  setter mem

  O_CALL  = 0x01_u8
  O_CALLI = 0x02_u8
  O_RET   = 0x03_u8
  O_PUSH  = 0x04_u8
  O_PUSHI = 0x05_u8
  O_POP   = 0x06_u8
  O_J     = 0x07_u8
  O_JI    = 0x08_u8
  O_JE    = 0x09_u8
  O_JEI   = 0x0a_u8
  O_JNE   = 0x0b_u8
  O_JNEI  = 0x0c_u8
  O_JG    = 0x0d_u8
  O_JGI   = 0x0e_u8
  O_JGE   = 0x0f_u8
  O_JGEI  = 0x10_u8
  O_JL    = 0x11_u8
  O_JLI   = 0x12_u8
  O_JLE   = 0x13_u8
  O_JLEI  = 0x14_u8
  O_CMP   = 0x15_u8
  O_CMPI  = 0x16_u8
  O_MOD   = 0x17_u8
  O_MODI  = 0x18_u8
  O_ADD   = 0x19_u8
  O_ADDI  = 0x1a_u8
  O_SUB   = 0x1b_u8
  O_SUBI  = 0x1c_u8
  O_MUL   = 0x1d_u8
  O_MULI  = 0x1e_u8
  O_DIV   = 0x1f_u8
  O_DIVI  = 0x20_u8
  O_XOR   = 0x21_u8
  O_XORI  = 0x22_u8
  O_OR    = 0x23_u8
  O_ORI   = 0x24_u8
  O_AND   = 0x25_u8
  O_ANDI  = 0x26_u8
  O_SHL   = 0x27_u8
  O_SHLI  = 0x28_u8
  O_SHR   = 0x29_u8
  O_SHRI  = 0x2a_u8
  O_NOT   = 0x2b_u8
  O_MOV   = 0x2c_u8
  O_LI    = 0x2d_u8
  O_LW    = 0x2e_u8
  O_LH    = 0x2f_u8
  O_LB    = 0x30_u8
  O_SW    = 0x31_u8
  O_SH    = 0x32_u8
  O_SB    = 0x33_u8
  O_PRN   = 0xfe_u8
  O_HALT  = 0xff_u8

  class OpcodeNotSupportedException < Exception
  end

  class InvalidOpcodeException < Exception
  end

  def initialize(mem)
    @reg = Reg.new
    @mem = mem
    @running = true
  end

  def run(cycles = -1)
    return unless @running

    if cycles == -1
      loop do
        step
        break unless @running
      end
    else
      cycles.times do
        step
        break unless @running
      end
    end
  end

  def step
    opcode = read_byte

    case opcode
    # --- FUNCTION HANDLING ---
    when O_CALL
      new_pc = reg[Reg::RPC] + 1
      push(new_pc)
      a0 = read_byte
      reg[Reg::RPC] = reg[a0]
    when O_CALLI
      new_pc = reg[Reg::RPC] + 4
      push(new_pc)
      i = read_u32
      reg[Reg::RPC] = i
    when O_RET
      reg[Reg::RPC] = pop
    # --- STACK MANAGEMENT ---
    when O_PUSH
      a0 = read_byte
      raw = reg[a0]
      push(raw)
    when O_PUSHI
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      a3 = read_byte
      push(a0, a1, a2, a3)
    when O_POP
      a0 = read_byte
      reg[a0] = pop
    # --- BRANCHING ---
    when O_J
      a0 = read_byte
      reg[Reg::RPC] = reg[a0]
    when O_JI
      i = read_u32
      reg[Reg::RPC] = i
    when O_JE
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JEI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x01 == 0x01
    when O_JNE
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JNEI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x01 == 0x00
    when O_JG
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JGI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x02 == 0x02
    when O_JGE
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JGEI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x03 != 0x00
    when O_JL
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JLI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x03 == 0x00
    when O_JLE
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_JLEI
      i = read_u32
      reg[Reg::RPC] = i if reg[Reg::RFLAGS] & 0x02 == 0x00
    # --- ARITHMETIC ---
    when O_CMP
      a0 = read_byte
      a1 = read_byte
      cmp(reg[a0], reg[a1])
    when O_CMPI
      a0 = read_byte
      i = read_u32
      cmp(reg[a0], i)
    when O_MOD
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = reg[a1] % reg[a2]
    when O_MODI
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = reg[a1] % i
    when O_ADD
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = (reg[a1] + reg[a2])
    when O_ADDI
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] + i)
    when O_SUB
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SUBI
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] - i)
    when O_MUL
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_MULI
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] * i)
    when O_DIV
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_DIVI
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_XOR
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_XORI
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_OR
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_ORI
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_AND
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_ANDI
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SHL
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SHLI
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SHR
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SHRI
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] >> i)
    when O_NOT
      raise OpcodeNotSupportedException.new(opcode.inspect)
    # --- REGISTER HANDLING ---
    when O_MOV
      a0 = read_byte
      a1 = read_byte
      reg[a0] = reg[a1]
    when O_LI
      a0 = read_byte
      a1 = read_u32
      reg[a0] = a1
    # --- MEMORY HANDLING ---
    when O_LW
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 24) |
        (mem[address + 1].to_u32 << 16) |
        (mem[address + 2].to_u32 << 8)  |
        (mem[address + 3].to_u32 << 0)
    when O_LH
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 8)  |
        (mem[address + 1].to_u32 << 0)
    when O_LB
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 0)
    when O_SW
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SH
      raise OpcodeNotSupportedException.new(opcode.inspect)
    when O_SB
      a0 = read_byte
      a1 = read_byte
      raw = reg[a1]
      mem[reg[a0] + 0] = ((raw & 0x000000ff)).to_u8
    # --- SPECIAL ---
    when O_PRN
      a0 = read_byte
      puts "#{reg[a0]}"
    when O_HALT
      @running = false
      advance(-1)
    else
      raise InvalidOpcodeException.new(opcode.inspect)
    end
  end

  private def push(int)
    push(
      ((int & 0xff000000) >> 24).to_u8,
      ((int & 0x00ff0000) >> 16).to_u8,
      ((int & 0x0000ff00) >> 8).to_u8,
      ((int & 0x000000ff)).to_u8,
    )
  end

  private def push(a, b, c, d)
    reg[Reg::RSP] -= 4_u32
    mem[reg[Reg::RSP] + 0] = a
    mem[reg[Reg::RSP] + 1] = b
    mem[reg[Reg::RSP] + 2] = c
    mem[reg[Reg::RSP] + 3] = d
  end

  private def pop
    reconstruct_int(
      mem.fetch(reg[Reg::RSP] + 0),
      mem.fetch(reg[Reg::RSP] + 1),
      mem.fetch(reg[Reg::RSP] + 2),
      mem.fetch(reg[Reg::RSP] + 3)
    ).tap do
      reg[Reg::RSP] += 4
    end
  end

  private def cmp(a, b)
    reg[Reg::RFLAGS] =
      (a == b ? 0x01_u32 : 0x00_u32) |
      (a > b  ? 0x02_u32 : 0x00_u32)
  end

  private def advance(amount)
    reg[Reg::RPC] += amount
  end

  private def read_byte
    mem[reg[Reg::RPC]].tap { advance(1) }
  end

  private def read_u32
    reconstruct_int(read_byte, read_byte, read_byte, read_byte)
  end

  private def reconstruct_int(x, y, z, t)
    (x.to_u32 << 24) + (y.to_u32 << 16) + (z.to_u32 << 8) + t.to_u32
  end
end
