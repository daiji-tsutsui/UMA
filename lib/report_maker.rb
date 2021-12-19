class ReportMaker
  attr_accessor :report

  def initialize(analyzer, logger)
    @analyzer = analyzer
    @logger = logger
  end

  def summarize(odds)
    @report = ""

    col_num = @analyzer.a.size
    columns = " time |"
    a_values = "    a |"
    b_values = "    b |"
    col_num.times do |i|
      columns += sprintf("%9d", i) + " |"
      a_values += sprintf("%9.5f", @analyzer.a[i]) + " |"
      b_values += sprintf("%9.5f", @analyzer.b[i]) + " |"
    end
    @report += "Summary:" + "\n"
    @report += columns + "\n"
    @report += columns.gsub(/[^\|]/, '-').gsub(/\|/, '+') + "\n"
    @report += a_values + "\n"
    @report += b_values + "\n"

    unless @analyzer.t.nil?
      col_num = @analyzer.t.size
      strat = @analyzer.strat(odds)
      columns = " horse |"
      t_values = "     t |"
      o_values = "  odds |"
      s_values = " strat |"
      col_num.times do |i|
        columns += sprintf("%9d", i + 1) + " |"
        t_values += sprintf("%9.5f", @analyzer.t[i]) + " |"
        o_values += sprintf("%9.1f", odds[i]) + " |"
        s_values += sprintf("%9.5f", strat[i]) + " |"
      end
      @report += "\n"
      @report += columns + "\n"
      @report += columns.gsub(/[^\|]/, '-').gsub(/\|/, '+') + "\n"
      @report += t_values + "\n"
      @report += o_values + "\n"
      @report += s_values + "\n"
    end
    @logger.info @report
    @report
  end
end
