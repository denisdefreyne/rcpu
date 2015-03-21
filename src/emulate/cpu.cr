class CPU
  getter running
  getter reg
  getter mem
  setter mem

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
    when 0x01 # call
      # TODO: implement
    when 0x02 # calli
      reg[Reg::SP] -= 4_u32
      new_pc = reg[Reg::PC] + 4
      mem[reg[Reg::SP] + 0] = ((new_pc & 0xff000000) >> 24).to_u8
      mem[reg[Reg::SP] + 1] = ((new_pc & 0x00ff0000) >> 16).to_u8
      mem[reg[Reg::SP] + 2] = ((new_pc & 0x0000ff00) >> 8).to_u8
      mem[reg[Reg::SP] + 3] = ((new_pc & 0x000000ff)).to_u8
      i = read_u32
      reg[Reg::PC] = i
    when 0x03 # ret
      i = reconstruct_int(
        mem.fetch(reg[Reg::SP] + 0),
        mem.fetch(reg[Reg::SP] + 1),
        mem.fetch(reg[Reg::SP] + 2),
        mem.fetch(reg[Reg::SP] + 3)
      )
      reg[Reg::SP] += 4
      reg[Reg::PC] = i
    # --- STACK MANAGEMENT ---
    when 0x04 # push
      a0 = read_byte
      raw = reg[a0]
      reg[Reg::SP] -= 4
      mem[reg[Reg::SP] + 0] = ((raw & 0xff000000) >> 24).to_u8
      mem[reg[Reg::SP] + 1] = ((raw & 0x00ff0000) >> 16).to_u8
      mem[reg[Reg::SP] + 2] = ((raw & 0x0000ff00) >> 8).to_u8
      mem[reg[Reg::SP] + 3] = ((raw & 0x000000ff)).to_u8
    when 0x05 # pushi
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      a3 = read_byte
      reg[Reg::SP] -= 4_u32
      mem[reg[Reg::SP] + 0] = a0
      mem[reg[Reg::SP] + 1] = a1
      mem[reg[Reg::SP] + 2] = a2
      mem[reg[Reg::SP] + 3] = a3
    when 0x06 # pop
      a0 = read_byte
      reg[a0] = reconstruct_int(
        mem.fetch(reg[Reg::SP] + 0),
        mem.fetch(reg[Reg::SP] + 1),
        mem.fetch(reg[Reg::SP] + 2),
        mem.fetch(reg[Reg::SP] + 3)
      )
      reg[Reg::SP] += 4
    # --- BRANCHING ---
    when 0x07 # j
      a0 = read_byte
      reg[Reg::PC] = reg[a0]
    when 0x08 # ji
      i = read_u32
      reg[Reg::PC] = i
    when 0x09 # je
      # TODO: implement
    when 0x0a # jei
      i = read_u32
      if reg[Reg::FLAGS] & 0x01 == 0x01
        reg[Reg::PC] = i
      end
    when 0x0b # jne
      # TODO: implement
    when 0x0c # jnei
      i = read_u32
      if reg[Reg::FLAGS] & 0x01 == 0x00
        reg[Reg::PC] = i
      end
    when 0x0d # jg
      # TODO: implement
    when 0x0e # jgi
      i = read_u32
      if reg[Reg::FLAGS] & 0x02 == 0x02
        reg[Reg::PC] = i
      end
    when 0x0f # jge
      # TODO: implement
    when 0x10 # jgei
      i = read_u32
      if reg[Reg::FLAGS] & 0x03 != 0x00
        reg[Reg::PC] = i
      end
    when 0x11 # jl
      # TODO: implement
    when 0x12 # jli
      i = read_u32
      if reg[Reg::FLAGS] & 0x03 == 0x00
        reg[Reg::PC] = i
      end
    when 0x13 # jle
      # TODO: implement
    when 0x14 # jlei
      i = read_u32
      if reg[Reg::FLAGS] & 0x02 == 0x00
        reg[Reg::PC] = i
      end
    # --- ARITHMETIC ---
    when 0x15 # cmp
      a0 = read_byte
      a1 = read_byte
      reg[Reg::FLAGS] =
        (reg[a0] == reg[a1] ? 0x01_u32 : 0x00_u32) |
        (reg[a0] > reg[a1]  ? 0x02_u32 : 0x00_u32)
    when 0x16 # cmpi
      a0 = read_byte
      i = read_u32
      reg[Reg::FLAGS] =
        (reg[a0] == i ? 0x01_u32 : 0x00_u32) |
        (reg[a0] > i  ? 0x02_u32 : 0x00_u32)
    when 0x17 # mod
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = reg[a1] % reg[a2]
    when 0x18 # modi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = reg[a1] % i
    when 0x19 # add
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = (reg[a1] + reg[a2])
    when 0x1a # addi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] + i)
    when 0x1b # sub
    when 0x1c # subi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] - i)
    when 0x1d # mul
    when 0x1e # muli
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] * i)
    when 0x1f # div
    when 0x20 # divi
    when 0x21 # xor
    when 0x22 # xori
    when 0x23 # or
    when 0x24 # ori
    when 0x25 # and
    when 0x26 # andi
    when 0x27 # shl
    when 0x28 # shli
    when 0x29 # shr
    when 0x2a # shri
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] >> i)
    when 0x2b # not
      # TODO: iplement
    # --- REGISTER HANDLING ---
    when 0x2c # mov
      # TODO: implement
    when 0x2d # li
      a0 = read_byte
      a1 = read_u32
      reg[a0] = a1
    # --- MEMORY HANDLING ---
    when 0x2e # lw
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 24) |
        (mem[address + 1].to_u32 << 16) |
        (mem[address + 2].to_u32 << 8)  |
        (mem[address + 3].to_u32 << 0)
    when 0x2f # lh
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 8)  |
        (mem[address + 1].to_u32 << 0)
    when 0x30 # lb
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 0)
    when 0x31 # sw
      # TODO: implement
    when 0x32 # sh
      # TODO: implement
    when 0x33 # sb
      a0 = read_byte
      a1 = read_byte
      raw = reg[a1]
      mem[reg[a0] + 0] = ((raw & 0x000000ff)).to_u8
    # --- SPECIAL ---
    when 0xfe # prn
      a0 = read_byte
      puts "#{reg[a0]}"
    when 0xff # halt
      @running = false
      advance(-1)
    else
      raise "Unknown opcode: #{@opcode.inspect}"
    end
  end

  def advance(amount)
    reg[Reg::PC] += amount
  end

  def read_byte
    mem[reg[Reg::PC]].tap { advance(1) }
  end

  def read_u32
    reconstruct_int(read_byte, read_byte, read_byte, read_byte)
  end

  def reconstruct_int(x, y, z, t)
    (x.to_u32 << 24) + (y.to_u32 << 16) + (z.to_u32 << 8) + t.to_u32
  end
end
