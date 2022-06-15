# frozen_string_literal: true

require 'yaml'

# Read and write odds stream data
class DataManager
  attr_accessor :data

  def initialize(filename, **options)
    base_path = options[:base_path] || './data'
    simulate = options[:simulate] || false
    @filename = if simulate
                  "#{base_path}/#{filename}.yml"
                else
                  "#{base_path}/#{Time.now.strftime('%Y%m%d')}_#{filename}.yml"
                end
    @data = []
    @data = YAML.load_file(@filename) if File.exist? @filename
  end

  def save
    file = File.open(@filename, 'w')
    YAML.dump(@data, file)
    file.close
  end

  def odds
    @data.map { |record| record[:data] }
  end

  def receive(new_data)
    @data.push new_data
  end
end
