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
# while true do
#   break if scheduler.is_finished
#   if scheduler.is_on_fire
#     # result = fetcher.run
#     # logger.info result if !result.nil?
#     odds_list = manager.odds
#     converge = false
#   elsif !scheduler.is_on_deadline && !converge
#     analyzer.update_params(odds_list, with_forecast: true)
#     if count % 100 == 0
#       loss = analyzer.loss(odds_list).sum
#       logger.info "Loss: #{loss}"
#       if (loss - prev_loss).abs < 1e-4
#         converge = true
#         logger.info "Fitting converges!"
#       end
#       prev_loss = loss
#     end
#     sleep 0.02
#   else
#     sleep 1
#   end
#   count += 1
# end
# manager.save

p loss_list = analyzer.loss(odds_list, with_forecast: true)
# # p analyzer.model
pp "Total loss: #{loss_list.sum}"

def summarize(analyzer, odds)
  col_num = analyzer.a.size
  columns = " time |"
  a_values = "    a |"
  b_values = "    b |"
  col_num.times do |i|
    columns += sprintf("%9d", i) + " |"
    a_values += sprintf("%9.5f", analyzer.a[i]) + " |"
    b_values += sprintf("%9.5f", analyzer.b[i]) + " |"
  end
  puts "Summary:"
  puts columns
  puts columns.gsub(/[^\|]/, '-').gsub(/\|/, '+')
  puts a_values
  puts b_values

  col_num = analyzer.t.size
  strat = analyzer.strat(odds)
  columns = " horse |"
  t_values = "     t |"
  o_values = "  odds |"
  s_values = " strat |"
  col_num.times do |i|
    columns += sprintf("%9d", i + 1) + " |"
    t_values += sprintf("%9.5f", analyzer.t[i]) + " |"
    o_values += sprintf("%9.1f", odds[i]) + " |"
    s_values += sprintf("%9.5f", strat[i]) + " |"
  end
  puts ""
  puts columns
  puts columns.gsub(/[^\|]/, '-').gsub(/\|/, '+')
  puts t_values
  puts o_values
  puts s_values
end


summarize(analyzer, odds_list[-1])
