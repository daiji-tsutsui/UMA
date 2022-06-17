# frozen_string_literal: true

# Presentation for nonnegative distributions
class Positives < Array
  def initialize(w = [])
    super(w)
    self.concat([1.0]) if self.empty?
  end

  def move!(v, _name = nil)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
    end
    nil
  end

  def move_in_theta!(v, _name = nil)
    v_theta = v.map.with_index(1) { |v_i, i| self[i] * v_i }
    v_theta.each.with_index(1) do |v_i, i|
      self[i] *= Math.exp(v_i)
    end
    nil
  end

  def extend_to!(trg_size)
    ext = Array.new(trg_size - self.size, 1.0)
    self.concat(ext)
  end

  # Schur product a.k.a. Hadamard or element-wise product
  def schur(array)
    self.map.with_index { |r, i| r * array[i] }
  end

  # Inner-product
  def dot(array)
    schur(array).sum
  end
end
