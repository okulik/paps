require_relative 'ascao'

module Cmp
  include Ascao

  def handle_cmp(buf)
    if buf[@buf_index] >> 2 == 0b001110
      return handle_ascao_default(buf, op: :cmp)
    elsif buf[@buf_index] >> 1 == 0b0011110
      return handle_ascao_immediate_acc(buf, op: :cmp)
    elsif buf[@buf_index] >> 2 == 0b100000
      return handle_ascao_immediate_rm(buf, op: :cmp)
    end
    
    false
  end
end
