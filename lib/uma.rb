require 'logger'
require "./lib/report_maker"
require "./lib/data_manager"
require "./lib/scheduler"
require "./lib/odds_analyzer"
require "./lib/odds_fetcher"


class Uma
  attr_accessor :converge, :summarized

  def initialize(**options)
    @logger = Logger.new("./log/#{Time.now.strftime("%Y%m%d_%H%M")}.log")
    @scheduler = Scheduler.new(@logger)
    @fetcher = OddsFetcher.new(options)
    @manager = DataManager.new(options[:datafile])
    @analyzer = OddsAnalyzer.new(@logger)
    @summarizer = ReportMaker.new(@analyzer, @logger)

    @logger.info "DataManager got data: #{@manager.data}"
    @fetcher.odds = @manager.data
    get_odds
    @converge = false
    @summarized = false
    @prev_loss = 0.0
  end

  def run
    result = @fetcher.run
    @logger.info result unless result.nil?
    get_odds
    @converge = false
    @summarized = false
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

  def save
    @manager.save
  end

  private

    def get_odds
      @odds_list = @manager.odds
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
