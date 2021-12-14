require 'yaml'

class Scheduler
  attr_accessor :next

  def initialize
    input = open('schedule.yaml', 'r') { |f| YAML.load(f) }
    @start = input['start']
    @end = input['end']
    @table = [@start]

    indicator = @start.clone
    rule = input['rule'].shift
    while true do
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
      puts "[INFO][#{Time.now}] Performed!! Next will be performed at #{@next}"
      return true
    end
    false
  end

  def is_finished
    Time.now > @end
  end
end
