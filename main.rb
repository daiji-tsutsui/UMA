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

fetcher.odds = manager.data
while true do
  break if scheduler.is_finished
  if scheduler.is_on_fire
    fetcher.run
  end
  sleep 1
end
manager.save
