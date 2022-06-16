# frozen_string_literal: true

require './lib/scheduler'

# Mock object for OddsFetcher and Scheduler
class Simulator < Scheduler
  # odds:     実行予定データキュー
  # sim_odds: 実行済みデータキュー
  attr_accessor :odds, :sim_odds, :next

  def initialize(logger, odds_list)
    @odds = odds_list
    @sim_odds = []
    @logger = logger
    @first_wait = ENV.fetch('SIMULATOR_FIRST_WAIT', 60).to_i
    @table = schedule(odds_list)
    @start = @table[0]
    # TODO: ここの20[s]も環境変数化したい
    @end = @table[-1] + 20
    @next = @table.shift
  end

  # TODO: runってなんぞ，もっと具体的な名前に
  def run
    if @odds.empty?
      @logger.warn 'Simulator has no odds data in exe queue'
    else
      current = @odds.shift
      @sim_odds.push current
    end
    log
  end

  # TODO: 謎メソッドその２
  def get_odds
    @sim_odds.map { |record| record[:data] }
  end

  private

  def schedule(odds_list)
    start = odds_list[0][:at]
    inc = Time.now + @first_wait - start
    odds_list.map { |record| record[:at] + inc }
  end

  def log
    odds = @sim_odds[-1]
    return "Got odds: #{odds[:data]}" unless odds.nil?

    'Simulator has no odds!!'
  end
end
