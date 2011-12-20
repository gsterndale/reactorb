class CallbackRegistry < Hash

  def initialize(*args, &blk)
    blk ||= proc {|h,k| h[k] = [] }
    super *args, &blk
  end

  def first_key
    self.keys.sort.first
  end

  def shift
    if key = self.first_key
      self.delete key
    end
  end

  def shift_pair
    if key = self.first_key
      [ key, self.delete(key) ]
    end
  end

end
