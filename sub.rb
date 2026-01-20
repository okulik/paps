require_relative 'ascao'

module Sub
  include Ascao

  def handle_sub(buf)
    if buf[@buf_index] >> 2 == 0b001010
      return handle_ascao_default(buf, op: :sub)
    elsif buf[@buf_index] >> 1 == 0b0010110
      return handle_ascao_immediate_acc(buf, op: :sub)
    elsif buf[@buf_index] >> 2 == 0b100000
      return handle_ascao_immediate_rm(buf, op: :sub)
    end
    
    false
  end
end
