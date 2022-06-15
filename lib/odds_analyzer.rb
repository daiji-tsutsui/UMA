# frozen_string_literal: true

require "./lib/probability"
require "./lib/positives"

# Object class for mathematical model for fitting time series of odds
class OddsAnalyzer

  PROBABLE_EFFICIENCY = 0.05
  PROBABLE_GUARANTY = 0.6
  PROBABLE_RETURN = 0.8

  attr_accessor :t, :a, :b
  attr_accessor :ini_p
  attr_accessor :model, :blueprint
  attr_accessor :eps

  def initialize(logger = nil)
    @logger = logger
    @a = Probability.new
    @b = Positives.new      # @b[0]はdummy
    @eps = 0.01
  end

  # mathematical model
  def forecast(odds_list)
    adjust_params(odds_list)
    p = @ini_p
    @model = []
    @blueprint = []
    (1..odds_list.size - 1).each do |i|
      odds = odds_list[i - 1]
      a = @a[i] / @a.first(i + 1).sum
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

  def update_params(odds_list, with_forecast: false)
    with_forecast ? forecast(odds_list) : adjust_params(odds_list)
    warnings = []
    @model.each do |p|
      warnings.concat [
        update_a(p, odds_list),
        update_t(p, odds_list),
        update_b(p, odds_list),
      ]
    end
    validate_params(warnings)
  end

  def loss(odds_list, with_forecast: false)
    with_forecast ? forecast(odds_list) : adjust_params(odds_list)
    @model.map.with_index do |q, k|
      p = Probability.new_from_odds(odds_list[k+1])
      p.kl_div(q)
    end
  end

  #TODO private?
  def strategy(odds, t, b)
    exp_gain = t.schur(odds)
    w = exp_gain.map { |r| Math.exp(r * b) }
    Probability.new(w)
  end

  def strat(odds, b = @b[-1])
    strategy(odds, @t, b)
  end

  def probable_strat(odds)
    gain_by_pay = @t.schur(odds).map.with_index { |r, i| [i, r] }.to_h
    gain_by_pay.delete_if { |key, val| @t[key] < PROBABLE_EFFICIENCY }
    gain_by_pay = gain_by_pay.sort { |a, b| a[1] <=> b[1] }
    while gain_by_pay[1..-1].sum(0.0) { |e| @t[e[0]] } > PROBABLE_GUARANTY do
      gain_by_pay.shift
    end
    result = Array.new(odds.size, nil)
    gain_by_pay.to_h.each { |key, val| result[key] = PROBABLE_RETURN / odds[key] }
    result
  end

  private

  def adjust_params(odds_list)
    @ini_p ||= Probability.new_from_odds(odds_list[0])
    @t ||= @ini_p.clone
    @a.extend_to!(odds_list.size) if @a.size < odds_list.size
    @b.extend_to!(odds_list.size) if @b.size < odds_list.size
  end

  def validate_params(addition = [])
    warnings = @a.validate('a') + @t.validate('t') + addition
    warnings.each do |warn|
      next if warn.nil?
      @logger.nil? ? puts("[WARN][#{Time.new}] #{warn}") : @logger.warn(warn)
    end
  end

  def update_a(p, odds_list)
    da = grad_a(p, odds_list)
    v = da.map { |da_i| -@eps * da_i }
    @a.move_in_theta!(v, 'a')
  end

  def update_b(p, odds_list)
    db = grad_b(p, odds_list)
    v = db.map { |db_i| -@eps * db_i }
    @b.move_in_theta!(v, 'b')
  end

  def update_t(p, odds_list)
    dt = grad_t(p, odds_list)
    v = dt.map { |dt_i| -@eps * dt_i }
    @t.move_in_theta!(v, 'b')
  end

  def grad_a(p, odds_list)
    @blueprint.map.with_index(1) do |strat, k|
      teacher = Probability.new_from_odds(odds_list[k])
      grad_a_for_instant(p, teacher, strat)
    end
  end

  def grad_b(p, odds_list)
    @blueprint.map.with_index(1) do |strat, k|
      teacher = Probability.new_from_odds(odds_list[k])
      grad_b_for_instant(p, teacher, strat, @a[k], odds_list[k])
    end
  end

  def grad_t(p, odds_list)
    grad_list = @blueprint.map.with_index(1) do |strat, k|
      teacher = Probability.new_from_odds(odds_list[k])
      grad_t_for_instant(p, teacher, strat, @a[k], @b[k], odds_list[k])
    end
    grad_list.transpose.map { |row| row.sum }
  end

  def grad_a_for_instant(p, teacher, strat)
    f = p.map.with_index { |p_i, i| (strat[i] - @ini_p[i]) / p_i }
    -teacher.expectation(f)
  end

  def grad_b_for_instant(p, teacher, strat, a, odds)
    f1 = @t.schur(odds)
    exp_f1 = strat.expectation(f1)
    f2 = p.map.with_index { |p_i, i| a * strat[i] * (f1[i] - exp_f1) / p_i }
    -teacher.expectation(f2)
  end

  def grad_t_for_instant(p, teacher, strat, a, b, odds)
    result = []
    (1..odds.size - 1).each do |j|
      f = p.map.with_index do |p_i, i|
        a * b * strat[i] * (
          odds[j] * (delta(i, j) - strat[j])
          - odds[0] * (delta(i, 0) - strat[0])
        ) / p_i
      end
      result.push -teacher.expectation(f)
    end
    result
  end

  def delta(i, j)
    Probability.delta(i,j)
  end
end
