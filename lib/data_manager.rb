require 'yaml'

# Read and write odds stream data
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
      @data = YAML.load_file(@filename)
    end
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
