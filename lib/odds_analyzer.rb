

class OddsAnalyzer
  attr_accessor :t, :a, :b
  attr_accessor :ini_odds

  def initialize
    @a = [1.0]
    @b = []
  end

  def forecast(odds_list)
    adjust_params(odds_list)
  end

  # t: true distribution
  # a: weight of importance at this moment
  # b: coefficient of certainty at this moment
  def forecast_next(prev, odds, t, a, b)
    p = strategy(odds, t, b)
    prev.map.with_index { |r, i| (1.0 - a) * r + a * p[i] }
  end

  def odds_to_prob(odds)
    w = odds.map { |v| 1.0/v }
    total = w.sum
    w.map { |r| r/total }
  end

  def strategy(odds, t, b)
    w = t.map.with_index { |r, i| Math.exp(r * odds[i] * b) }
    total = w.sum
    w.map { |r| r/total }
  end

  def kl_div(p, q)
    f = p.map.with_index { |pi, i| Math.log(pi) - Math.log(q[i]) }
    expectation(p, f)
  end

  private
    def expectation(base, f)
      fw = base.map.with_index { |r, i| r * f[i] }
      fw.sum
    end

    def adjust_params(odds_list)
      @ini_odds ||= odds_list[0]
      @t ||= @ini_odds.clone
      if @a.size != odds_list.size
        ratio = @a.size.to_f/odds_list.size.to_f
        @a.map! { |ai| ai * ratio }
        @a += Array.new(odds_list.size - @a.size, 1.0/odds_list.size.to_f)
      end
      @b += Array.new(odds_list.size - @b.size - 1, @b[-1] || 1.0)
    end
end
