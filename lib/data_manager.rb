require 'yaml'

class DataManager
  attr_accessor :data

  def initialize(filename, base_url = './data')
    @filename = "#{base_url}/#{filename}.yml"
    @data = []
    if File.exist? @filename
      @data = open(@filename, 'r') { |f| YAML.load(f) }
    end
  end

  def save
    YAML.dump(@data, File.open(@filename, 'w'))
  end

  def log
    puts "[INFO][#{Time.now}] DataManager got data: #{@data}"
  end
end
