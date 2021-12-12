require 'site_prism'
require 'capybara/dsl'

module Google
  class Home < SitePrism::Page
    set_url 'https://www.google.com'

    element :search_field, "input[name='q']"
    element :search_button, "input[name='btnK']"

    def open_search_result
      search_button.click
      SearchResults.new  # 次のページを返す
    end
  end

  class SearchResults < SitePrism::Page
    set_url_matcher /google.com\/search\?.*/

    elements :links, "a"
    elements :titles, "h3"

    def search_result_links
      links.map { |lk| lk['href'] }
    end

    def title_texts
      titles.map { |t| t.text }
    end
  end
end
