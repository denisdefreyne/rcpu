require "spec"

require "../src/emulate/cpu"
require "../src/emulate/mem"
require "../src/emulate/reg"

describe CPU do
  describe "j" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = 0x07_u8
      mem[1_u32] = 6_u8 # r6

      cpu = CPU.new(mem)
      cpu.reg[6_u8] = 0x01020304_u32

      cpu.step
      cpu.reg[Reg::PC].should eq(0x01020304)
    end
  end

  describe "ji" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = 0x08_u8
      mem[1_u32] = 1_u8
      mem[2_u32] = 2_u8
      mem[3_u32] = 3_u8
      mem[4_u32] = 4_u8

      cpu = CPU.new(mem)

      cpu.step
      cpu.reg[Reg::PC].should eq(0x01020304)
    end
  end
end
