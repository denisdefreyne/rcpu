require "spec"

require "../src/emulate/cpu"
require "../src/emulate/mem"
require "../src/emulate/reg"

describe CPU do
  describe "calli" do
    it "pushes the return address and jumps" do
      mem = Mem.new
      mem[0_u32] = CPU::O_CALLI
      mem[1_u32] = 1_u8
      mem[2_u32] = 2_u8
      mem[3_u32] = 3_u8
      mem[4_u32] = 4_u8

      cpu = CPU.new(mem)

      cpu.reg[Reg::RPC].should eq(0x0)
      cpu.reg[Reg::RSP].should eq(0xffff)
      cpu.step
      cpu.reg[Reg::RPC].should eq(0x01020304)
      cpu.reg[Reg::RSP].should eq(0xfffb)
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

      cpu.reg[Reg::RPC].should eq(0x0)
      cpu.step
      cpu.reg[Reg::RPC].should eq(0x05060708)
      cpu.reg[Reg::RSP].should eq(0xffff_u32 + 0x01_u32)
    end
  end

  describe "push" do
    # TODO: implement
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

      cpu.reg[Reg::RPC].should eq(0x00)
      cpu.reg[Reg::RSP].should eq(0xffff)
      cpu.step
      cpu.reg[Reg::RPC].should eq(0x05)
      cpu.reg[Reg::RSP].should eq(0xfffb_u32)
      mem[0xfffb_u32].should eq(5_u8)
      mem[0xfffc_u32].should eq(6_u8)
      mem[0xfffd_u32].should eq(7_u8)
      mem[0xfffe_u32].should eq(8_u8)
    end
  end

  describe "j" do
    it "jumps to the right address" do
      mem = Mem.new
      mem[0_u32] = CPU::O_J
      mem[1_u32] = Reg::R6

      cpu = CPU.new(mem)
      cpu.reg[Reg::R6] = 0x01020304_u32

      cpu.reg[Reg::RPC].should eq(0x0)
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

      cpu.reg[Reg::RPC].should eq(0x0)
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
