

class OddsAnalyzer
  attr_accessor :t, :a, :b
  attr_accessor :ini_p
  attr_accessor :model, :blueprint
  attr_accessor :eps

  def initialize
    @a = [1.0]
    @b = [1.0]  # @b[0]はdummy
    @eps = 0.00001
  end

  # mathematical model
  def forecast(odds_list)
    adjust_params(odds_list)
    p = @ini_p
    @model = []
    @blueprint = []
    (1..odds_list.size - 1).each do |i|
      odds = odds_list[i-1]
      a = @a[i] / @a.first(i+1).sum
      b = @b[i]
      p = forecast_next(p, odds, @t, a, b)
      @model.push p
    end
    @model
  end

  # t: true distribution
  # a: weight of importance at this moment
  # b: coefficient of certainty at this moment
  def forecast_next(prev, odds, t, a, b)
    q = strategy(odds, t, b)
    @blueprint.push q
    prev.map.with_index { |r, i| (1.0 - a) * r + a * q[i] }
  end

  def update_params(odds_list, prepare: false)
    forecast(odds_list) if prepare
    @model.each do |p|
      update_a(p, odds_list)
      update_b(p, odds_list)
      update_t(p, odds_list)
    end
    @a = normalize(@a)
    @t = normalize(@t)
  end

  def loss(odds_list, prepare: false)
    forecast(odds_list) if prepare
    @model.map.with_index do |q, k|
      p = odds_to_prob(odds_list[k+1])
      kl_div(p, q)
    end
  end

  def strategy(odds, t, b)
    w = t.map.with_index { |r, i| Math.exp(r * odds[i] * b) }
    normalize(w)
  end

  def kl_div(p, q)
    f = p.map.with_index { |p_i, i| Math.log(p_i) - Math.log(q[i]) }
    expectation(p, f)
  end


  private

    def odds_to_prob(odds)
      w = odds.map { |v| 1.0/v }
      normalize(w)
    end

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
        ratio = @a.size.to_f / odds_list.size.to_f
        @a.map! { |ai| ai * ratio }
        @a += Array.new(odds_list.size - @a.size, 1.0 / odds_list.size.to_f)
        @a = normalize @a
      end
      @b += Array.new(odds_list.size - @b.size, @b[-1] || 1.0)
    end

    def update_a(p, odds_list)
      da = grad_a(p, odds_list)
      da.each.with_index(1) do |da_i, i|
        @a[i] -= @eps * da_i
        @a[0] += @eps * da_i
      end
    end

    def update_b(p, odds_list)
      db = grad_b(p, odds_list)
      db.each.with_index(1) do |db_i, i|
        @b[i] -= @eps * db_i
      end
    end

    def update_t(p, odds_list)
      dt = grad_t(p, odds_list)
      dt.each.with_index do |dt_i, i|
        @t[i] -= @eps * dt_i
      end
    end

    def grad_a(p, odds_list)
      @blueprint.map.with_index(1) do |strat, k|
        teacher = odds_to_prob(odds_list[k])
        grad_a_for_instant(p, teacher, strat)
      end
    end

    def grad_a_for_instant(p, teacher, strat)
      f = p.map.with_index { |p_i, i| (strat[i] - @ini_p[i]) / p_i }
      -expectation(teacher, f)
    end

    def grad_b(p, odds_list)
      @blueprint.map.with_index(1) do |strat, k|
        teacher = odds_to_prob(odds_list[k])
        grad_b_for_instant(p, teacher, strat, @a[k], odds_list[k])
      end
    end

    def grad_b_for_instant(p, teacher, strat, a, odds)
      f1 = @t.map.with_index { |ti, i| ti * odds[i] }
      exp_f1 = expectation(strat, f1)
      f2 = p.map.with_index { |p_i, i| a * strat[i] * (f1[i] - exp_f1) / p_i }
      -expectation(teacher, f2)
    end

    def grad_t(p, odds_list)
      grad_list = @blueprint.map.with_index(1) do |strat, k|
        teacher = odds_to_prob(odds_list[k])
        grad_t_for_instant(p, teacher, strat, @a[k], @b[k], odds_list[k])
      end
      grad_list.transpose.map { |row| row.sum }
    end

    def grad_t_for_instant(p, teacher, strat, a, b, odds)
      result = []
      odds.size.times do |j|
        f = p.map.with_index do |p_i, i|
          a * b * strat[i] * (
            odds[j] * (delta(i, j) - strat[j])
            - odds[0] * (delta(i, 0) - strat[0])
          ) / p_i
        end
        result.push -expectation(teacher, f)
      end
      result
    end

    def delta(i, j)
      return 1.0 if i == j
      0.0
    end
end
