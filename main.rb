# frozen_string_literal: true

require './lib/uma'

# https://sp.jra.jp
uma = Uma.new(
  driver:    :selenium_chrome_headless,
  day:       Jra::SUNDAY,
  course:    '東京',
  race:      Jra::RACE_11,
  datafile:  'UnicornS',
  duplicate: false, # true: オッズの更新がなくても取得する
  # simulate:   false,
  # simfile:    '20211227_test1'
)
uma.run

# p loss_list = analyzer.loss(odds_list, with_forecast: true)
# # p analyzer.model
# pp "Total loss: #{loss_list.sum}"
