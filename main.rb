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
manager = DataManager.new('test3')
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

odds = [9.4, 57.3, 89.5, 46.0, 1.7, 16.8, 19.9, 7.0, 89.8, 90.5, 40.4, 14.6, 8.1, 46.4]
p = analyzer.odds_to_prob([9.4, 57.3, 89.5, 46.0, 1.7, 16.8, 19.9, 7.0, 89.8, 90.5, 40.4, 14.6, 8.1, 46.4])
q = analyzer.odds_to_prob([9.4, 57.7, 90.0, 46.3, 1.7, 16.9, 19.9, 7.0, 89.3, 91.0, 40.3, 14.6, 8.1, 46.4])
r = analyzer.odds_to_prob([9.5, 60.5, 93.9, 48.5, 1.6, 17.5, 20.2, 7.0, 93.8, 91.4, 41.3, 15.1, 8.1, 48.7])
one = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
one = analyzer.odds_to_prob(one)
p analyzer.forecast_next(one, odds, r, 1.0, 0.1)
p analyzer.forecast_next(one, odds, r, 1.0, 1.0)
p analyzer.forecast_next(one, odds, r, 1.0, 10.0)
