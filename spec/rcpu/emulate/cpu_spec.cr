require "spec"

require "../src/emulate/cpu"
require "../src/emulate/mem"
require "../src/emulate/reg"

describe CPU do
  describe "j" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = CPU::O_J
      mem[1_u32] = Reg::R6

      cpu = CPU.new(mem)
      cpu.reg[Reg::R6] = 0x01020304_u32

      cpu.step
      cpu.reg[Reg::RPC].should eq(0x01020304)
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
      cpu.reg[Reg::RPC].should eq(0x01020304)
    end
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
end
