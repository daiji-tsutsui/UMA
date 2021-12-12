require 'capybara'
require 'selenium-webdriver'
Dir.glob('./lib/**/*.rb').each do |file|
  require file
  puts file
end


Capybara.default_driver = :selenium_chrome

scheduler = Scheduler.new

Capybara::Session.new(:selenium_chrome).tap { |session|
  while true do
    break if scheduler.is_finished
    puts "Fire at #{Time.now}" if scheduler.is_on_fire
    sleep 1
  end
  # top_page = Jra::TopPage.new
  # top_page.load
  #
  # odds_page = top_page.go_odds
  # race_odds_page = odds_page.go_course(Jra::SUNDAY, '阪神')
  #
  # single_odds_page = race_odds_page.go_single_odds(Jra::RACE_11)
  # pp single_odds_page.get_uma_name
  # pp single_odds_page.get_tan_odds
  # pp single_odds_page.get_fuku_odds
  # sleep 5
}
