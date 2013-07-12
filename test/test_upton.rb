# encoding: UTF-8

require 'test/unit'
require 'rack'
require 'thin'
require 'nokogiri'
require 'restclient'
require './lib/upton'
require 'fileutils'

module Upton
  module Test

    # class ProPublicaScraper < Upton::Scraper
    #   def initialize(a, b, c)
    #     super
    #     @verbose = false
    #     @debug = false
    #     @stash_folder = "test_stashes"
    #   end
    # end


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
                     "",
                     "A Prosecutor, a Wrongful Conviction and a Question of Justice",
                     "Six Facts Lost in the IRS Scandal"]

        propubscraper = Upton::Scraper.new("http://127.0.0.1:9876/propublica.html", "section#river section h1 a", :css)
        propubscraper.debug = true
        propubscraper.verbose = true

        heds = propubscraper.scrape do |article_str|
          doc = Nokogiri::HTML(article_str)
          hed = doc.css('h1.article-title').text
        end
        assert_equal(heds, headlines)
        FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
      end

      def test_encodings
        skip "should test getting pages, switching their encoding to UTF-8, saving them as UTF-8, reading them as UTF-8"
      end

      def test_stashing
        skip "should test stashing, make sure we never send too many requests"
      end

      def test_scrape_list
        #this doesn't test stashing.
        #TODO: needs a website that has links to a multi-page list (or table)
        start_test_server()

        most_commented_heds = [["Six Facts Lost in the IRS Scandal", 
                            "How the IRS’s Nonprofit Division Got So Dysfunctional", 
                            "Sound, Fury and the IRS Mess", 
                            "The Most Important #Muckreads on Rape in the Military", 
                            "Congressmen to Hagel: Where Are the Missing War Records?", 
                            "As Need for New Flood Maps Rises, Congress and Obama Cut Funding", 
                            "A Prosecutor, a Wrongful Conviction and a Question of Justice", 
                            "A Prolonged Stay: The Reasons Behind the Slow Pace of Executions", 
                            "The Story Behind Our Hospital Interactive",
                            "irs-test-charts-for-embedding"]]

        propubscraper = Upton::Scraper.new(["http://127.0.0.1:9876/propublica.html"])
        propubscraper.debug = true
        propubscraper.verbose = true
        list = propubscraper.scrape(&Upton::Utils.list("#jamb.wNarrow #most-commented li a", :css))

        assert_equal(list, most_commented_heds)
        FileUtils.rm_r("test_stashes") if Dir.exists?("test_stashes")
      end

      def test_scrape_table
        #this doesn't test stashing.
        start_test_server()

        east_timor_prime_ministers = [[ 
                                        ["#", "Portrait", "Name(Birth–Death)", "Term of Office", "Party", 
                                          "1", "2", "3", "4",],
                                        [],
                                        ["", "Mari Alkatiri(b. 1949)", "20 May 2002", "26 June 2006[1]", "FRETILIN"],
                                        ["", "José Ramos-Horta(b. 1949)", "26 June 2006", "19 May 2007", "Independent"],
                                        ["", "Estanislau da Silva(b. 1952)", "19 May 2007", "8 August 2007", "FRETILIN"],
                                        ["", "Xanana Gusmão(b. 1946)", "8 August 2007", "Incumbent", "CNRT"],
                                      ]]

        propubscraper = Upton::Scraper.new(["http://127.0.0.1:9876/easttimor.html"])
        propubscraper.debug = true
        propubscraper.verbose = true
        table = propubscraper.scrape(&Upton::Utils.table('//table[contains(concat(" ", normalize-space(@class), " "), " wikitable ")][2]'))
        assert_equal(table, east_timor_prime_ministers)
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
        file = File.join(@root, "data", path)

        params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])

        if File.exists?(file)
          [ 200, {"Content-Type" => "text/html; charset=utf-8"}, File.read(file) ]
        else
          [ 404, {'Content-Type' => 'text/plain'}, 'file not found' ]
        end
      end
    end
  end
end