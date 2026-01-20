module Ascao
  def handle_ascao_default(buf, op:)
    mod = buf[@buf_index+1] >> 6

    case mod
    when 0b11 # reg
      handle_ascao_default_reg(buf, op: op)
    when 0b00 # mem_no
      handle_ascao_default_mem_no(buf, op: op)
    when 0b01 # mem_8_bit
      handle_ascao_default_mem_8_bit(buf, op: op)
    when 0b10 # mem_16_bit
      handle_ascao_default_mem_16_bit(buf, op: op)
    else
      raise 'unknown add mode'
    end
    
    true
  end
  
  def handle_ascao_default_reg(buf, op:)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    rm_str = reg_to_s(rm, w)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str

    @out << op << " " << dest << ", " << src << "\n"
  end
  
  def handle_ascao_default_mem_no(buf, op:)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    if rm == 0b110
      rm_str = "[#{buf[@buf_index] + (buf[@buf_index+1] << 8)}]"
      @buf_index += 2
    else
      rm_str = mem_to_s(rm, mod: 0b00)
    end

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << op << " " << dest << ", " << src << "\n"
  end
  
  def handle_ascao_default_mem_8_bit(buf, op:)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index]
    @buf_index += 1
    disp = disp >= 0x80 ? disp - 0x100 : disp
    rm_str = mem_to_s(rm, mod: 0b01, disp: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << op << " " << dest << ", " << src << "\n"
  end
  
  def handle_ascao_default_mem_16_bit(buf, op:)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
    @buf_index += 2
    disp = disp >= 0x8000 ? disp - 0x10000 : disp
    rm_str = mem_to_s(rm, mod: 0b10, disp: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << op << " " << dest << ", " << src << "\n"
  end

  def handle_ascao_immediate_acc(buf, op:)
    w = buf[@buf_index] & 1
    @buf_index += 1

    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
      src = src >= 0x80 ? src - 0x100 : src
    else
      src = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
      src = src >= 0x8000 ? src - 0x10000 : src
    end
    
    dest = w == 0 ? 'al' : 'ax'

    @out << op << " " << dest << ", " << src.to_s << "\n"
    
    true
  end

  def handle_ascao_immediate_rm(buf, op:)
    return false if op(buf) != op

    mod = buf[@buf_index+1] >> 6
    case mod
    when 0b11 # reg
      handle_ascao_immediate_rm_reg(buf, op: op)
    when 0b00 # mem_no
      handle_ascao_immediate_rm_mem_no(buf, op: op)
    when 0b01 # mem_8_bit
      handle_ascao_immediate_rm_mem_8_bit(buf, op: op)
    when 0b10 # mem_16_bit
      handle_ascao_immediate_rm_mem_16_bit(buf, op: op)
    else
      raise 'unknown add mode'
    end
    
    true
  end
  
  def handle_ascao_immediate_rm_reg(buf, op:)
    mod = buf[@buf_index+1] >> 6
    s, w, _, rm = extract_flags(buf)
    @buf_index += 2
    
    dest = reg_to_s(rm, w)

    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      if s == 0
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      else
        src = buf[@buf_index]
        @buf_index += 1
        src = src >= 0x80 ? src - 0x100 : src
      end
    end
    
    @out << op.to_s << " " << dest << ", " << src.to_s << "\n"
  end
  
  def handle_ascao_immediate_rm_mem_no(buf, op:)
    mod = buf[@buf_index+1] >> 6
    s, w, _, rm = extract_flags(buf)
    @buf_index += 2
    
    if rm == 0b110
      disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
      dest = mem_to_s(rm, mod: mod, disp: disp)
    else
      dest = mem_to_s(rm, mod: mod)
    end
    hint = w == 0 ? 'byte ' : 'word '
    
    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      if s == 0
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      else
        src = buf[@buf_index]
        @buf_index += 1
        src = src >= 0x80 ? src - 0x100 : src
      end
    end
    
    @out << op.to_s << " " << hint.to_s << dest << ", " << src.to_s << "\n"
  end
  
  def handle_ascao_immediate_rm_mem_8_bit(buf, op:)
    mod = buf[@buf_index+1] >> 6
    s, w, _, rm = extract_flags(buf)
    @buf_index += 2

    disp = buf[@buf_index]
    @buf_index += 1
    dest = mem_to_s(rm, mod: mod, disp: disp)
    hint = 'byte ' if w == 0
    
    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      if s == 0
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      else
        src = buf[@buf_index]
        @buf_index += 1
        src = src >= 0x80 ? src - 0x100 : src
      end
    end
    
    @out << op.to_s << " " << hint.to_s << dest << ", " << src.to_s << "\n"
  end
  
  def handle_ascao_immediate_rm_mem_16_bit(buf, op:)
    mod = buf[@buf_index+1] >> 6
    s, w, _, rm = extract_flags(buf)
    @buf_index += 2

    disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
    @buf_index += 2
    dest = mem_to_s(rm, mod: mod, disp: disp)
    hint = 'word ' if w == 1

    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      if s == 0
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      else
        src = buf[@buf_index]
        @buf_index += 1
        src = src >= 0x80 ? src - 0x100 : src
      end
    end

    @out << op.to_s << " " << hint.to_s << dest << ", " << src.to_s << "\n"
  end
  
  def op(buf)
    _, _, reg, _ = extract_flags(buf)
    case reg
    when 0b000
      :add
    when 0b010
      :adc
    when 0b101
      :sub
    when 0b011
      :sbb
    when 0b111
      :cmp
    when 0b100
      :and
    when 0b001
      :or
    else
      raise 'unsupported op'
    end
  end
end
