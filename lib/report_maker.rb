# frozen_string_literal: true

require './lib/probability'

# Make instant summary and output to log file
class ReportMaker
  attr_accessor :report

  FORMAT_D_TIME = '%9d'
  FORMAT_F_TIME = '%9.5f'
  LABEL_STRLEN_TIME = 10
  FORMAT_D_HORSE = '%9d'
  FORMAT_F_HORSE = '%9.5f'
  FORMAT_STRLEN_HORSE = 9
  LABEL_STRLEN_HORSE = 14
  JRA_RETURN_RATE = 0.8

  def initialize(analyzer, logger)
    @analyzer = analyzer
    @logger = logger
  end

  def summarize(odds)
    @report = "Summary:\n\n"
    @report += summarize_time_series + "\n"
    @report += summarize_horse_info(odds) unless @analyzer.t.nil?
    @logger.info @report
    @report
  end

  private

  def summarize_time_series
    summary = columns_time_series(@analyzer.a.size)
    summary += row_time_series(@analyzer.a, 'weight')
    summary += row_time_series(@analyzer.b, 'certainty')
    summary
  end

  def summarize_horse_info(odds)
    opt_odds = @analyzer.t.map { |r| JRA_RETURN_RATE / r }
    summary = columns_horse_info(@analyzer.t.size)
    summary += row_horse_info(@analyzer.t, 'probability', '%9.5f')
    summary += row_horse_info(odds, 'current odds', '%9.1f')
    summary += row_horse_info(opt_odds, 'optimal odds', '%9.1f')
    summary += row_horse_info(@analyzer.strat(odds, 1.0), 'weak strat', '%9.5f', @analyzer.t.schur(odds))
    summary += row_horse_info(@analyzer.strat(odds, 10.0), 'strong strat', '%9.5f', @analyzer.t.schur(odds))
    summary += row_horse_info(@analyzer.probable_strat(odds), 'probable st.', '%9.5f')
    summary
  end

  def columns_time_series(col_num, format: FORMAT_D_TIME)
    columns = 'time'.rjust(LABEL_STRLEN_TIME) + ' |'
    col_num.times do |i|
      columns += sprintf(format, i) + ' |'
    end
    columns += "\n"
    columns += columns.gsub(/[^|\n]/, '-').gsub(/\|/, '+')
    columns
  end

  def row_time_series(array, label, format: FORMAT_F_TIME)
    row = label.rjust(LABEL_STRLEN_TIME) + ' |'
    array.each do |elem|
      row += sprintf(format, elem)
      row += ' |'
    end
    row += "\n"
    row
  end

  def columns_horse_info(col_num, format: FORMAT_D_HORSE)
    columns = 'horse'.rjust(LABEL_STRLEN_HORSE) + ' |'
    col_num.times do |i|
      columns += sprintf(format, i + 1) + ' |'
    end
    columns += 'expect'.rjust(9)
    columns += "\n"
    columns += columns.gsub(/[^|\n]/, '-').gsub(/\|/, '+')
    columns
  end

  def row_horse_info(array, label, format = FORMAT_F_HORSE, func = nil)
    row = label.rjust(LABEL_STRLEN_HORSE) + ' |'
    array.each do |elem|
      row += elem.nil? ? (' ' * FORMAT_STRLEN_HORSE) : sprintf(format, elem)
      row += ' |'
    end
    row += sprintf('%9.5f', array.expectation(func)) if array.instance_of?(Probability) && !func.nil?
    row += "\n"
    row
  end
end
