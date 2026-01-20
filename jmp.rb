module Jmp
  def handle_jumps(buf)
    case buf[@buf_index]
    when 0b01110101
      handle_jump(buf, op: :jnz)
    when 0b01110100
      handle_jump(buf, op: :je)
    when 0b01111100
      handle_jump(buf, op: :jl)
    when 0b01111110
      handle_jump(buf, op: :jle)
    when 0b01110010
      handle_jump(buf, op: :jb)
    when 0b01110110
      handle_jump(buf, op: :jbe)
    when 0b01111010
      handle_jump(buf, op: :jp)
    when 0b01110000
      handle_jump(buf, op: :jo)
    when 0b01111000
      handle_jump(buf, op: :js)
    when 0b01110101
      handle_jump(buf, op: :jne)
    when 0b01111101
      handle_jump(buf, op: :jnl)
    when 0b01111111
      handle_jump(buf, op: :jg)
    when 0b01110011
      handle_jump(buf, op: :jnb)
    when 0b01110111
      handle_jump(buf, op: :ja)
    when 0b01111011
      handle_jump(buf, op: :jnp)
    when 0b01110001
      handle_jump(buf, op: :jno)
    when 0b01111001
      handle_jump(buf, op: :jns)
    when 0b11100010
      handle_jump(buf, op: :loop)
    when 0b11100001
      handle_jump(buf, op: :loopz)
    when 0b11100000
      handle_jump(buf, op: :loopnz)
    when 0b11100011
      handle_jump(buf, op: :jcxz)
    else
      false
    end
  end
  
  def handle_jump(buf, op:)
    inc = buf[@buf_index+1]
    inc = inc >= 0x80 ? inc - 0x100 : inc
    @buf_index += 2
    
    @out << op << " " << inc.to_s << "\n"
  end
end
