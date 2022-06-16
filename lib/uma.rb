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
    update_odds_list
    init_params
    @logger.info "DataManager got data: #{@manager.data}"
  end

  def update
    new_odds = @fetcher.fetch_new_odds
    @manager.receive(new_odds) unless @simulate
    update_odds_list
    init_flags
  end

  def learn(check_loss: false)
    @analyzer.update_params(@odds_list, with_forecast: true)
    summarize
    return unless check_loss

    loss = @analyzer.loss(@odds_list).sum
    logging_loss(loss)
  end

  def finalize
    return unless finished?

    update_odds_list
    summarize(force: true)
  end

  def finished?
    @scheduler.finished?
  end

  def on_fire?
    @scheduler.on_fire?
  end

  def on_learning?
    @odds_list.size > 1 && !@scheduler.on_deadline? && !@converge
  end

  private

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
    save
  end

  def save
    @manager.save unless @simulate
  end

  def logging_loss(loss)
    @logger.info "Loss: #{loss}"
    summarize(force: true) if check_conv(loss)
    store_loss(loss)
  end

  def check_conv(loss)
    return false unless (loss - @prev_loss).abs < 1e-5

    @converge = true
    @logger.info 'Fitting converges!'
    true
  end

  def store_loss(loss)
    @prev_loss = loss
  end
end
