# encoding: UTF-8

require 'rack'
require 'thin'
require 'nokogiri'
require 'restclient'
require 'fileutils'
require "spec_helper.rb"

require './lib/upton'


describe Upton do
  before :all do
    @headlines = ["Webinar: How to Use Prescriber Checkup to Power Your Reporting",
                 "",
                 "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                 "Six Facts Lost in the IRS Scandal"]
    @most_commented_heds = [["Six Facts Lost in the IRS Scandal",
                        "How the IRS’s Nonprofit Division Got So Dysfunctional",
                        "Sound, Fury and the IRS Mess",
                        "The Most Important #Muckreads on Rape in the Military",
                        "Congressmen to Hagel: Where Are the Missing War Records?",
                        "As Need for New Flood Maps Rises, Congress and Obama Cut Funding",
                        "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                        "A Prolonged Stay: The Reasons Behind the Slow Pace of Executions",
                        "The Story Behind Our Hospital Interactive",
                        "irs-test-charts-for-embedding"]]
    @east_timor_prime_ministers = [[
                                    ["#", "Portrait", "Name(Birth–Death)", "Term of Office", "Party",
                                      "1", "2", "3", "4",],
                                    [],
                                    ["", "Mari Alkatiri(b. 1949)", "20 May 2002", "26 June 2006[1]", "FRETILIN"],
                                    ["", "José Ramos-Horta(b. 1949)", "26 June 2006", "19 May 2007", "Independent"],
                                    ["", "Estanislau da Silva(b. 1952)", "19 May 2007", "8 August 2007", "FRETILIN"],
                                    ["", "Xanana Gusmão(b. 1946)", "8 August 2007", "Incumbent", "CNRT"],
                                  ]]
    @searchResults = ["Webinar: How to Use Prescriber Checkup to Power Your Reporting",
                 "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                 "Six Facts Lost in the IRS Scandal"]
  end

  it "should scrape in the basic case" do
    stub_request(:get, "www.example.com/propublica.html").
      to_return(:body => File.new('./spec/data/propublica.html'), :status => 200)
    stub_request(:get, "www.example.com/discussion.html").
      to_return(:body => File.new('./spec/data/discussion.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)

    propubscraper = Upton::Scraper.new("http://www.example.com/propublica.html", "section#river section h1 a")
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    heds = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      hed = doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    heds.should eql @headlines
  end

  it 'should properly handle relative urls'  do
# uses a modified page from the previous test in which the target
# href, http://127.0.0.1:9876/prosecutors.html, has been changed
# to a relative url
#
# Note: this test is a bit quirky, because it passes on the fact that
# the resolve_url creates a url identical to one that is already stashed ("prosecutors.html").
# So it works, but because of a coupling to how Upton handles caching in the file system

    stub_request(:get, "www.example.com/propublica-relative.html").
      to_return(:body => File.new('./spec/data/propublica-relative.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/discussion.html").
      to_return(:body => File.new('./spec/data/discussion.html'), :status => 200)


    propubscraper = Upton::Scraper.new("http://www.example.com/propublica-relative.html", "section#river h1 a")
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    heds = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      hed = doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    heds.should eql ["A Prosecutor, a Wrongful Conviction and a Question of Justice"]
  end

  it "should scrape a list properly with the list helper" do
    stub_request(:get, "www.example.com/propublica.html").
      to_return(:body => File.new('./spec/data/propublica.html'), :status => 200)

    propubscraper = Upton::Scraper.new(["http://www.example.com/propublica.html"])
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    list = propubscraper.scrape(&Upton::Utils.list("#jamb.wNarrow #most-commented li a"))
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    list.should eql @most_commented_heds
  end

  it "should scrape a table properly with the table helper" do
    stub_request(:get, "www.example.com/easttimor.html").
      to_return(:body => File.new('./spec/data/easttimor.html'), :status => 200)

    propubscraper = Upton::Scraper.new(["http://www.example.com/easttimor.html"])
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    table = propubscraper.scrape(&Upton::Utils.table('//table[contains(concat(" ", normalize-space(@class), " "), " wikitable ")][2]'))
    table.map{|outer| outer.map{|row| row.map{|cell| cell.gsub!("\n", '') } }} # cope with diff nokogiri versions differing behavior.
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    table.should eql @east_timor_prime_ministers
  end

  it "should test saving files with the right encoding" do
    pending "finding a site that gives funny encodings"
  end

  it "should scrape paginated pages" do
    stub_request(:get, "www.example.com/propublica_search.html").
      to_return(:body => File.new('./spec/data/propublica_search.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=1").
      to_return(:body => File.new('./spec/data/propublica_search.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=2").
      to_return(:body => File.new('./spec/data/propublica_search_page_2.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=3").
      to_return(:body => '', :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)


    propubscraper = Upton::Scraper.new("http://www.example.com/propublica_search.html", '.compact-list a.title-link')
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.paginated = true
    propubscraper.pagination_param = 'p'
    propubscraper.pagination_max_pages = 3
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    results = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    results.should eql @searchResults
  end


  before do
    Upton::Scraper.stub(:sleep)
  end

  it "should sleep after requests with caching disabled" do
    stub_request(:get, "www.example.com")
    u = Upton::Scraper.new("http://www.example.com", '.whatever')
    u.index_debug = false
    u.sleep_time_between_requests = 1 #don't sleep too long, that's annoying.
    u.should_receive(:sleep)
    u.scrape
  end

  it "should sleep after uncached requests when caching is enabled" do
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    stub_request(:get, "www.example.com")
    u = Upton::Scraper.new("http://www.example.com", '.whatever')
    u.index_debug = true
    u.stash_folder = "test_stashes"
    u.sleep_time_between_requests = 1 #don't sleep too long, that's annoying.
    u.should_receive(:sleep)
    u.scrape
  end

  it "should sleep after paginated requests when caching is disabled" do
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    stub_request(:get, "www.example.com/propublica_search.html").
      to_return(:body => File.new('./spec/data/propublica_search.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=1").
      to_return(:body => File.new('./spec/data/propublica_search.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=2").
      to_return(:body => File.new('./spec/data/propublica_search_page_2.html'), :status => 200)
    stub_request(:get, "www.example.com/propublica_search.html?p=3").
      to_return(:body => '', :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)


    u = Upton::Scraper.new("http://www.example.com/propublica_search.html", '.nonexistent')
    u.index_debug = false
    u.debug = false
    u.paginated = true
    u.pagination_param = 'p'
    u.pagination_max_pages = 3
    u.sleep_time_between_requests = 1 #don't sleep too long, that's annoying.
    u.stash_folder = "test_stashes"

    u.should_receive(:sleep).exactly(3).times #once for each search page, so 3.
    u.scrape
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
  end


  it "should save to the designated stash folder" do
    custom_cache_folder = "#{Dir.tmpdir}/upton/test"
    FileUtils.rm_rf(custom_cache_folder)
    stub_request(:get, "www.example.com").
      to_return(:body => '', :status => 200)

    u = Upton::Scraper.new("http://www.example.com", '.whatever')
    u.sleep_time_between_requests = 0.0
    u.stash_folder = custom_cache_folder
    u.debug = true
    u.scrape do
      1+1
    end
    files = Dir.glob(custom_cache_folder)
    expect(files).not_to be_empty
  end

  it "should scrape in the basic case with the index method" do
    stub_request(:get, "www.example.com/propublica.html").
      to_return(:body => File.new('./spec/data/propublica.html'), :status => 200)
    stub_request(:get, "www.example.com/discussion.html").
      to_return(:body => File.new('./spec/data/discussion.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)

    propubscraper = Upton::Scraper.index("http://www.example.com/propublica.html", "section#river section h1 a")
    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    heds = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      hed = doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    heds.should eql @headlines
  end

  it "should allow instances to be set on a new Scraper" do
    stub_request(:get, "www.example.com/propublica.html").
      to_return(:body => File.new('./spec/data/propublica.html'), :status => 200)
    stub_request(:get, "www.example.com/discussion.html").
      to_return(:body => File.new('./spec/data/discussion.html'), :status => 200)
    stub_request(:get, "www.example.com/prosecutor.html").
      to_return(:body => File.new('./spec/data/prosecutor.html'), :status => 200)
    stub_request(:get, "www.example.com/webinar.html").
      to_return(:body => File.new('./spec/data/webinar.html'), :status => 200)
    stub_request(:get, "www.example.com/sixfacts.html").
      to_return(:body => File.new('./spec/data/sixfacts.html'), :status => 200)

    propubscraper = Upton::Scraper.instances(["www.example.com/webinar.html",
                                              "www.example.com/discussion.html", 
                                              "www.example.com/prosecutor.html", 
                                              "www.example.com/sixfacts.html"])

    propubscraper.debug = true
    propubscraper.verbose = false
    propubscraper.sleep_time_between_requests = 0
    propubscraper.stash_folder = "test_stashes"

    heds = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      hed = doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    heds.should eql @headlines
  end

  before do
    Upton::Scraper.stub(:puts)
  end

  it "should be silent if verbose is false" do
    stub_request(:get, "www.example.com")
    u = Upton::Scraper.new("http://www.example.com", '.whatever')
    u.sleep_time_between_requests = 0.0
    u.verbose = false
    u.should_not_receive(:puts)
    u.scrape
  end

end
