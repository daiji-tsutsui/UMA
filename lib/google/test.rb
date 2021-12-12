def test_scraping(searc_query)
  home = Google::Home.new
  home.load
  home.search_field.set searc_query
  result = home.open_search_result

  # pp result.search_result_links
  pp result.title_texts
end
