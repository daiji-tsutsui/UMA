# frozen_string_literal: true

require 'logger'
require "./lib/report_maker"
require "./lib/data_manager"
require "./lib/scheduler"
require "./lib/odds_analyzer"
require "./lib/odds_fetcher"
require "./lib/simulator"

# Wrapper class which integrates the object classes above
class Uma
  attr_accessor :converge, :summarized

  def initialize(**options)
    @simulate = options[:simulate]
    unless @simulate
      @manager = DataManager.new(options[:datafile])
      @logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d_%H%M")}.log")
      #TODO options渡すのよくない
      @fetcher = OddsFetcher.new(@logger, options)
      @scheduler = Scheduler.new(@logger)
    else
      @manager = DataManager.new(options[:simfile], simulate: true)
      @logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d_%H%M")}_#{options[:simfile]}.log")
      @fetcher = Simulator.new(@logger, @manager.data)
      @scheduler = @fetcher
    end
    @analyzer = OddsAnalyzer.new(@logger)
    @summarizer = ReportMaker.new(@analyzer, @logger)

    get_odds
    @logger.info "DataManager got data: #{@manager.data}"
    init_params
  end

  def run
    #TODO fetch_new_oddsにできれば統一したい（無理なら構わない）
    if @simulate
      result = @fetcher.run
      @logger.info result unless result.nil?
    else
      new_odds = @fetcher.fetch_new_odds
      @manager.receive(new_odds)
    end
    get_odds
    init_flags
  end

  def learn(check_loss: false)
    @analyzer.update_params(@odds_list, with_forecast: true)
    summarize
    if check_loss
      loss = @analyzer.loss(@odds_list).sum
      @logger.info "Loss: #{loss}"
      summarize(force: true) if check_conv(loss)
      @prev_loss = loss
    end
  end

  #TODO private?
  def summarize(force: false)
    if force || !@summarized
      @summarizer.summarize(@odds_list[-1])
    end
    @summarized = true
  end

  def finalize
    if is_finished
      get_odds
      odds = @odds_list[-1]
      @summarizer.summarize(odds) unless odds.nil?
      return true
    end
    false
  end

  def is_finished
    @scheduler.is_finished
  end

  def is_on_fire
    @scheduler.is_on_fire
  end

  def is_on_learning
    @odds_list.size > 1 && !@scheduler.is_on_deadline && !@converge
  end

  #TODO private?
  def save
    @manager.save unless @simulate
  end

  private

  def init_flags
    @converge = false
    @summarized = false
  end

  def init_params
    init_flags
    @prev_loss = 0.0
  end

  def get_odds
    #TODO OddsFetcher#fetch_new_oddsと紛らわしいから名前なんとかしよう
    @odds_list = (@simulate ? @fetcher.get_odds : @manager.odds)
    save
  end

  def check_conv(loss)
    if (loss - @prev_loss).abs < 1e-5
      @converge = true
      @logger.info "Fitting converges!"
      return true
    end
    false
  end
end
