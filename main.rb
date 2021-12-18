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

count = 0
converge = false
prev_loss = 0.0
loss = 0.0
logger.info "DataManager got data: #{manager.data}"

fetcher.odds = manager.data
odds_list = manager.odds
while true do
  break if scheduler.is_finished
  if scheduler.is_on_fire
    # result = fetcher.run
    # logger.info result if !result.nil?
    odds_list = manager.odds
    converge = false
  elsif !scheduler.is_on_deadline && !converge
    analyzer.update_params(odds_list, with_forecast: true)
    if count % 100 == 0
      loss = analyzer.loss(odds_list).sum
      logger.info "Loss: #{loss}"
      if (loss - prev_loss).abs < 1e-4
        converge = true
        logger.info "Fitting converges!"
      end
      prev_loss = loss
    end
    sleep 0.02
  else
    sleep 1
  end
  count += 1
end
manager.save

# p loss_list = analyzer.loss(odds_list, with_forecast: true)
# # p analyzer.model
# logger.info "Total loss: #{loss_list.sum}"
# pp "a: #{analyzer.a}"
# pp "b: #{analyzer.b}"
# pp "t: #{analyzer.t}"
