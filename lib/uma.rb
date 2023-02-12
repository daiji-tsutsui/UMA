# frozen_string_literal: true

require 'logger'
require './lib/report_maker'
require './lib/data_manager'
require './lib/scheduler'
require './lib/odds_analyzer'
require './lib/odds_fetcher'
require './lib/simulator'

# Wrapper class which integrates the object classes above
class Uma
  attr_accessor :converge, :summarized

  def initialize(**options)
    @simulate = options[:simulate]
    @simulate ? init_simulator(options[:simfile]) : init_runner(options)
    @analyzer = OddsAnalyzer.new(@logger)
    @summarizer = ReportMaker.new(@analyzer, @logger)
    fetch_env
    update_odds_list
    init_params
    @logger.info "DataManager got data: #{@manager.data}"
  end

  def run
    count = 0
    until @scheduler.finished?
      count += 1
      next if done_update?
      next if done_learning_with_sleep?(count)

      sleep @idle_wait
    end
    finalize
  end

  private

  def fetch_env
    @learn_interval = ENV.fetch('UMA_LEARNING_INTERVAL', 100).to_i
    @learn_wait = ENV.fetch('UMA_LEARNING_WAIT', 0.02).to_f
    @idle_wait = ENV.fetch('UMA_IDLING_WAIT', 1.0).to_f
    @error_tolerance = ENV.fetch('UMA_CONVERGE_ERROR_TOLERANCE', 1e-5).to_f
  end

  def done_update?
    return false unless @scheduler.on_fire?

    update
    true
  end

  def update
    summarize(force: true)
    new_odds = @fetcher.fetch_new_odds
    @manager.receive(new_odds) unless @simulate
    update_odds_list
    init_flags
  end

  def done_learning_with_sleep?(count)
    return false unless on_learning?

    (count % @learn_interval).zero? ? learn(check_loss: true) : learn
    sleep @learn_wait
    true
  end

  def learn(check_loss: false)
    @analyzer.update_params(@odds_list, with_forecast: true)
    summarize
    return unless check_loss

    loss = @analyzer.loss(@odds_list).sum
    logging_loss(loss)
  end

  def finalize
    return unless @scheduler.finished?

    update_odds_list
    summarize(force: true)
  end

  def on_learning?
    @odds_list.size > 1 && !@scheduler.on_deadline? && !@converge
  end

  def init_runner(options)
    @manager = DataManager.new(options[:datafile])
    @logger = Logger.new("./log/#{Time.now.strftime('%Y%m%d_%H%M')}.log")
    # TODO: options渡すのよくない
    @fetcher = OddsFetcher.new(@logger, options)
    @scheduler = Scheduler.new(@logger)
  end

  def init_simulator(filename)
    @manager = DataManager.new(filename, simulate: true)
    @logger = Logger.new("./log/#{Time.now.strftime('%Y%m%d_%H%M')}_#{filename}.log")
    @fetcher = Simulator.new(@logger, @manager.data)
    @scheduler = @fetcher
  end

  def summarize(force: false)
    @summarizer.summarize(@odds_list[-1]) if force || !@summarized
    @summarized = true
  end

  def init_params
    init_flags
    @prev_loss = 0.0
  end

  def init_flags
    @converge = false
    @summarized = false
  end

  def update_odds_list
    @odds_list = (@simulate ? @fetcher.odds : @manager.odds)
    @manager.save unless @simulate
  end

  def logging_loss(loss)
    @logger.info "Loss: #{loss}"
    summarize(force: true) if converge?(loss)
    @prev_loss = loss
  end

  def converge?(loss)
    return false unless (loss - @prev_loss).abs < @error_tolerance

    @converge = true
    @logger.info 'Fitting converges!'
    true
  end
end
