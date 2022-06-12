require "./lib/probability"

# Make instant summary and output to log file
class ReportMaker
  attr_accessor :report

  FORMAT_D_TIME = "%9d"
  FORMAT_F_TIME = "%9.5f"
  LABEL_STRLEN_TIME = 10
  FORMAT_D_HORSE = "%9d"
  FORMAT_F_HORSE = "%9.5f"
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
    col_num = @analyzer.a.size
    summary = columns_time_series(col_num)
    summary += row_time_series(@analyzer.a, col_num, 'weight')
    summary += row_time_series(@analyzer.b, col_num, 'certainty')
    summary
  end

  def summarize_horse_info(odds)
    col_num = @analyzer.t.size
    opt_odds = @analyzer.t.map { |r| JRA_RETURN_RATE / r }
    summary = columns_horse_info(col_num)
    summary += row_horse_info(@analyzer.t, col_num, 'probability', format: "%9.5f")
    summary += row_horse_info(odds, col_num, 'current odds', format: "%9.1f")
    summary += row_horse_info(opt_odds, col_num, 'optimal odds', format: "%9.1f")
    summary += row_horse_info(@analyzer.strat(odds, 1.0),
                              col_num,
                              'weak strat',
                              format: "%9.5f",
                              f: @analyzer.t.map.with_index { |r, i| r * odds[i] })
    summary += row_horse_info(@analyzer.strat(odds, 10.0),
                              col_num,
                              'strong strat',
                              format: "%9.5f",
                              f: @analyzer.t.map.with_index { |r, i| r * odds[i] })
    summary += row_horse_info(@analyzer.probable_strat(odds),
                              col_num,
                              'probable st.',
                              format: "%9.5f")
    summary
  end

  def columns_time_series(col_num, format: FORMAT_D_TIME)
    columns = "time".rjust(LABEL_STRLEN_TIME) + " |"
    col_num.times do |i|
      columns += sprintf(format, i) + " |"
    end
    columns += "\n"
    columns += columns.gsub(/[^\|\n]/, '-').gsub(/\|/, '+')
    columns
  end

  def row_time_series(array, col_num, label, format: FORMAT_F_TIME)
    row = label.rjust(LABEL_STRLEN_TIME) + " |"
    col_num.times do |i|
      row += sprintf(format, array[i]) + " |"
    end
    row += "\n"
    row
  end

  def columns_horse_info(col_num, format: FORMAT_D_HORSE)
    columns = "horse".rjust(LABEL_STRLEN_HORSE) + " |"
    col_num.times do |i|
      columns += sprintf(format, i + 1) + " |"
    end
    columns += "expect".rjust(9)
    columns += "\n"
    columns += columns.gsub(/[^\|\n]/, '-').gsub(/\|/, '+')
    columns
  end

  def row_horse_info(array, col_num, label, format: FORMAT_F_HORSE, f: nil)
    row = label.rjust(LABEL_STRLEN_HORSE) + " |"
    col_num.times do |i|
      row += sprintf(format, array[i]) + " |"
    end
    if array.instance_of?(Probability) && !f.nil?
      row += sprintf("%9.5f", array.expectation(f))
    end
    row += "\n"
    row
  end

end
