class String
  def partition_on(sep : String | Char) : Tuple(String, String?)
    a, b, c = self.partition(sep)
    if b.size == 0
      {a, nil}
    else
      {a, c}
    end
  end
end
