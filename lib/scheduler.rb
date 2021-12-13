require 'yaml'

class Scheduler
  attr_accessor :next

  def initialize
    input = open('schedule.yaml', 'r') { |f| YAML.load(f) }
    @start = input["start"]
    @end = input["end"]
    @table = [@start]

    indicator = @start.clone
    rule = input["rule"].shift
    while true do
      if indicator >= rule["until"]
        rule = input["rule"].shift
        break if rule.nil?
        next
      end
      indicator += rule["freq"]
      break if indicator > @end
      @table.push indicator
    end
    @next = @table.shift
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
      puts "[INFO][#{Time.now}] Performed!! Next will be performed at #{@next}"
      return true
    end
    false
  end

  def is_finished
    Time.now > @end
  end
end
