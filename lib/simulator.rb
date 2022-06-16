# frozen_string_literal: true

require './lib/scheduler'

# Mock object for OddsFetcher and Scheduler
class Simulator < Scheduler
  # queue:     実行予定データキュー
  # simulated: 実行済みデータキュー
  attr_accessor :queue, :simulated, :next

  def initialize(logger, odds_list)
    @queue = odds_list
    @simulated = []
    @logger = logger
    @first_wait = ENV.fetch('SIMULATOR_FIRST_WAIT', 60).to_i
    @table = schedule(odds_list)
    @start = @table[0]
    # TODO: ここの20[s]も環境変数化したい
    @end = @table[-1] + 20
    @next = @table.shift
  end

  def fetch_new_odds
    if @queue.empty?
      @logger.warn 'Simulator has no odds data in execution queue'
    else
      new_odds = @queue.shift
      @simulated.push new_odds
    end
    logging(@simulated[-1])
  end

  def odds
    @simulated.map { |record| record[:data] }
  end

  private

  def schedule(odds_list)
    start = odds_list[0][:at]
    inc = Time.now + @first_wait - start
    odds_list.map { |record| record[:at] + inc }
  end

  def logging(odds)
    unless odds.nil?
      @logger.info "Got odds: #{odds[:data]}"
      return
    end
    @logger.warn 'Simulator has no odds!!'
  end
end
