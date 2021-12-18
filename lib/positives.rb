class Positives < Array

  def initialize(w = [])
    self.concat(w)
    self.concat([1.0]) if self.empty?
  end

  def move(v, name = nil)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
    end
    nil
  end

  def move_theta(v, name = nil)
    v_theta = v.map.with_index(1) { |v_i, i| self[i] * v_i }
    v_theta.each.with_index(1) do |v_i, i|
      self[i] *= Math.exp(v_i)
    end
    nil
  end

  def extend(trg_size)
    ext = Array.new(trg_size - self.size, self[-1] || 1.0)
    self.concat(ext)
  end
end
