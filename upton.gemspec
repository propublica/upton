Gem::Specification.new do |s|
  s.name        = 'upton'
  s.version     = '0.0.1'
  s.date        = '2013-05-29'
  s.summary     = "A simple web-scraping framework"
  s.description = "Don't re-write web scrapers every time. Skrapojan gives you a scraper template that's easy to use for debugging and doesn't hammer servers by default"
  s.authors     = ["Jeremy B. Merrill"]
  s.email       = 'jeremy.merrill@propublica.org'
  s.files       = ["lib/upton.rb"]
  s.requried_ruby_version = ">= 1.8.7" #not tested with 1.8.6, but it might work
  s.license     = 'MIT'
  s.homepage    =
    'http://github.org/propublica/upton'

  s.add_development_dependency 'rack'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rocco'

  s.add_runtime_dependency "rest-client", ["~> 1.6.7"]
end
