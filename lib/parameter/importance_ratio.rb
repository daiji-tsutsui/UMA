# frozen_string_literal: true

require './lib/probability'

# Sequence of importance weights at each moment
class ImportanceRatio < Probability
  def initialize(eps)
    super
    @eps = eps
  end

  def adjust(trg_size, ini_p)
    @ini_p ||= ini_p
    extend_to!(trg_size) if size < trg_size
  end

  def update(p, odds_list, strategies)
    df = gradient(p, odds_list, strategies)
    v = df.map { |df_i| -@eps * df_i }
    move_in_theta!(v, 'a')
  end

  private

  def gradient(p, odds_list, strategies)
    strategies.map.with_index(1) do |strat, k|
      teacher = Probability.new_from_odds(odds_list[k])
      gradient_for_instant(p, teacher, strat)
    end
  end

  def gradient_for_instant(p, teacher, strat)
    f = p.map.with_index { |p_i, i| (strat[i] - @ini_p[i]) / p_i }
    -teacher.expectation(f)
  end
end
