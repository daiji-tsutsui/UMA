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
    s = strategy(odds, b)
    @blueprint.push s
    prev.map.with_index { |r, i| ((1.0 - a) * r) + (a * s[i]) }
  end

  def update_params(odds_list, with_forecast: false)
    with_forecast ? forecast(odds_list) : adjust_params(odds_list)
    @model.each.with_index(1) do |p, m|
      q = Probability.new_from_odds(odds_list[m])
      update_a(m, p, q)
      update_t(m, p, q, odds_list)
      update_b(m, p, q, odds_list)
    end
  end

  def loss(odds_list, with_forecast: false)
    debug_logging if @debug
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
    @eps = ENV.fetch('ODDS_ANALYZER_LEARNING_RATE', 0.001).to_f
    @probable_efficiency = ENV.fetch('ODDS_ANALYZER_PROBABLE_EFFICIENCY', 0.05).to_f
    @probable_guaranty = ENV.fetch('ODDS_ANALYZER_PROBABLE_GUARANTY', 0.6).to_f
    @probable_return = ENV.fetch('ODDS_ANALYZER_PROBABLE_RETURN', 0.8).to_f
    @debug = ENV.fetch('ODDS_ANALYZER_DEBUG', '') == 'true'
  end

  def adjust_params(odds_list)
    @ini_p ||= Probability.new_from_odds(odds_list[0])
    @t ||= @ini_p.clone
    @a.extend_to!(odds_list.size) if @a.size < odds_list.size
    @b.extend_to!(odds_list.size) if @b.size < odds_list.size
  end

  def truncate(exp_gain)
    exp_gain = exp_gain.map.with_index { |r, i| [i, r] }.to_h
    exp_gain.delete_if { |key, _val| @t[key] < @probable_efficiency }
    exp_gain = exp_gain.sort { |a, b| a[1] <=> b[1] }
    exp_gain.shift while exp_gain[1..].map { |e| @t[e[0]] }.sum > @probable_guaranty
    exp_gain.to_h
  end

  def update_a(m, p, q)
    da = grad_a(m, p, q)
    v = da.map { |da_i| -@eps * da_i }
    @a.move_with_natural_grad!(v)
  end

  def update_b(m, p, q, odds_list)
    db = grad_b(m, p, q, odds_list)
    v = db.map { |db_i| -@eps * db_i }
    @b.move_with_natural_grad!(v)
  end

  def update_t(m, p, q, odds_list)
    dt = grad_t(m, p, q, odds_list)
    v = dt.map { |dt_i| -@eps * dt_i }
    @t.move_with_natural_grad!(v)
  end

  def grad_a(m, p, q)
    @blueprint.map.with_index(1) do |strat, k|
      grad_a_for_instant(k, m, p, q, strat)
    end
  end

  def grad_a_for_instant(k, m, p, q, strat)
    alpha = @a.shrink_rate(m)
    f = if k > m
          a = @a.shrink(m)
          p.map.with_index do |p_i, i|
            alpha * (1..m).map { |h| a[h] * (@blueprint[h - 1][i] - @ini_p[i]) / p_i }.sum
          end
        else
          p.map.with_index { |p_i, i| alpha * (strat[i] - @ini_p[i]) / p_i }
        end
    -q.expectation(f)
  end

  def grad_b(m, p, q, odds_list)
    @blueprint.map.with_index(1) do |strat, k|
      grad_b_for_instant(k, m, p, q, strat, odds_list)
    end
  end

  def grad_b_for_instant(k, m, p, q, strat, odds_list)
    return 0.0 if k > m

    a = @a.shrink(m)
    f1 = @t.schur(odds_list[k])
    exp_f1 = strat.expectation(f1)
    f2 = p.map.with_index { |p_i, i| a[k] * strat[i] * (f1[i] - exp_f1) / p_i }
    -q.expectation(f2)
  end

  def grad_t(m, p, q, odds_list)
    (1..@t.size - 1).map do |j|
      grad_t_for_coord_axis(j, m, p, q, odds_list)
    end
  end

  def grad_t_for_coord_axis(j, m, p, q, odds_list)
    a = @a.shrink(m)
    (1..m).inject(0.0) do |sum, k|
      strat = @blueprint[k]
      odds = odds_list[k]
      f = p.map.with_index do |p_i, i|
        strat[i] * (((delta(i, j) - strat[j]) * odds[j]) - ((delta(i, 0) - strat[0]) * odds[0])) / p_i
      end
      sum - (a[k] * @b[k] * q.expectation(f))
    end
  end

  def delta(i, j)
    Probability.delta(i, j)
  end

  def debug_logging
    @logger.debug("t: #{@t}")
    @logger.debug("a: #{@a}")
    @logger.debug("b: #{@b}")
  end
end
