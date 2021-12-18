class Probability < Array

  def initialize(w = [], logger: nil)
    @logger = logger
    self.concat(w)
    self.concat([1.0]) if self.empty?
    normalize(false)
  end

  def kl_div(q)
    f = self.map.with_index { |p_i, i| Math.log(p_i) - Math.log(q[i]) }
    expectation(f)
  end

  class << self
    def new_from_odds(odds)
      w = odds.map { |v| 1.0 / v }
      new(w)
    end

    def delta(i, j)
      return 1.0 if i == j
      0.0
    end
  end


  private

    def normalize(caution = true)
      total = self.sum
      if caution && !@logger.nil? && (total - 1.0).abs > 0.05
        if @logger.nil?
          puts "[WARN][#{Time.now}] Maybe non-probability: #{self}"
        else
          @logger.warn "Maybe non-probability: #{self}"
        end
      end
      self.map! { |r| r / total }
    end

    def expectation(f)
      self.map.with_index { |r, i| r * f[i] }.sum
    end
end
