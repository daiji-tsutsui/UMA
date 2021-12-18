require 'capybara'
require 'selenium-webdriver'
require './lib/jra/pages'

class OddsFetcher
  attr_accessor :odds

  def initialize(**options)
    @odds = []
    @driver = options[:driver]  || :selenium_chrome_headless
    @day    = options[:day]     || Jra::SUNDAY
    @course = options[:course]  || '阪神'
    @race   = options[:race]    || Jra::RACE_1
    @duplicate = options[:duplicate] || false
  end

  def run
    Capybara.default_driver = @driver
    fetched = false
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
      if @duplicate || current_odds != @odds[-1][:data]
        @odds.push({
          at: Time.now,
          data: current_odds,
        })
        fetched = true
      end
    end
    fetched ? log : "Same odds! Skipped!"
  end

  def log
    odds = @odds[-1]
    unless odds.nil?
      return "Got odds: #{odds[:data]}"
    end
    "Fetcher has no odds!!"
  end

end
