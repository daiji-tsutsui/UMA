require './lib/uma'

# https://sp.jra.jp
uma = Uma.new(
  driver:     :selenium_chrome_headless,
  day:        Jra::SUNDAY,
  course:     '東京',
  race:       Jra::RACE_12,
  datafile:   '20220612-R12',
  duplicate:  false,        # true: オッズの更新がなくても取得する
  simulate:   false,
  simfile:    '20211227_test1'
)

count = 0
while true do
  break if uma.finalize
  if uma.is_on_fire
    uma.run
  elsif uma.is_on_learning
    count % 100 == 0 ? uma.learn(check_loss: true) : uma.learn
    sleep 0.02
  else
    sleep 1
  end
  count += 1
end
uma.save

# p loss_list = analyzer.loss(odds_list, with_forecast: true)
# # p analyzer.model
# pp "Total loss: #{loss_list.sum}"
