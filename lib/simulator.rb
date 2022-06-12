# Mock object for OddsFetcher and Scheduler
class Simulator
  attr_accessor :odds         # 実行予定データキュー
  attr_accessor :sim_odds     # 実行済みデータキュー
  attr_accessor :next

  def initialize(logger, odds_list)
    @odds = odds_list
    @sim_odds = []
    @logger = logger
    @first_wait = (ENV['SIMULATOR_FIRST_WAIT'] || 60).to_i
    schedule
  end

  def run
    if @odds.size > 0
      current = @odds.shift
      @sim_odds.push current
    else
      @logger.warn "Simulator has no odds data in exe queue"
    end
    log
  end

  def get_odds
    @sim_odds.map { |record| record[:data] }
  end

  def is_on_fire
    return false if is_finished
    if Time.now > @next
      @next = @table.shift
      @next = @end if @next.nil?
      @logger.info "Performed!! Next will be performed at #{@next}"
      return true
    end
    false
  end

  def is_on_deadline
    if Time.now > @next - 10
      return true
    end
    false
  end

  def is_finished
    Time.now > @end
  end

  private

  def schedule
    start = @odds[0][:at]
    inc = Time.now + @first_wait - start
    @table = @odds.map { |record| record[:at] + inc }
    @start = @table[0]
    @end = @table[-1] + 20
    @next = @table.shift
  end

  def log
    odds = @sim_odds[-1]
    unless odds.nil?
      return "Got odds: #{odds[:data]}"
    end
    "Simulator has no odds!!"
  end

end
