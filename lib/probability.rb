# frozen_string_literal: true

require './lib/positives'

# Presentation for probability distributions on $n+1$ points
class Probability < Positives
  def initialize(w = [])
    super(w)
    normalize!
  end

  # override
  # v: $n$-dim eta-vector
  def move!(v)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
      self[0] -= v_i
    end
    normalize!
  end

  def extend_to!(trg_size)
    self.map! { |p_i| p_i * self.size.to_f / trg_size.to_f }
    ext = Array.new(trg_size - self.size, 1.0 / trg_size.to_f)
    self.concat(ext)
    normalize!
  end

  # Make a copy shirnked to probability distributions on $m+1$ points
  def shrink(m)
    Probability.new(self[0..m])
  end

  def shrink_rate(m)
    1.0 / self[0..m].sum
  end

  def expectation(f)
    dot(f)
  end

  def kl_div(q)
    f = self.map.with_index { |p_i, i| Math.log(p_i) - Math.log(q[i]) }
    expectation(f)
  end

  class << self
    def new_from_odds(odds)
      w = odds.map { |v| 1.0 / v }
      new w
    end

    def delta(i, j)
      i == j ? 1.0 : 0.0
    end
  end

  private

  def normalize!
    super
    total = self.sum
    self.map! { |r| r / total }
  end

  # $n \times n$ matrix
  def fisher
    size1 = size - 1
    matrix = Array.new(size1)
    (0..size1 - 1).each do |i|
      matrix[i] = Array.new(size1, 0.0)
      (0..size1 - 1).each do |j|
        matrix[i][j] = self[i + 1] if i == j
        matrix[i][j] -= self[i + 1] * self[j + 1]
      end
    end
    matrix
  end
end
