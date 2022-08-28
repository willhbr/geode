struct Number
  def count_bytes : String
    val = self.to_u64
    v = 1000_u64 ** 6
    {'E', 'P', 'T', 'G', 'M', 'k'}.each do |n|
      return "#{(val / v).format(decimal_places: 1)}#{n}" if val > v
      v //= 1000
    end
    return val.to_s
  end
end
