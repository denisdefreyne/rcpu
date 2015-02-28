# encoding: utf-8

class Context
  attr_reader :reg
  attr_accessor :mem

  def initialize
    @reg = {
      0 => 0, # r0
      1 => 0, # r1
      2 => 0, # r2
      3 => 0, # r3
      4 => 0, # r4
      5 => 0, # r5
      6 => 0, # r6
      7 => 0, # r7
      8 => 0, # pc
    }
    @mem = []
  end

  def inspect
    mem = ''
    @mem.each.with_index do |val, idx|
      mem << format('%02x', val)
      if idx % 8 == 7
        mem << "\n"
      elsif idx % 2 == 1
        mem << ' '
      end
    end

    reg = ''
    reg << '┌─────┬───────────┬───────────┐' << "\n"
    reg << '│ loc │ val (hex) │ val (dec) │' << "\n"
    reg << '├─────┼───────────┼───────────┤' << "\n"
    @reg.each do |loc, val|
      reg << '│ '
      reg << format('%3i', loc)
      reg << ' │ '
      reg << '     0x' << format('%02x', val)
      reg << ' │ '
      reg << '      ' << format('%3i', val)
      reg << ' │' << "\n"
    end
    reg << '└─────┴───────────┴───────────┘' << "\n"

    [mem, reg].join("\n")
  end
end

class CPU
  class HaltException < StandardError
  end

  def initialize(context)
    @context = context
  end

  def run
    loop do
      begin
        step
      rescue HaltException
        break
      end
    end
  end

  def mem
    @context.mem
  end

  def reg
    @context.reg
  end

  PC = 8

  def step
    puts @context.inspect
    opcode = mem[reg[PC]]
    puts "Opcode #{opcode.inspect}"

    case opcode
    when 0 # nop
      reg[PC] += 1
    when 1 # addi reg, imm
      r = mem[reg[PC] + 1]
      i = mem[reg[PC] + 2]
      reg[r] += i
      reg[PC] += 3
    when 2 # mod reg, reg
      r1 = mem[reg[PC] + 1]
      r2 = mem[reg[PC] + 2]
      reg[r1] = reg[r1] % reg[r2]
      reg[PC] += 3
    when 3 # mov reg, reg
      r1 = mem[reg[PC] + 1]
      r2 = mem[reg[PC] + 2]
      reg[r1] = reg[r2]
      reg[PC] += 3
    when 4 # jrz reg, imm
      r = mem[reg[PC] + 1]
      i = mem[reg[PC] + 2]
      if reg[r] == 0
        reg[PC] += i
      else
        reg[PC] += 3
      end
    when 5 # movi reg, imm
      r = mem[reg[PC] + 1]
      i = mem[reg[PC] + 2]
      reg[r] = i
      reg[PC] += 3
    when 6 # jrb imm
      i = mem[reg[PC] + 1]
      reg[PC] -= i
    when 7 # halt
      raise HaltException
    when 8 # mod2 reg, reg, reg
      r1 = mem[reg[PC] + 1]
      r2 = mem[reg[PC] + 2]
      r3 = mem[reg[PC] + 3]
      reg[r1] = reg[r2] % reg[r3]
      reg[PC] += 4
    else
      raise "Unknown opcode: #{@opcode.inspect}"
    end
  end

  def pc(offset=0)
    mem[reg[PC] + offset]
  end
end

# Run
context = Context.new
context.mem = File.read(ARGV[0]).unpack('C*')
CPU.new(context).run
