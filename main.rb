# frozen_string_literal: true

require './lib/uma'

# https://sp.jra.jp
uma = Uma.new(
  driver:    :selenium_chrome_headless,
  day:       Jra::SATURDAY,
  course:    '東京',
  race:      Jra::RACE_11,
  datafile:  'EpsomCup',
  duplicate: false, # true: オッズの更新がなくても取得する
  simulate:  true,
  simfile:   '20220612_EpsomCup',
)

count = 0
until uma.finished?
  if uma.on_fire?
    uma.update
  elsif uma.on_learning?
    (count % 100).zero? ? uma.learn(check_loss: true) : uma.learn
    sleep 0.02
  else
    sleep 1
  end
  count += 1
end
uma.finalize

# p loss_list = analyzer.loss(odds_list, with_forecast: true)
# # p analyzer.model
# pp "Total loss: #{loss_list.sum}"
