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
manager = DataManager.new('test2')
puts "[INFO][#{Time.now}] manager got data: #{manager.data}"

while true do
  break if scheduler.is_finished
  fetcher.run if scheduler.is_on_fire
  sleep 1
end
manager.data = fetcher.odds
manager.save
