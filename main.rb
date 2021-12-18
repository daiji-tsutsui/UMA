Dir.glob('./lib/**/*.rb').each do |file|
  require file
  puts file
end
require 'logger'

logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d")}.log")
scheduler = Scheduler.new(logger)
fetcher = OddsFetcher.new(
  driver: :selenium_chrome_headless,
  day: Jra::SUNDAY,
  course: '阪神',
  race: Jra::RACE_11,
)
manager = DataManager.new('dummy2')
# manager = DataManager.new('test5')
analyzer = OddsAnalyzer.new(logger)

# logger.info "DataManager got data: #{manager.data}"
#
# fetcher.odds = manager.data
# while true do
#   break if scheduler.is_finished
#   if scheduler.is_on_fire
#     result = fetcher.run
#     logger.info result if !result.nil?
#   end
#   sleep 1
# end
# manager.save

p odds_list = manager.odds
puts "odds_list.size: #{odds_list.size}"
start = Time.now
1001.times do |t|
  analyzer.update_params(odds_list, with_forecast: true)
  if t % 10 == 0
    puts "Count: #{t}, Time elapsed: #{Time.now - start}"
    puts "Loss: #{analyzer.loss(odds_list)}"
    # puts "a: #{analyzer.a}"
    # puts "b: #{analyzer.b}"
    # puts "t: #{analyzer.t}"
  end
end

p loss_list = analyzer.loss(odds_list, with_forecast: true)
# p analyzer.model
logger.info "Total loss: #{loss_list.sum}"
pp analyzer
