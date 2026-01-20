require 'pry-byebug'

require_relative 'mov'
require_relative 'add'
require_relative 'sub'
require_relative 'cmp'
require_relative 'jmp'

class Disassembler
  include Mov
  include Add
  include Sub
  include Cmp
  include Jmp

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
    handle_mov(buf) ||
      handle_add(buf) ||
      handle_sub(buf) ||
      handle_cmp(buf) ||
      handle_jumps(buf) ||
      raise("unknown instruction #{buf[@buf_index].to_s(2)}")
  end

  def extract_flags(buf)
    d = (buf[@buf_index] >> 1) & 1
    w = buf[@buf_index] & 1
    reg = (buf[@buf_index+1] >> 3) & 0b111
    rm  = buf[@buf_index+1] & 0b111
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

  def mem_to_s(rm, mod:, disp: nil)
    if !disp.nil? && mod != 0b00
      if disp < 0
        disp = " - #{disp*(-1)}"
      elsif disp > 0
        disp = " + #{disp}"
      else
        disp = ""
      end
    end

    case rm
    when 0b000
      "[bx + si#{disp}]"
    when 0b001
      "[bx + di#{disp}]"
    when 0b010
      "[bp + si#{disp}]"
    when 0b011
      "[bp + di#{disp}]"
    when 0b100
      "[si#{disp}]"
    when 0b101
      "[di#{disp}]"
    when 0b110
      mod == 0b00 ? "[#{disp}]" : "[bp#{disp}]"
    when 0b111
      mod == 0b00 ? "[bx]" : "[bx#{disp}]"
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
