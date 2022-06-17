# frozen_string_literal: true

require './lib/positives'

# Presentation for probability distributions
class Probability < Positives
  def initialize(w = [])
    super(w)
    normalize
  end

  # v: eta-vector
  def move!(v, name = nil)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
      self[0] -= v_i
    end
    warn = validate_total(name)
    normalize
    warn
  end

  # v: eta-vector
  def move_in_theta!(v, _name = nil)
    v_theta = fisher.map do |row|
      row.map.with_index { |entry, j| entry * v[j] }.sum
    end
    v_theta.each.with_index(1) do |v_i, i|
      self[i] *= Math.exp(v_i)
    end
    normalize
    nil
  end

  def extend_to!(trg_size)
    self.map! { |p_i| p_i * self.size.to_f / trg_size.to_f }
    ext = Array.new(trg_size - self.size, 1.0 / trg_size.to_f)
    self.concat(ext)
    normalize
  end

  def expectation(f)
    dot(f)
  end

  def kl_div(q)
    f = self.map.with_index { |p_i, i| Math.log(p_i) - Math.log(q[i]) }
    expectation(f)
  end

  def validate(name = nil)
    [
      validate_negative(name),
      validate_total(name),
    ]
  end

  class << self
    def new_from_odds(odds)
      w = odds.map { |v| 1.0 / v }
      new w
    end

    def delta(i, j)
      return 1.0 if i == j

      0.0
    end
  end

  private

  def normalize
    total = self.sum
    self.map! { |r| r / total }
  end

  def validate_negative(name = nil)
    warn = nil
    self.each do |p_i|
      if p_i.negative?
        warn = "Probability \'#{name}\' maybe has a negative entry"
        break
      end
    end
    warn
  end

  def validate_total(name = nil)
    return unless (self.sum - 1.0).abs > 0.05

    "Probability \'#{name}\' is maybe not normalized"
  end

  def fisher
    size1 = self.size - 1
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
