

class OddsAnalyzer
  attr_accessor :t, :a, :b
  attr_accessor :ini_p

  def initialize
    @a = [1.0]
    @b = []
  end

  # mathematical model
  def forecast(odds_list)
    adjust_params(odds_list)
    p = @ini_p
    model = [@ini_p]
    (odds_list.size - 1).times do |i|
      odds = odds_list[i]
      a = @a[i+1]/@a.first(i+2).sum
      b = @b[i]
      p = forecast_next(p, odds, @t, a, b)
      model.push p
    end
    model
  end

  # t: true distribution
  # a: weight of importance at this moment
  # b: coefficient of certainty at this moment
  def forecast_next(prev, odds, t, a, b)
    p = strategy(odds, t, b)
    prev.map.with_index { |r, i| (1.0 - a) * r + a * p[i] }
  end

  def loss(odds_list)
    model = forecast(odds_list)
    p_list = odds_list.map { |odds| odds_to_prob(odds) }
    p_list.map.with_index { |p, k| kl_div(p, model[k]) }
  end

  def odds_to_prob(odds)
    w = odds.map { |v| 1.0/v }
    normalize(w)
  end

  def strategy(odds, t, b)
    w = t.map.with_index { |r, i| Math.exp(r * odds[i] * b) }
    normalize(w)
  end

  def kl_div(p, q)
    f = p.map.with_index { |pi, i| Math.log(pi) - Math.log(q[i]) }
    expectation(p, f)
  end

  private
    def normalize(w)
      total = w.sum
      w.map { |r| r/total }
    end

    def expectation(base, f)
      fw = base.map.with_index { |r, i| r * f[i] }
      fw.sum
    end

    def adjust_params(odds_list)
      @ini_p ||= odds_to_prob(odds_list[0])
      @t ||= @ini_p.clone
      if @a.size != odds_list.size
        ratio = @a.size.to_f/odds_list.size.to_f
        @a.map! { |ai| ai * ratio }
        @a += Array.new(odds_list.size - @a.size, 1.0/odds_list.size.to_f)
        @a = normalize @a
      end
      @b += Array.new(odds_list.size - @b.size - 1, @b[-1] || 1.0)
    end
end
