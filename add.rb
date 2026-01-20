module Add
  def handle_add(buf)
    mod = buf[@buf_index+1] >> 6

    case mod
    when 0b11 # reg
      handle_add_reg(buf)
    when 0b00 # mem_no
      handle_add_mem_no(buf)
    when 0b01 # mem_8_bit
      handle_add_mem_8_bit(buf)
    when 0b10 # mem_16_bit
      handle_add_mem_16_bit(buf)
    else
      raise 'unknown add mode'
    end
  end
  
  def handle_add_reg(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = reg_to_s(reg, w)
    rm_str = reg_to_s(rm, w)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str

    @out << "add" << " " << dest << ", " << src << "\n"
  end
  
  def handle_add_mem_no(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = reg_to_s(reg, w)
    if rm == 0b110
      rm_str = "[#{buf[@buf_index] + (buf[@buf_index+1] << 8)}]"
      @buf_index += 2
    else
      rm_str = mem_to_s(rm)
    end

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "add" << " " << dest << ", " << src << "\n"
  end
  
  def handle_add_mem_8_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index]
    @buf_index += 1
    disp = disp >= 0x80 ? disp - 0x100 : disp
    rm_str = mem_to_s(rm, d: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "add" << " " << dest << ", " << src << "\n"
  end
  
  def handle_add_mem_16_bit(buf)
    d, w, reg, rm = extract_flags(buf)
    reg_str = reg_to_s(reg, w)
    disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
    @buf_index += 2
    disp = disp >= 0x8000 ? disp - 0x10000 : disp
    rm_str = mem_to_s(rm, d: disp)

    src = d == 0 ? reg_str : rm_str
    dest = d == 0 ? rm_str : reg_str
    
    @out << "add" << " " << dest << ", " << src << "\n"
  end

  def handle_add_immediate_to_reg_mem(buf)
    mod = buf[@buf_index+1] >> 6
    s, w, _, rm = extract_flags(buf)

    if mod == 0b11
      dest = reg_to_s(rm, w)
    elsif mod == 0b00
      dest = mem_to_s(rm)
      hint = 'byte ' if w == 0
    elsif mod == 0b01
      disp = buf[@buf_index]
      @buf_index += 1
      dest = mem_to_s(rm, d: disp)
      hint = 'byte ' if w == 0
    elsif mod == 0b10
      disp = buf[@buf_index] + (buf[@buf_index+1] << 8)
      @buf_index += 2
      dest = mem_to_s(rm, d: disp)
      hint = 'word ' if w == 1
    end

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

    @out << "add" << " " << hint.to_s << dest << ", " << src.to_s << "\n"
  end
  
  def handle_add_immediate_to_acc(buf)
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

    @out << "add" << " " << dest << ", " << src.to_s << "\n"
  end
end
