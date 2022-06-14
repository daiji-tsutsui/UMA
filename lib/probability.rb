# Presentation for probability distributions
class Probability < Array

  def initialize(w = [])
    self.concat(w)
    self.concat([1.0]) if self.empty?
    normalize
  end

  def kl_div(q)
    f = self.map.with_index { |p_i, i| Math.log(p_i) - Math.log(q[i]) }
    expectation(f)
  end

  # v: eta-vector
  def move!(v, name = nil)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
      self[0] -= v_i
    end
    warn = check_total(name)
    normalize
    warn
  end

  # v: eta-vector
  def move_in_theta!(v, name = nil)
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
    self.map.with_index { |r, i| r * f[i] }.sum
  end

  def check(name = nil)
    [
      check_negative(name),
      check_total(name),
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

    def check_negative(name = nil)
      warn = nil
      self.each do |p_i|
        if p_i < 0
          warn = "Probability \'#{name}\' maybe has a negative entry"
          break
        end
      end
      warn
    end

    def check_total(name = nil)
      if (self.sum - 1.0).abs > 0.05
        "Probability \'#{name}\' is maybe not normalized"
      end
    end

    def fisher
      size1 = self.size - 1
      matrix = Array.new(size1)
      (0..size1 - 1).each do |i|
        matrix[i] = Array.new(size1)
        (0..size1 - 1).each do |j|
          matrix[i][j] = -self[i + 1] * self[j + 1]
          matrix[i][j] += self[i + 1] if i == j
        end
      end
      matrix
    end
end
