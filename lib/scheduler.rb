# frozen_string_literal: true

require 'yaml'

# Read schedule.yaml and make schedule for fetching odds data
class Scheduler
  attr_accessor :next

  def initialize(logger)
    @logger = logger

    input = YAML.load_file('schedule.yaml')
    @start = input['start']
    @end = input['end']
    @table = make_time_table(input)
    @next = @table.shift
  end

  def wait
    return if finished?

    sleep 10 until on_fire?
  end

  def on_fire?
    return false if finished? || Time.now <= @next

    # TODO: ブロックを受け取って本当にperformする仕組みにする？
    # とりあえずbooleanのメソッドでperformしてるのは変
    perform
    true
  end

  def on_deadline?
    # TODO: 10[s]を環境変数にしたい
    Time.now > @next - 10
  end

  def finished?
    Time.now > @end
  end

  private

  def make_time_table(input)
    result = []
    rule = input['rule'].shift
    indicator = @start.clone
    while indicator < @end
      result.push(indicator)
      rule = input['rule'].shift if require_next_rule?(rule, indicator)
      break if rule.nil?

      indicator = calculate_next_schedule(rule, indicator)
    end
    result
  end

  def require_next_rule?(rule, indicator)
    return true if !rule['duration'].nil? && rule['duration'] <= 0
    return true if !rule['until'].nil? && indicator >= rule['until']

    false
  end

  def calculate_next_schedule(rule, indicator)
    rule['duration'] -= rule['interval'] unless rule['duration'].nil?
    indicator + rule['interval']
  end

  def perform
    @next = @table.shift || @end
    @logger.info "Performed!! Next will be performed at #{@next}"
  end
end
