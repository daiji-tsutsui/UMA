require './lib/uma'

uma = Uma.new(
  driver:     :selenium_chrome_headless,
  day:        Jra::SUNDAY,
  course:     '中山',
  race:       Jra::RACE_11,
  datafile:   'test1',
  duplicate:  true,
  simulate:   true,
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
