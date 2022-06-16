# frozen_string_literal: true

require 'yaml'

# Read schedule.yaml and make schedule for fetching odds data
class Scheduler
  attr_accessor :next

  def initialize(logger)
    input = YAML.load_file('schedule.yaml')
    @start = input['start']
    @end = input['end']
    @table = [@start]
    @logger = logger

    indicator = @start.clone
    rule = input['rule'].shift
    while true
      if rule['until'].nil?
        if rule['duration'] <= 0
          rule = get_new_rule(input['rule'])
          rule.nil? ? break : next
        end
        rule['duration'] -= rule['interval']
      else
        if indicator >= rule['until']
          rule = get_new_rule(input['rule'])
          rule.nil? ? break : next
        end
      end
      indicator += rule['interval']
      break if indicator > @end
      @table.push indicator
    end
    @next = @table.shift
  end

  def wait
    return if finished?
    while true
      break if on_fire?

      sleep 10
    end
  end

  def on_fire?
    return false if finished?
    if Time.now > @next
      @next = @table.shift
      @next = @end if @next.nil?
      @logger.info "Performed!! Next will be performed at #{@next}"
      return true
    end
    false
  end

  def on_deadline?
    return true if Time.now > @next - 10

    false
  end

  def finished?
    Time.now > @end
  end

  private

  def get_new_rule(rules)
    rules.shift
  end
end
