require "spec"

require "../../../src/emulate/cpu"
require "../../../src/emulate/mem"
require "../../../src/emulate/reg"

macro stack_pointer
  cpu.reg[Reg::RSP]
end

macro program_counter
  cpu.reg[Reg::RPC]
end

describe CPU do

  describe "initial CPU state" do
    mem = Mem.new
    cpu = CPU.new(mem)

    program_counter.should eq(0x0)
    stack_pointer.should eq(0xffff)
  end

  describe "call" do
    it "pushes the return address and jumps" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CALL
      mem[1_u32] = Reg::R3

      cpu = CPU.new(mem)
      cpu.reg[Reg::R3] = 0x10204080_u32

      cpu.step
      program_counter.should eq(0x10204080)
      stack_pointer.should eq(0xfffb)
    end
  end

  describe "calli" do
    it "pushes the return address and jumps" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CALLI
      mem[1_u32] = 1_u8
      mem[2_u32] = 2_u8
      mem[3_u32] = 3_u8
      mem[4_u32] = 4_u8

      cpu = CPU.new(mem)

      cpu.step
      program_counter.should eq(0x01020304)
      stack_pointer.should eq(0xfffb)
    end
  end

  describe "ret" do
    it "pops the return address and jumps" do
      mem = Mem.new
      mem[0_u32] = CPU::O_RET
      mem[0xfffc_u32] = 5_u8
      mem[0xfffd_u32] = 6_u8
      mem[0xfffe_u32] = 7_u8
      mem[0xffff_u32] = 8_u8

      cpu = CPU.new(mem)
      cpu.reg[Reg::RSP] = 0xfffc_u32

      cpu.step
      program_counter.should eq(0x05060708)
      stack_pointer.should eq(0xffff_u32 + 0x01_u32)
    end
  end

  describe "push" do
    it "advances RSP and stores the value at the given register" do
      mem = Mem.new
      mem[0x00_u32] = CPU::O_PUSH
      mem[0x01_u32] = Reg::R6

      cpu = CPU.new(mem)
      cpu.reg[Reg::R6] = 0x05060708_u32

      cpu.step
      program_counter.should eq(0x02)
      stack_pointer.should eq(0xfffb_u32)
      mem[0xfffb_u32].should eq(5_u8)
      mem[0xfffc_u32].should eq(6_u8)
      mem[0xfffd_u32].should eq(7_u8)
      mem[0xfffe_u32].should eq(8_u8)
    end
  end

  describe "pushi" do
    it "advances RSP and stores the immediate value" do
      mem = Mem.new
      mem[0x00_u32] = CPU::O_PUSHI
      mem[0x01_u32] = 5_u8
      mem[0x02_u32] = 6_u8
      mem[0x03_u32] = 7_u8
      mem[0x04_u32] = 8_u8

      cpu = CPU.new(mem)

      cpu.step
      program_counter.should eq(0x05)
      stack_pointer.should eq(0xfffb_u32)
      mem[0xfffb_u32].should eq(5_u8)
      mem[0xfffc_u32].should eq(6_u8)
      mem[0xfffd_u32].should eq(7_u8)
      mem[0xfffe_u32].should eq(8_u8)
    end
  end

  describe "pop" do
    it "pops four bytes" do
      mem = Mem.new
      mem[0_u32] = CPU::O_POP
      mem[1_u32] = 0x05_u8
      mem[0xfffc_u32] = 5_u8
      mem[0xfffd_u32] = 6_u8
      mem[0xfffe_u32] = 7_u8
      mem[0xffff_u32] = 8_u8

      cpu = CPU.new(mem)
      cpu.reg[Reg::RSP] = 0xfffc_u32

      cpu.step
      program_counter.should eq(0x2)
      cpu.reg[Reg::R5].should eq(0x05060708)
      stack_pointer.should eq(0xffff_u32 + 0x01_u32)
    end
  end

  describe "j" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = CPU::O_J
      mem[1_u32] = Reg::R6

      cpu = CPU.new(mem)
      cpu.reg[Reg::R6] = 0x01020304_u32

      cpu.step
      program_counter.should eq(0x01020304)
    end
  end

  describe "ji" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = CPU::O_JI
      mem[1_u32] = 1_u8
      mem[2_u32] = 2_u8
      mem[3_u32] = 3_u8
      mem[4_u32] = 4_u8

      cpu = CPU.new(mem)

      cpu.step
      program_counter.should eq(0x01020304)
    end
  end

  describe "je" do
    # TODO: implement
  end

  describe "jei" do
    # TODO: implement
  end

  describe "jne" do
    # TODO: implement
  end

  describe "jnei" do
    # TODO: implement
  end

  describe "jg" do
    # TODO: implement
  end

  describe "jgi" do
    # TODO: implement
  end

  describe "jge" do
    # TODO: implement
  end

  describe "jgei" do
    # TODO: implement
  end

  describe "jl" do
    # TODO: implement
  end

  describe "jli" do
    # TODO: implement
  end

  describe "jle" do
    # TODO: implement
  end

  describe "jlei" do
    # TODO: implement
  end

  describe "cmp" do
    it "sets the right flags when equal" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMP
      mem[1_u32] = Reg::R1
      mem[2_u32] = Reg::R2

      cpu = CPU.new(mem)
      cpu.reg[Reg::R1] = 0x05_u32
      cpu.reg[Reg::R2] = 0x05_u32

      cpu.step
      program_counter.should eq(0x03)
      cpu.reg[Reg::RFLAGS].should eq(0x01)
    end

    it "sets the right flags when greater than" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMP
      mem[1_u32] = Reg::R1
      mem[2_u32] = Reg::R2

      cpu = CPU.new(mem)
      cpu.reg[Reg::R1] = 0x07_u32
      cpu.reg[Reg::R2] = 0x05_u32

      cpu.step
      program_counter.should eq(0x03)
      cpu.reg[Reg::RFLAGS].should eq(0x02)
    end

    it "sets the right flags when less than" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMP
      mem[1_u32] = Reg::R1
      mem[2_u32] = Reg::R2

      cpu = CPU.new(mem)
      cpu.reg[Reg::R1] = 0x03_u32
      cpu.reg[Reg::R2] = 0x05_u32

      cpu.step
      program_counter.should eq(0x03)
      cpu.reg[Reg::RFLAGS].should eq(0x00)
    end
  end

  describe "cmpi" do
    it "sets the right flags when equal" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMPI
      mem[1_u32] = Reg::R2
      mem[2_u32] = 0_u8
      mem[3_u32] = 0_u8
      mem[4_u32] = 0_u8
      mem[5_u32] = 5_u8

      cpu = CPU.new(mem)
      cpu.reg[Reg::R2] = 0x05_u32

      cpu.step
      program_counter.should eq(0x06)
      cpu.reg[Reg::RFLAGS].should eq(0x01)
    end

    it "sets the right flags when greater than" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMPI
      mem[1_u32] = Reg::R2
      mem[2_u32] = 0_u8
      mem[3_u32] = 0_u8
      mem[4_u32] = 0_u8
      mem[5_u32] = 5_u8

      cpu = CPU.new(mem)
      cpu.reg[Reg::R2] = 0x07_u32

      cpu.step
      program_counter.should eq(0x06)
      cpu.reg[Reg::RFLAGS].should eq(0x02)
    end

    it "sets the right flags when less than" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CMPI
      mem[1_u32] = Reg::R2
      mem[2_u32] = 0_u8
      mem[3_u32] = 0_u8
      mem[4_u32] = 0_u8
      mem[5_u32] = 5_u8

      cpu = CPU.new(mem)
      cpu.reg[Reg::R2] = 0x03_u32

      cpu.step
      program_counter.should eq(0x06)
      cpu.reg[Reg::RFLAGS].should eq(0x00)
    end
  end

  describe "mod" do
    # TODO: implement
  end

  describe "modi" do
    # TODO: implement
  end

  describe "add" do
    # TODO: implement
  end

  describe "addi" do
    # TODO: implement
  end

  describe "sub" do
    # TODO: implement
  end

  describe "subi" do
    # TODO: implement
  end

  describe "mul" do
    # TODO: implement
  end

  describe "muli" do
    # TODO: implement
  end

  describe "div" do
    # TODO: implement
  end

  describe "divi" do
    # TODO: implement
  end

  describe "xor" do
    # TODO: implement
  end

  describe "xori" do
    # TODO: implement
  end

  describe "or" do
    # TODO: implement
  end

  describe "ori" do
    # TODO: implement
  end

  describe "and" do
    # TODO: implement
  end

  describe "andi" do
    # TODO: implement
  end

  describe "shl" do
    # TODO: implement
  end

  describe "shli" do
    # TODO: implement
  end

  describe "shr" do
    # TODO: implement
  end

  describe "shri" do
    # TODO: implement
  end

  describe "not" do
    # TODO: implement
  end

  describe "mov" do
    it "copies the register" do
      mem = Mem.new
      mem[0_u32] = CPU::O_MOV
      mem[1_u32] = Reg::R1
      mem[2_u32] = Reg::R2

      cpu = CPU.new(mem)
      cpu.reg[Reg::R1] = 0x11111111_u32
      cpu.reg[Reg::R2] = 0x22222222_u32

      cpu.step
      cpu.reg[Reg::R1].should eq(0x22222222_u32)
      cpu.reg[Reg::R2].should eq(0x22222222_u32)
    end
  end

  describe "li" do
    # TODO: implement
  end

  describe "lw" do
    # TODO: implement
  end

  describe "lh" do
    # TODO: implement
  end

  describe "lb" do
    # TODO: implement
  end

  describe "sw" do
    # TODO: implement
  end

  describe "sh" do
    # TODO: implement
  end

  describe "sb" do
    # TODO: implement
  end

  describe "prn" do
    # TODO: implement
  end

  describe "halt" do
    # TODO: implement
  end

end
