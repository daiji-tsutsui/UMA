require 'yaml'

class DataManager
  attr_accessor :data

  def initialize(filename, **options)
    base_path = options[:base_path] || './data'
    simulate = options[:simulate] || false
    unless simulate
      @filename = "#{base_path}/#{Time.now.strftime("%Y%m%d")}_#{filename}.yml"
    else
      @filename = "#{base_path}/#{filename}.yml"
    end
    @data = []
    if File.exist? @filename
      @data = open(@filename, 'r') { |f| YAML.load(f) }
    end
  end

  def save
    YAML.dump(@data, File.open(@filename, 'w'))
  end

  def odds
    @data.map { |record| record[:data] }
  end
end
