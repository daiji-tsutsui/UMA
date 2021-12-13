require 'capybara'
require 'selenium-webdriver'
require './lib/jra/pages'

class OddsFetcher
  attr_accessor :odds

  def initialize(driver, day, course, race)
    @odds = []
    @driver = driver
    @day = day
    @course = course
    @race = race
  end

  def run
    Capybara.default_driver = @driver
    Capybara::Session.new(@driver).tap do |s|
      # トップページ
      top_page = Jra::TopPage.new
      top_page.load
      # コース選択ページ
      odds_page = top_page.go_odds
      race_odds_page = odds_page.go_course(@day, @course)
      # 単勝・複勝ページ
      single_odds_page = race_odds_page.go_single_odds(@race)
      current_odds = single_odds_page.get_tan_odds
      @odds.push current_odds
      puts "[INFO][#{Time.now}] Got odds: #{current_odds}"
    end
  end

end
