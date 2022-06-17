# frozen_string_literal: true

require './lib/scheduler'

# Mock object for OddsFetcher and Scheduler
class Simulator < Scheduler
  # queue:     実行予定データキュー
  # simulated: 実行済みデータキュー
  attr_accessor :queue, :simulated

  def initialize(logger, odds_list)
    @queue = odds_list
    @simulated = []
    @first_wait = ENV.fetch('SIMULATOR_FIRST_WAIT', 60).to_i
    @end_wait = ENV.fetch('SIMULATOR_END_WAIT', 20).to_i
    super(logger)
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

  def initialize_time_table
    @table = schedule(@queue)
    @start = @table[0]
    @end = @table[-1] + @end_wait
  end

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
