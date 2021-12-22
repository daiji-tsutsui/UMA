Dir.glob('./lib/**/*.rb').each do |file|
  require file
  puts file
end
require 'logger'

logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d_%H%M")}.log")
scheduler = Scheduler.new(logger)
fetcher = OddsFetcher.new(
  driver:     :selenium_chrome_headless,
  day:        Jra::SUNDAY,
  course:     '阪神',
  race:       Jra::RACE_12,
  duplicate:  false,
)
manager = DataManager.new("test1")
analyzer = OddsAnalyzer.new(logger)
summarizer = ReportMaker.new(analyzer, logger)

count = 0
summarized = false
converge = false
prev_loss = 0.0
loss = 0.0
logger.info "DataManager got data: #{manager.data}"


fetcher.odds = manager.data
odds_list = manager.odds
while true do
  if scheduler.is_finished
    summarizer.summarize(odds_list[-1]) unless odds_list[-1].nil?
    break
  end
  if scheduler.is_on_fire
    # result = fetcher.run
    # logger.info result unless result.nil?
    odds_list = manager.odds
    manager.save
    converge = false
    summarized = false
  elsif odds_list.size > 1 && !scheduler.is_on_deadline && !converge
    analyzer.update_params(odds_list, with_forecast: true)
    if !summarized
      summarizer.summarize(odds_list[-1])
      summarized = true
    end
    if count % 100 == 0
      loss = analyzer.loss(odds_list).sum
      logger.info "Loss: #{loss}"
      if (loss - prev_loss).abs < 1e-5
        converge = true
        summarizer.summarize(odds_list[-1])
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
# pp "Total loss: #{loss_list.sum}"
