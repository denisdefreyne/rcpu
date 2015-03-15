require "sdl2"

class Registers
  def initialize
    @reg = {
      0_u8  => 0_u32,      # r0
      1_u8  => 0_u32,      # r1
      2_u8  => 0_u32,      # r2
      3_u8  => 0_u32,      # r3
      4_u8  => 0_u32,      # r4
      5_u8  => 0_u32,      # r5
      6_u8  => 0_u32,      # r6
      7_u8  => 0_u32,      # r7
      8_u8  => 0_u32,      # rpc
      9_u8  => 0_u32,      # rflags
      10_u8 => 0xffff_u32, # rsp
      11_u8 => 0_u32,      # rbp
      12_u8 => 0_u32,      # rr
    }
  end

  def [](num)
    @reg.fetch(num)
  end

  def []=(num, value)
    unless @reg.has_key?(num)
      raise "Unknown register: #{num}"
    end

    @reg[num] = value
  end

  def each
    @reg.each { |r| yield(r) }
  end
end

class Mem
  def initialize
    @wrapped = {} of UInt32 => UInt8
  end

  def [](address)
    @wrapped[address]
  end

  def fetch(address)
    @wrapped.fetch(address)
  end

  def []=(address, value)
    @wrapped[address] = value
  end
end

class Context
  getter reg
  getter mem
  setter mem

  def initialize
    @mem = Mem.new
    @reg = Registers.new
  end

  def inspect
    # TODO: re-enable (#format)

    # mem = String.build do |io|
    #   stride = 10
    #   i = 0
    #   prev_key = nil
    #   @mem.keys.sort.each do |key|
    #     # Split
    #     if prev_key && prev_key + 1 != key
    #       io << "\n" << "----" << "\n"
    #       i = 0
    #     end
    #     prev_key = key

    #     io << format("%04x=%02x ", key, @mem[key])

    #     io << "\n" if i % stride == stride - 1
    #     i += 1
    #   end
    # end

    # reg = String.build do |io|
    #   io << "┌─────┬───────────┬────────────┐" << "\n"
    #   io << "│ loc │ val (hex) │ val (dec)  │" << "\n"
    #   io << "├─────┼───────────┼────────────┤" << "\n"
    #   @reg.each do |loc, val|
    #     io << "│ "
    #     io << format("%3i", loc)
    #     io << " │ "
    #     io << format(" %8x", val)
    #     io << " │ "
    #     io << format("%10i", val)
    #     io << " │" << "\n"
    #   end
    #   io << "└─────┴───────────┴────────────┘" << "\n"
    # end

    # mem + "\n" + reg
    ""
  end
end

class CPU
  # TODO: move these elsewhere
  PC    = 8_u8
  FLAGS = 9_u8
  SP    = 10_u8
  BP    = 11_u8

  getter running

  def initialize(context)
    @context = context
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

  private def mem
    @context.mem
  end

  private def reg
    @context.reg
  end

  private def step
    opcode = read_byte

    debug_count = ARGV.count { |a| a == "--debug" }
    if debug_count >= 2
      puts @context.inspect
    end
    if debug_count >= 1
      # puts "*** #{format("0x%02x", opcode)} @ #{format("0x%08x", reg[PC])}"
      puts "*** #{opcode} (0x#{opcode.to_s(16)}) @ #{reg[PC]-1}"
    end

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

context = Context.new

# Read instructions into memory
# FIXME: use proper option parser
filename = ARGV.reject { |a| a =~ /\A--/ }.first
bytes = [] of UInt8
File.open(filename, "r") do |io|
  loop do
    byte = io.read_byte
    if byte
      bytes << byte
    else
      break
    end
  end
end
bytes.each_with_index do |byte, index|
  context.mem[index.to_u32] = byte
end

# Set video memory
160.times do |x|
  120.times do |y|
    index = 0x10000 + (x * 120 + y)
    context.mem[index.to_u32] = 0_u8
  end
end

require "./video"

# Run

def get_input
  while LibSDL2.poll_event(out e) == 1
    case e.type
    when EventType::QUIT
      return :quit
    end
  end
  return :none
end

if ARGV.find { |a| a == "--video" }
  cpu = CPU.new(context)
  video = Video.new(context.mem)
  video.draw do |g|
    loop do
      case get_input
      when :quit
        break
      end

      cpu.run(40)
      video.update(g)
      break unless cpu.running
    end
  end
else
  CPU.new(context).run
end
