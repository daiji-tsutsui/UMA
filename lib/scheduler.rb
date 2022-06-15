# frozen_string_literal: true

require 'yaml'

# Read schedule.yaml and make schedule for fetching odds data
class Scheduler
  attr_accessor :next

  def initialize(logger)
    # input = open('schedule.yaml', 'r') { |f| YAML.load(f) }
    input = YAML.load_file('schedule.yaml')
    @start = input['start']
    @end = input['end']
    @table = [@start]
    @logger = logger

    indicator = @start.clone
    rule = input['rule'].shift
    while true
      if !rule['until'].nil?
        if indicator >= rule['until']
          rule = get_new_rule(input['rule'])
          rule.nil? ? break : next
        end
      else
        if rule['duration'] <= 0
          rule = get_new_rule(input['rule'])
          rule.nil? ? break : next
        end
        rule['duration'] -= rule['interval']
      end
      indicator += rule['interval']
      break if indicator > @end
      @table.push indicator
    end
    @next = @table.shift
  end

  # TODO: privateでよくない？
  def get_new_rule(rules)
    rules.shift
  end

  def wait
    return if is_finished
    while true do
      break if is_on_fire
      sleep 10
    end
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
end
