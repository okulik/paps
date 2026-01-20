module Mov
  def handle_mov(buf)
    if buf[@buf_index] >> 2 == 0b100010
      return handle_mov_default(buf)
    elsif buf[@buf_index] >> 4 == 0b1011
      return handle_mov_immediate_to_reg(buf)
    elsif buf[@buf_index] >> 1 == 0b1100011
      return handle_mov_immediate_to_reg_mem(buf)
    elsif buf[@buf_index] >> 1 == 0b1010000
      return handle_mov_mem_to_acc(buf)
    elsif buf[@buf_index] >> 1 == 0b1010001
      return handle_mov_acc_to_mem(buf)
    end
    
    false
  end

  def handle_mov_default(buf)
    mod = buf[@buf_index+1] >> 6

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
      raise 'unknown mov mode'
    end
    
    true
  end
  
  def handle_mov_reg(buf)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    rm_str = reg_to_s(rm, w)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str

    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_no(buf)
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
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_8_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index]
    @buf_index += 1
    disp = disp >= 0x80 ? disp - 0x100 : disp
    rm_str = mem_to_s(rm, mod: 0b01, disp: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end
  
  def handle_mov_mem_16_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    @buf_index += 2
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
    @buf_index += 2
    disp = disp >= 0x8000 ? disp - 0x10000 : disp
    rm_str = mem_to_s(rm, mod: 0b10, disp: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "mov" << " " << dest << ", " << src << "\n"
  end

  def handle_mov_immediate_to_reg(buf)
    w = (buf[@buf_index] >> 3) & 1
    reg = buf[@buf_index] & 0b111
    @buf_index += 1
    
    dest = reg_to_s(reg, w)
    if w == 0
      src = buf[@buf_index]
      @buf_index += 1
    else
      src = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
    end
      
    @out << "mov" << " " << dest << ", " << src << "\n"
    
    true
  end
  
  def handle_mov_immediate_to_reg_mem(buf)
    mod = buf[@buf_index+1] >> 6
    _, w, _, rm = extract_flags(buf)
    @buf_index += 2
    
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
      dest = mem_to_s(rm, mod: mod)
      src = disp
    else
      dest = mem_to_s(rm, mod: mod, disp: disp)
      if w == 0
        src = buf[@buf_index]
        @buf_index += 1
      else
        src = buf[@buf_index] + (buf[@buf_index+1] << 8)
        @buf_index += 2
      end
    end

    @out << "mov" << " " << dest << ", " << hint.to_s + src.to_s << "\n"
    
    true
  end
  
  def handle_mov_mem_to_acc(buf)
    w = buf[@buf_index] & 1
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
    
    true
  end
  
  def handle_mov_acc_to_mem(buf)
    w = buf[@buf_index] & 1
    @buf_index += 1
    
    if w == 0
      dest = buf[@buf_index]
      @buf_index += 1
    else
      dest = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
    end
    src = w == 0 ? 'al' : 'ax'

    @out << "mov" << " " << "[#{dest}]" << ", " << src << "\n"
    
    true
  end
end
