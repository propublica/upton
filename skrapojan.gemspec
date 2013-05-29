Gem::Specification.new do |s|
  s.name        = 'skrapojan'
  s.version     = '0.0.1'
  s.date        = '2013-05-29'
  s.summary     = "A simple web-scraping framework"
  s.description = "Don't re-write web scrapers every time. Skrapojan gives you a scraper template that's easy to use for debugging and doesn't hammer servers by default"
  s.authors     = ["Jeremy B. Merrill"]
  s.email       = 'jeremy.merrill@propublica.org'
  s.files       = ["lib/skrapojan.rb"]
  s.homepage    =
    'http://github.org/propublica/skrapojan'

  s.add_runtime_dependency "restclient", ["~> 1.6.7"]
end
