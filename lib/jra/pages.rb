# frozen_string_literal: true

require 'site_prism'
require 'capybara/dsl'

module Jra

  # 今週のオッズボタン用
  SATURDAY = 0
  SUNDAY = 1
  THIRD = 2
  # レース番号
  RACE_1 = 0
  RACE_2 = 1
  RACE_3 = 2
  RACE_4 = 3
  RACE_5 = 4
  RACE_6 = 5
  RACE_7 = 6
  RACE_8 = 7
  RACE_9 = 8
  RACE_10 = 9
  RACE_11 = 10
  RACE_12 = 11

  # JRAのトップページ
  class TopPage < SitePrism::Page
    set_url 'https://sp.jra.jp'

    elements :menu_items, 'div#quick_menu>ul>li'

    def go_odds
      menu_items.each do |item|
        if item.text == 'オッズ'
          item.hover.click
          break
        end
      end
      OddsPage.new
    end
  end

  # オッズ情報コース・日時選択ページ
  class OddsPage < SitePrism::Page
    set_url 'https://sp.jra.jp/JRADB/accessO.html'

    elements :days, 'div#ThisWkOdds>div.joSelectArea'

    def go_course(day_id, region)
      courses = days[day_id].all(:css, 'div.jyoSelectBtn')
      courses.each do |course|
        if course.text == region
          course.hover.click
          break
        end
      end
      RaceOddsPage.new
    end
  end

  # オッズ情報レース選択ページ
  class RaceOddsPage < SitePrism::Page
    elements :races, 'li.oddsRaceListCol'

    def go_single_odds(race_id)
      race = races[race_id].all(:css, 'li>a')
      race.each do |type|
        if type.text == '単勝・複勝'
          type.hover.click
          break
        end
      end
      SingleOddsPage.new
    end
  end

  # 単勝・複勝オッズ情報ページ
  class SingleOddsPage < SitePrism::Page
    element :odds_table, 'div.ozTanfukuTable'

    def get_uma_num
      odds_table.all(:css, 'tr>td.umaban').size
    end

    def get_uma_name
      odds_table.all(:css, 'tr>td.bamei>a').map { |bamei| bamei.text }
    end

    def get_tan_odds
      odds_table.all(:css, 'tr>td.oztan').map { |odds| odds.text.to_f }
    end

    def get_fuku_odds
      fuku_area = odds_table.all(:css, 'tr>td.fukuArea')
      fuku_min = []
      fuku_max = []
      fuku_area.each do |area|
        fuku_min.push area.first(:css, 'div.fukuMin').text.to_f
        fuku_max.push area.first(:css, 'div.fukuMax').text.to_f
      end
      { min: fuku_min, max: fuku_max }
    end
  end
end
