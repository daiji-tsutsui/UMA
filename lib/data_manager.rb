require 'yaml'

class DataManager
  attr_accessor :data

  def initialize(filename, base_url = './data')
    @filename = "#{base_url}/#{Time.now.strftime("%Y%m%d")}_#{filename}.yml"
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
