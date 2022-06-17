# frozen_string_literal: true

require 'data_manager'
require 'fileutils'

RSpec.describe DataManager do
  describe '#new' do
    context 'pursuit streaming odds' do
      it 'makes empty data for a new stream' do
        obj = DataManager.new('new_stream')
        expect(obj.data).to eq []
      end
      it 'reads data file for an ongoing stream' do
        filename = "./data/#{Time.now.strftime('%Y%m%d')}_ongoing_stream.yml"
        FileUtils.cp('./data/dummy_for_test.yml', filename)
        obj = DataManager.new('ongoing_stream')
        expect(obj.data[0][:at].to_s).to eq '2021-12-15 02:09:42 +0900'
        expect(obj.data[0][:data].size).to eq 14
        FileUtils.rm(filename)
      end
    end
    context 'simulation of past race' do
      it 'with non-existing file name makes vacant data' do
        obj = DataManager.new('non_existing_file', simulate: true)
        expect(obj.data).to eq []
      end
      it 'with existing file name reads data from file' do
        obj = DataManager.new('dummy_for_test', simulate: true)
        expect(obj.data[0][:at].to_s).to eq '2021-12-15 02:09:42 +0900'
        expect(obj.data[0][:data].size).to eq 14
      end
    end
  end

  describe '#save' do
    before do
      @obj = DataManager.new('save_test')
      @obj.data.push({
        at:   Time.local(1993, 4, 17),
        data: [4.0, 4.0, 2.0],
      })
      @filename = "./data/#{Time.now.strftime('%Y%m%d')}_save_test.yml"
    end
    after do
      FileUtils.rm(@filename)
    end

    it 'writes data into a file' do
      @obj.save
      expect(File.exist?(@filename)).to be_truthy
    end
    it 'writes correct data' do
      @obj.save
      data = YAML.load_file(@filename, {})
      expect(data[0][:at].to_s).to eq '1993-04-17 00:00:00 +0900'
      expect(data[0][:data]).to eq [4.0, 4.0, 2.0]
    end
  end

  describe '#odds' do
    before do
      @obj = DataManager.new('odds_test')
      @obj.data.push({
        at:   Time.local(1993, 4, 17),
        data: [4.0, 4.0, 2.0],
      })
    end

    it 'gives odds data as a two-dim array' do
      expect(@obj.odds.class.to_s).to eq 'Array'
      expect(@obj.odds.size).to eq 1
      expect(@obj.odds[0].class.to_s).to eq 'Array'
      expect(@obj.odds[0].size).to eq 3
    end
  end
end
