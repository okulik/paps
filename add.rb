require_relative 'ascao'

module Add
  include Ascao

  def handle_add(buf)
    if buf[@buf_index] >> 2 == 0b000000
      return handle_ascao_default(buf, op: :add)
    elsif buf[@buf_index] >> 1 == 0b0000010
      return handle_ascao_immediate_acc(buf, op: :add)
    elsif buf[@buf_index] >> 2 == 0b100000
      return handle_ascao_immediate_rm(buf, op: :add)
    end
    
    false
  end
end
