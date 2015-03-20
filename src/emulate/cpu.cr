class CPU
  # TODO: move these elsewhere
  PC    = 8_u8
  FLAGS = 9_u8
  SP    = 10_u8
  BP    = 11_u8

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

  private def step
    opcode = read_byte

    case opcode
    when 0x01 # call
      reg[SP] -= 4_u32
      new_pc = reg[PC] + 4
      mem[reg[SP] + 0] = ((new_pc & 0xff000000) >> 24).to_u8
      mem[reg[SP] + 1] = ((new_pc & 0x00ff0000) >> 16).to_u8
      mem[reg[SP] + 2] = ((new_pc & 0x0000ff00) >> 8).to_u8
      mem[reg[SP] + 3] = ((new_pc & 0x000000ff)).to_u8
      i = read_u32
      reg[PC] = i
    when 0x02 # ret
      i = reconstruct_int(
        mem.fetch(reg[SP] + 0),
        mem.fetch(reg[SP] + 1),
        mem.fetch(reg[SP] + 2),
        mem.fetch(reg[SP] + 3)
      )
      reg[SP] += 4
      reg[PC] = i
    when 0x03 # push
      a0 = read_byte
      raw = reg[a0]
      reg[SP] -= 4
      mem[reg[SP] + 0] = ((raw & 0xff000000) >> 24).to_u8
      mem[reg[SP] + 1] = ((raw & 0x00ff0000) >> 16).to_u8
      mem[reg[SP] + 2] = ((raw & 0x0000ff00) >> 8).to_u8
      mem[reg[SP] + 3] = ((raw & 0x000000ff)).to_u8
    when 0x04 # pushi
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      a3 = read_byte
      reg[SP] -= 4_u32
      mem[reg[SP] + 0] = a0
      mem[reg[SP] + 1] = a1
      mem[reg[SP] + 2] = a2
      mem[reg[SP] + 3] = a3
    when 0x05 # pop
      a0 = read_byte
      reg[a0] = reconstruct_int(
        mem.fetch(reg[SP] + 0),
        mem.fetch(reg[SP] + 1),
        mem.fetch(reg[SP] + 2),
        mem.fetch(reg[SP] + 3)
      )
      reg[SP] += 4
    when 0x06 # jmpi
      i = read_u32
      reg[PC] = i
    when 0xa6 # jmp
      a0 = read_byte
      reg[PC] = reg[a0]
    when 0x07 # je
      i = read_u32
      if reg[FLAGS] & 0x01 == 0x01
        reg[PC] = i
      end
    when 0x08 # jne
      i = read_u32
      if reg[FLAGS] & 0x01 == 0x00
        reg[PC] = i
      end
    when 0x09 # jg
      i = read_u32
      if reg[FLAGS] & 0x02 == 0x02
        reg[PC] = i
      end
    when 0x0a # jge
      i = read_u32
      if reg[FLAGS] & 0x03 != 0x00
        reg[PC] = i
      end
    when 0x0b # jl
      i = read_u32
      if reg[FLAGS] & 0x03 == 0x00
        reg[PC] = i
      end
    when 0x0c # jle
      i = read_u32
      if reg[FLAGS] & 0x02 == 0x00
        reg[PC] = i
      end
    when 0x0d # not
    when 0x0e # prn
      a0 = read_byte
      puts "#{reg[a0]}"
    when 0x11 # cmp
      a0 = read_byte
      a1 = read_byte
      reg[FLAGS] =
        (reg[a0] == reg[a1] ? 0x01_u32 : 0x00_u32) |
        (reg[a0] > reg[a1]  ? 0x02_u32 : 0x00_u32)
    when 0x12 # cmpi
      a0 = read_byte
      i = read_u32
      reg[FLAGS] =
        (reg[a0] == i ? 0x01_u32 : 0x00_u32) |
        (reg[a0] > i  ? 0x02_u32 : 0x00_u32)
    when 0x13 # mod
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = reg[a1] % reg[a2]
    when 0x14 # modi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = reg[a1] % i
    when 0x15 # add
      a0 = read_byte
      a1 = read_byte
      a2 = read_byte
      reg[a0] = (reg[a1] + reg[a2])
    when 0x16 # addi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] + i)
    when 0x17 # sub
    when 0x18 # subi
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] - i)
    when 0x19 # mul
    when 0x1a # muli
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] * i)
    when 0x1b # div
    when 0x1c # divi
    when 0x1d # xor
    when 0x1e # xori
    when 0x1f # or
    when 0x20 # ori
    when 0x21 # and
    when 0x22 # andi
    when 0x23 # shl
    when 0x24 # shli
    when 0x25 # shr
    when 0x26 # shri
      a0 = read_byte
      a1 = read_byte
      i = read_u32
      reg[a0] = (reg[a1] >> i)
    when 0x27 # li
      a0 = read_byte
      a1 = read_u32
      reg[a0] = a1
    when 0x28 # lw
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 24) |
        (mem[address + 1].to_u32 << 16) |
        (mem[address + 2].to_u32 << 8)  |
        (mem[address + 3].to_u32 << 0)
    when 0x29 # lh
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 8)  |
        (mem[address + 1].to_u32 << 0)
    when 0x2a # lb
      a0 = read_byte
      a1 = read_byte
      address = reg[a1]
      reg[a0] =
        (mem[address + 0].to_u32 << 0)
    when 0x2b # sw
      raise "broken"
      # TODO: fixme
      # raw = reg[a1]
      # mem[reg[a0] + 0] = ((raw & 0xff000000) >> 24).to_u8
      # mem[reg[a0] + 1] = ((raw & 0x00ff0000) >> 16).to_u8
      # mem[reg[a0] + 2] = ((raw & 0x0000ff00) >> 8).to_u8
      # mem[reg[a0] + 3] = ((raw & 0x000000ff)).to_u8
      # advance(3)
    when 0x2c # sh
      raise "broken"
      # TODO: fixme
      # raw = reg[a1]
      # mem[reg[a0] + 0] = ((raw & 0x0000ff00) >> 8).to_u8
      # mem[reg[a0] + 1] = ((raw & 0x000000ff)).to_u8
      # advance(3)
    when 0x2d # sb
      a0 = read_byte
      a1 = read_byte
      raw = reg[a1]
      mem[reg[a0] + 0] = ((raw & 0x000000ff)).to_u8
    when 0xff # halt
      @running = false
      advance(-1)
    else
      raise "Unknown opcode: #{@opcode.inspect}"
    end
  end

  def advance(amount)
    reg[PC] += amount
  end

  def read_byte
    mem[reg[PC]].tap { advance(1) }
  end

  def read_u32
    reconstruct_int(read_byte, read_byte, read_byte, read_byte)
  end

  def reconstruct_int(x, y, z, t)
    (x.to_u32 << 24) + (y.to_u32 << 16) + (z.to_u32 << 8) + t.to_u32
  end
end
