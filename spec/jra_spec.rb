require 'jra/pages'

Capybara.default_driver = :selenium_chrome_headless

RSpec.describe Jra do
  before do
    @top_page = Jra::TopPage.new
    @top_page.load
  end

  describe 'TopPage' do
    it 'has menu items' do
      expect(@top_page).to be_displayed
      expect(@top_page).to have_menu_items
    end
    it 'can go odds page' do
      odds_page = @top_page.go_odds
      expect(odds_page).to be_displayed
      # expect(odds_page).to have_days
    end
  end

  describe 'OddsPage' do
  end
end