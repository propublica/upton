require 'rspec'
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
                 "asd",
                 "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                 "Six Facts Lost in the IRS Scandal"]

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
end