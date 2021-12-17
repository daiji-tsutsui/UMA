Dir.glob('./lib/**/*.rb').each do |file|
  require file
  puts file
end
require 'logger'

logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d")}.log")
scheduler = Scheduler.new(logger)
fetcher = OddsFetcher.new(
  :selenium_chrome_headless,
  Jra::SUNDAY,
  '阪神',
  Jra::RACE_1
)
# manager = DataManager.new('dummy1')
manager = DataManager.new('test4')
analyzer = OddsAnalyzer.new

logger.info "DataManager got data: #{manager.data}"

fetcher.odds = manager.data
while true do
  break if scheduler.is_finished
  if scheduler.is_on_fire
    fetcher.run
    logger.info fetcher.log
  end
  sleep 1
end
manager.save

# while true do
#
# end

odds_list = manager.data.map { |record| record[:data] }
p analyzer.forecast(odds_list)
pp analyzer
p loss_list = analyzer.loss(odds_list)
logger.info "Total loss: #{loss_list.sum}"
