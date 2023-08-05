module Enumerable(T)
  def to_h_by
    to_h do |e|
      {yield(e), e}
    end
  end
end
