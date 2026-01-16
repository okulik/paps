require 'pry-byebug'

class Disassembler
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
    else
      raise "unknown instruction #{buf[@buf_index].to_s(2)}"
    end
  end

  def handle_mov(buf)
    mod = (buf[@buf_index+1] & 0b11000000) >> 6

    case mod
    when 0b11 # reg
      handle_mov_reg(buf)
    when 0b00 # mem_no
      handle_mov_mem_no(buf)
    when 0b01 # mem_8_bit
      handle_mov_mem_8_bit(buf)
    when 0b10 # mem_16_bit
      handle_mov_mem_16_bit(buf)
    else
      raise 'unknown mode'
    end
  end
  
  def handle_mov_reg(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = mov_reg_to_s(reg, w)
    rm_str = mov_reg_to_s(rm, w)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str

    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_no(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = mov_reg_to_s(reg, w)
    if rm == 0b110
      rm_str = "[#{buf[@buf_index] + (buf[@buf_index+1] << 8)}]"
      @buf_index += 2
    else
      rm_str = mov_mem_to_s(rm)
    end

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_8_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = mov_reg_to_s(reg, w)
    disp = buf[@buf_index]
    @buf_index += 1
    disp = disp >= 0x80 ? disp - 0x100 : disp
    disp = nil if disp.zero?
    rm_str = mov_mem_to_s(rm, d: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_16_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = mov_reg_to_s(reg, w)
    disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
    @buf_index += 2
    disp = disp >= 0x8000 ? disp - 0x10000 : disp
    disp = nil if disp.zero?
    rm_str = mov_mem_to_s(rm, d: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def extract_flags(buf)
    d = (buf[@buf_index] & 0b00000010) == 0b00000010 ? 1 : 0
    w = (buf[@buf_index] & 0b00000001) == 0b00000001 ? 1 : 0
    reg = (buf[@buf_index+1] & 0b00111000) >> 3
    rm  = buf[@buf_index+1] & 0b00000111
    @buf_index += 2
    return [d, w, reg, rm]
  end
  
  def handle_mov_immediate_to_reg(buf)
    w = (buf[@buf_index] & 0b00001000) >> 3
    reg = buf[@buf_index] & 0b00000111
    @buf_index += 1
    
    dest = mov_reg_to_s(reg, w)
    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      src = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
    end
      
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_immediate_to_reg_mem(buf)
    mod = (buf[@buf_index+1] & 0b11000000) >> 6
    _, w, _, rm = extract_flags(buf)
    
    if w == 0
      disp = buf[@buf_index]
      @buf_index += 1
      hint = 'byte '
    else
      disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
      hint = 'word '
    end

    if mod == 0b000
      dest = mov_mem_to_s(rm)
      src = disp
    else
      dest = mov_mem_to_s(rm, d: disp)
      if w == 0
        src = buf[@buf_index]
        @buf_index += 1
      else
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      end
    end

    @out << "mov" << " " << dest << ", " << hint.to_s + src.to_s << "\n"
  end
  
  def handle_mov_mem_to_acc(buf)
    w = buf[@buf_index] & 0b00000001
    @buf_index += 1

    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      src = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
    end
    
    dest = w == 0 ? 'al' : 'ax'

    @out << "mov" << " " << dest << ", " << "[#{src}]" << "\n"
  end
  
  def handle_mov_acc_to_mem(buf)
    w = buf[@buf_index] & 0b00000001
    @buf_index += 1
    
    if w == 0
      dest = buf[@buf_index]
      @buf_index += 1
    else
      dest = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
    end
    src = (w == 0) ? 'al' : 'ax'

    @out << "mov" << " " << "[#{dest}]" << ", " << src << "\n"
  end

  def mov_reg_to_s(b, w)
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

  def mov_mem_to_s(b, d:nil)
    if !d.nil?
      if d < 0
        d = " - #{d*(-1)}"
      else
        d = " + #{d}"
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
disasm.process

puts "bits 16"
puts disasm.out.join("")
