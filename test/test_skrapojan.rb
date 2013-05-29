require 'test/unit'
require 'rack'
require 'thin'
require 'skrapojan'
require 'nokogiri'
require 'restclient'

module Skrapojan
  module Test
    class SkrapojanTest < ::Test::Unit::TestCase
      def _start_test_server
        @server_thread = Thread.new do
          Rack::Handler::Thin.run Skrapojan::Test::Server.new, :Port => 9876
        end
        sleep(1) # wait a sec for the server to be booted
      end

      # def test_get_page
      #TODO
      # end

      # def test_stash
      #TODO
      # end

      def test_scrape
        #this doesn't test stashing.
        _start_test_server()

        headlines = ["Webinar: How to Use Prescriber Checkup to Power Your Reporting", 
                     "Discussion: Military Lending and Debt",
                     "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                     "Six Facts Lost in the IRS Scandal"]

        ProPublicaScraper.scrape do |article_str|
          doc = Nokogiri::HTML(article_str)
          hed = doc.css('h1.article-title').text
          assert_equal(hed, headlines.shift)
        end
      end
    end

    class ProPublicaScraper < Skrapojan::Scraper
      @verbose = false
      @debug = false
      def self.get_index
        url = "http://127.0.0.1:9876/propublica.html"
        doc = Nokogiri::HTML(self._get_page(url, false))
        doc.css("section#river section h1 a").to_a.map{|l| + l["href"] }
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