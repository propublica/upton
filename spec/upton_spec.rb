# encoding: UTF-8

require 'rack'
require 'thin'
require 'nokogiri'
require 'restclient'
require 'fileutils'
require './lib/upton'

describe Upton do
  before :all do
    #start the server
    class Server
      def call(env)
        @root = File.expand_path(File.dirname(__FILE__))
        path = Rack::Utils.unescape(env['PATH_INFO'])
        path += 'index.html' if path == '/'
        file = File.join(@root, "data", path)

        params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])

        if File.exists?(file)
          [ 200, {"Content-Type" => "text/html; charset=utf-8"}, File.read(file) ]
        else
          [ 404, {'Content-Type' => 'text/plain'}, 'file not found' ]
        end
      end
    end

    def start_test_server
      @server_thread = Thread.new do
        Rack::Handler::Thin.run ::Server.new, :Port => 9876
      end
      sleep(1) # wait a sec for the server to be booted
    end

    start_test_server()

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
  end

  it "should scrape in the basic case" do
    propubscraper = Upton::Scraper.new("http://127.0.0.1:9876/propublica.html", "section#river section h1 a", :css)
    propubscraper.debug = true
    propubscraper.verbose = true

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

    propubscraper = Upton::Scraper.new("http://127.0.0.1:9876/propublica-relative.html", "section#river h1 a", :css)
    propubscraper.debug = true
    propubscraper.verbose = true

    heds = propubscraper.scrape do |article_str|
      doc = Nokogiri::HTML(article_str)
      hed = doc.css('h1.article-title').text
    end
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    heds.should eql ["A Prosecutor, a Wrongful Conviction and a Question of Justice"]
  end

  it "should scrape a list properly with the list helper" do
    propubscraper = Upton::Scraper.new(["http://127.0.0.1:9876/propublica.html"])
    propubscraper.debug = true
    propubscraper.verbose = true
    list = propubscraper.scrape(&Upton::Utils.list("#jamb.wNarrow #most-commented li a", :css))
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    list.should eql @most_commented_heds
  end

  it "should scrape a table properly with the table helper" do
    propubscraper = Upton::Scraper.new(["http://127.0.0.1:9876/easttimor.html"])
    propubscraper.debug = true
    propubscraper.verbose = true
    table = propubscraper.scrape(&Upton::Utils.table('//table[contains(concat(" ", normalize-space(@class), " "), " wikitable ")][2]'))
    FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
    table.should eql @east_timor_prime_ministers
  end

  it "should test saving files with the right encoding"
  it "should test stashing to make sure pages are stashed at the right times, but not at the wrong ones"
end
