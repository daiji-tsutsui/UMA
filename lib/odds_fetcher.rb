require 'capybara'
require 'selenium-webdriver'
require './lib/jra/pages'

# Object class which fetches odds data from JRA page
class OddsFetcher

  attr_accessor :odds

  def initialize(**options)
    @odds = []
    @driver     = options[:driver]    || :selenium_chrome_headless
    @day        = options[:day]       || Jra::SUNDAY
    @course     = options[:course]    || '阪神'
    @race       = options[:race]      || Jra::RACE_11
    @duplicate  = options[:duplicate] || false
  end

  def fetch_new_odds
    fetched = false
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
      if @duplicate || @odds[-1].nil? || current_odds != @odds[-1][:data]
        @odds.push({
          at: Time.now,
          data: current_odds,
        })
        fetched = true
      end
    end
    fetched ? make_log : "Same odds! Skipped!"
  end

  # DataManagerと同期する
  #TODO わかりづらいからインスタンスを共有するのはやめた方がいい
  # DataManagerを親として，DataManagerに最新のオッズを渡すようにすべき
  def sync_data(data_store)
    odds = data_store
  end

  private

  def make_log
    odds = @odds[-1]
    if odds.nil?
      return "Fetcher has no odds!!"
    end
    "Got odds: #{odds[:data]}"
  end
end
