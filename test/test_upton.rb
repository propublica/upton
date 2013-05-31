require 'test/unit'
require 'rack'
require 'thin'
require 'nokogiri'
require 'restclient'
require 'upton'
require 'fileutils'

module Upton
  module Test

    class ProPublicaScraper < Upton::Scraper
      def initialize(a, b, c)
        super
        @verbose = false
        @debug = false
        @stash_folder = "test_stashes"
      end
    end


    class UptonTest < ::Test::Unit::TestCase

      # def test_get_page
      #TODO
      # end

      # def test_stash
      #TODO
      # end

      def test_scrape
        #this doesn't test stashing.
        start_test_server()

        headlines = ["Webinar: How to Use Prescriber Checkup to Power Your Reporting", 
                     "Discussion: Military Lending and Debt",
                     "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                     "Six Facts Lost in the IRS Scandal"]

        ProPublicaScraper.new("http://127.0.0.1:9876/propublica.html", "section#river section h1 a", :css).scrape do |article_str|
          doc = Nokogiri::HTML(article_str)
          hed = doc.css('h1.article-title').text
          assert_equal(hed, headlines.shift)
        end
        FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
      end

      private
      def start_test_server
        @server_thread = Thread.new do
          Rack::Handler::Thin.run Upton::Test::Server.new, :Port => 9876
        end
        sleep(1) # wait a sec for the server to be booted
      end
    end



    # via http://stackoverflow.com/questions/10166611/launching-a-web-server-inside-ruby-tests
    class Server
      def call(env)
        @root = File.expand_path(File.dirname(__FILE__))
        path = Rack::Utils.unescape(env['PATH_INFO'])
        path += 'index.html' if path == '/'
        file = @root + "#{path}"

        params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])

        if File.exists?(file)
          [ 200, {"Content-Type" => "text/html"}, File.read(file) ]
        else
          [ 404, {'Content-Type' => 'text/plain'}, 'file not found' ]
        end
      end
    end
  end
end