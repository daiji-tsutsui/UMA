# frozen_string_literal: true

require './lib/probability'
require './lib/positives'

# Object class for mathematical model for fitting time series of odds
class OddsAnalyzer
  # t: true distribution
  # a: weight of importance at this moment
  # b: coefficient of certainty at this moment
  attr_accessor :t, :a, :b
  attr_reader :model, :blueprint, :ini_p, :eps

  def initialize(logger = nil)
    @logger = logger
    @a = Probability.new
    @b = Positives.new # @b[0]はdummy
    fetch_env
  end

  # Mathematical model
  def forecast(odds_list)
    adjust_params(odds_list)
    p = @ini_p
    @model = []
    @blueprint = []
    (1..odds_list.size - 1).each do |i|
      odds = odds_list[i - 1]
      a = @a[i] / @a.first(i + 1).sum
      b = @b[i]
      p = forecast_next(p, odds, a, b)
      @model.push p
    end
    @model
  end

  def forecast_next(prev, odds, a, b)
    q = strategy(odds, b)
    @blueprint.push q
    prev.map.with_index { |r, i| ((1.0 - a) * r) + (a * q[i]) }
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
      p = Probability.new_from_odds(odds_list[k + 1])
      p.kl_div(q)
    end
  end

  def strategy(odds, b = @b[-1])
    exp_gain = @t.schur(odds)
    w = exp_gain.map { |r| Math.exp(r * b) }
    Probability.new(w)
  end

  def probable_strat(odds)
    result = Array.new(odds.size, nil)
    exp_gain = @t.schur(odds)
    candidates = truncate(exp_gain)
    candidates.each { |key, _val| result[key] = @probable_return / odds[key] }
    result
  end

  private

  def fetch_env
    @eps = ENV.fetch('ODDS_ANALYZER_LEARNING_RATE', 0.01).to_f
    @probable_efficiency = ENV.fetch('ODDS_ANALYZER_PROBABLE_EFFICIENCY', 0.05).to_f
    @probable_guaranty = ENV.fetch('ODDS_ANALYZER_PROBABLE_GUARANTY', 0.6).to_f
    @probable_return = ENV.fetch('ODDS_ANALYZER_PROBABLE_RETURN', 0.8).to_f
  end

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

  def truncate(exp_gain)
    exp_gain = exp_gain.map.with_index { |r, i| [i, r] }.to_h
    exp_gain.delete_if { |key, _val| @t[key] < @probable_efficiency }
    exp_gain = exp_gain.sort { |a, b| a[1] <=> b[1] }
    exp_gain.shift while exp_gain[1..].map { |e| @t[e[0]] }.sum > @probable_guaranty
    exp_gain.to_h
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
    grad_list.transpose.map(&:sum)
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
        a * b * strat[i] * ((odds[j] * (delta(i, j) - strat[j])) - (odds[0] * (delta(i, 0) - strat[0]))) / p_i
      end
      result.push(-teacher.expectation(f))
    end
    result
  end

  def delta(i, j)
    Probability.delta(i, j)
  end
end
