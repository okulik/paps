require 'pry-byebug'

require_relative 'mov'
require_relative 'add'

class Disassembler
  include Mov
  include Add

  attr_reader :file_name, :out

  def initialize(file_name)
    @file_name = file_name
    @out = []
    @buf_index = 0
  end
  
  def process
    File.open(file_name, 'rb') do |file|
      buf = file.read.unpack('C*')
      while @buf_index < buf.length do
        handle_instruction(buf)
      end
    end
  end
  
  private
  
  def handle_instruction(buf)
    if buf[@buf_index] >> 2 == 0b100010
      handle_mov(buf)
    elsif buf[@buf_index] >> 4 == 0b1011
      handle_mov_immediate_to_reg(buf)
    elsif buf[@buf_index] >> 1 == 0b1100011
      handle_mov_immediate_to_reg_mem(buf)
    elsif buf[@buf_index] >> 1 == 0b1010000
      handle_mov_mem_to_acc(buf)
    elsif buf[@buf_index] >> 1 == 0b1010001
      handle_mov_acc_to_mem(buf)
    elsif buf[@buf_index] >> 2 == 0b000000
      handle_add(buf)
    elsif buf[@buf_index] >> 2 == 0b100000
      handle_add_immediate_to_reg_mem(buf)
    elsif buf[@buf_index] >> 1 == 0b0000010
      handle_add_immediate_to_acc(buf)
    else
      raise "unknown instruction #{buf[@buf_index].to_s(2)}"
    end
  end
  
  def extract_flags(buf)
    d = (buf[@buf_index] >> 1) & 1
    w = buf[@buf_index] & 1
    reg = (buf[@buf_index+1] >> 3) & 0b111
    rm  = buf[@buf_index+1] & 0b111
    @buf_index += 2
    return [d, w, reg, rm]
  end

  def reg_to_s(b, w)
    case b
    when 0b000
      w == 0 ? 'al' : 'ax'
    when 0b001
      w == 0 ? 'cl' : 'cx'
    when 0b010
      w == 0 ? 'dl' : 'dx'
    when 0b011
      w == 0 ? 'bl' : 'bx'
    when 0b100
      w == 0 ? 'ah' : 'sp'
    when 0b101
      w == 0 ? 'ch' : 'bp'
    when 0b110
      w == 0 ? 'dh' : 'si'
    when 0b111
      w == 0 ? 'bh' : 'di'
    else
      raise 'unknown reg/rm'
    end
  end

  def mem_to_s(b, d:nil)
    if !d.nil?
      if d < 0
        d = " - #{d*(-1)}"
      elsif d > 0
        d = " + #{d}"
      else
        d = ""
      end
    end

    case b
    when 0b000
      "[bx + si#{d}]"
    when 0b001
      "[bx + di#{d}]"
    when 0b010
      "[bp + si#{d}]"
    when 0b011
      "[bp + di#{d}]"
    when 0b100
      "[si#{d}]"
    when 0b101
      "[di#{d}]"
    when 0b110
      "[bp#{d}]"
    when 0b111
      "[bx#{d}]"
    else
      raise 'unknown reg/rm'
    end
  end
end

disasm = Disassembler.new(ARGV[0])
begin
disasm.process
rescue => e
  puts e
end

puts "bits 16"
puts disasm.out.join("")
