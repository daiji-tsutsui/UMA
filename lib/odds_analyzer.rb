

class OddsAnalyzer

  def forecast
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
    size = p.size
    sum = 0.0;
    p.each_with_index do |pi, i|
      sum += pi * (Math.log(pi) - Math.log(q[i]))
    end
    sum
  end
end
