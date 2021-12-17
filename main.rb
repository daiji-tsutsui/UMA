Dir.glob('./lib/**/*.rb').each do |file|
  require file
  puts file
end

scheduler = Scheduler.new
fetcher = OddsFetcher.new(
  :selenium_chrome_headless,
  Jra::SUNDAY,
  '阪神',
  Jra::RACE_11
)
manager = DataManager.new('dummy1')
manager.log
analyzer = OddsAnalyzer.new

# fetcher.odds = manager.data
# while true do
#   break if scheduler.is_finished
#   if scheduler.is_on_fire
#     fetcher.run
#   end
#   sleep 1
# end
# manager.save

# while true do
#
# end

odds_list = manager.data.map { |record| record[:data] }
p analyzer.forecast(odds_list)
pp analyzer
p loss_list = analyzer.loss(odds_list)
puts "[INFO] total loss: #{loss_list.sum}"
