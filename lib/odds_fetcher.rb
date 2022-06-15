# frozen_string_literal: true

require 'capybara'
require 'selenium-webdriver'
require './lib/jra/pages'

# Object class which fetches odds data from JRA page
class OddsFetcher

  attr_accessor :odds

  def initialize(logger, **options)
    @odds = []
    @logger = logger
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
    newest_odds_with_logging(fetched)
  end

  private

  def newest_odds_with_logging(fetched)
    unless fetched
      @logger.info 'Same odds! Skipped!'
      return nil
    end
    odds = @odds[-1]
    log = odds.nil? ? 'Fetcher has no odds!!' : "Got odds: #{odds[:data]}"
    @logger.info log
    odds
  end
end
