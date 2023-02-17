# frozen_string_literal: true

# Presentation for nonnegative distributions with $n$-dim
class Positives < Array
  NON_NEGATIVE_MARGIN = 1e-5

  def initialize(w = [])
    super(w)
    # NOTE: the 0-th element is dummy!!
    self.push(1.0) if self.empty?
  end

  # v: $(n-1)$-dim eta-vector
  def move!(v)
    v.each.with_index(1) do |v_i, i|
      self[i] += v_i
    end
  end

  # v: $(n-1)$-dim eta-vector
  def move_with_natural_grad!(v)
    v_natural = fisher.map do |row|
      row.map.with_index { |entry, j| entry * v[j] }.sum
    end
    move!(v_natural)
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

  private

  def normalize!
    self.map! { |v| [v, NON_NEGATIVE_MARGIN].max }
  end

  # $(n-1) \times (n-1)$ matrix
  def fisher
    size1 = size - 1 # Since 0-th element is dummy
    matrix = Array.new(size1)
    (0..size1 - 1).each do |i|
      matrix[i] = Array.new(size1, 0.0)
      (0..size1 - 1).each do |j|
        matrix[i][j] = self[i + 1] if i == j
      end
    end
    matrix
  end
end
