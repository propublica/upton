Gem::Specification.new do |s|
  s.name        = 'upton'
  s.version     = '0.2.6'
  s.date        = '2013-07-22'
  s.summary     = "A simple web-scraping framework"
  s.description = "Don't re-write web scrapers every time. Upton gives you a scraper template that's easy to use for debugging and doesn't hammer servers by default"
  s.authors     = ["Jeremy B. Merrill"]
  s.email       = 'jeremy.merrill@propublica.org'
  s.files       = ["lib/upton.rb", "lib/utils.rb"]
  s.has_rdoc    = true
  s.test_files  = Dir.glob('test/data/*.html') + ['test/test_upton.rb']
  s.required_ruby_version = ">= 1.8.7" #not tested with 1.8.6, but it might work
  s.license     = 'MIT'
  s.homepage    =
    'http://github.org/propublica/upton'

  s.add_development_dependency 'rack'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'yard'

  s.add_runtime_dependency "rest-client", ["~> 1.6.7"]
  s.add_runtime_dependency 'nokogiri'
end
