# encoding: UTF-8

# *Upton* is a framework for easy web-scraping with a useful debug mode 
# that doesn't hammer your target's servers. It does the repetitive parts of 
# writing scrapers, so you only have to write the unique parts for each site.
#
# Upton operates on the theory that, for most scraping projects, you need to
# scrape two types of pages:
# 
# 1. Index pages, which list instance pages. For example, a job search 
#     site's search page or a newspaper's homepage.
# 2. Instance pages, which represent the goal of your scraping, e.g.
#     job listings or news articles.
#

require 'nokogiri'
require 'uri'
require 'restclient'
require './lib/utils'

module Upton

  # Upton::Scraper can be used as-is for basic use-cases, or can be subclassed
  # in more complicated cases; e.g. +MyScraper < Upton::Scraper+
  class Scraper

    attr_accessor :verbose, :debug, :sleep_time_between_requests, :stash_folder, :url_array

    # == Basic use-case methods.

    # This is the main user-facing method for a basic scraper.
    # Call +scrape+ with a block; this block will be called on 
    # the text of each instance page, (and optionally, its URL and its index
    # in the list of instance URLs returned by +get_index+).
    def scrape &blk
      unless self.url_array
        self.url_array = self.get_index
      end
      self.scrape_from_list(self.url_array, blk)
    end

    # +index_url_or_array+: A list of string URLs, OR
    #              the URL of the page containing the list of instances.
    # +selector+: The XPath or CSS that specifies the anchor elements within 
    #              the page, if a url is specified for the previous argument.
    # +selector_method+: +:xpath+ or +:css+. By default, +:xpath+.
    #
    # These options are a shortcut. If you plant to override +get_index+, you
    # do not need to set them.
    # If you don't specify a selector, the first argument will be treated as a
    # list of URLs.
    def initialize(index_url_or_array, selector="", selector_method=:xpath)

      #if first arg is a valid URL, do already-written stuff;
      #if it's not (or if it's a list?) don't bother with get_index, etc.
      #e.g. Scraper.new(["http://jeremybmerrill.com"])

      #TODO: rewrite this, because it's a little silly. (i.e. should be a more sensical division of how these arguments work)
      if selector.empty?
        @url_array = index_url_or_array
      elsif index_url_or_array =~ ::URI::ABS_URI
        @index_url = index_url_or_array
        @index_selector = selector
        @index_selector_method = selector_method
      else
        raise ArgumentError
      end
      # If true, then Upton prints information about when it gets
      # files from the internet and when it gets them from its stash.
      @verbose = false

      # If true, then Upton fetches each instance page only once
      # future requests for that file are responded to with the locally stashed
      # version.
      # You may want to set @debug to false for production (but maybe not).
      # You can also control stashing behavior on a per-call basis with the
      # optional second argument to get_page, if, for instance, you want to 
      # stash certain instance pages, e.g. based on their modification date.
      @debug = true
      # Index debug does the same, but for index pages.
      @index_debug = false

      # In order to not hammer servers, Upton waits for, by default, 30  
      # seconds between requests to the remote server.
      @sleep_time_between_requests = 30 #seconds

      # Folder name for stashes, if you want them to be stored somewhere else,
      # e.g. under /tmp.
      @stash_folder = "stashes"
      unless Dir.exists?(@stash_folder)
        Dir.mkdir(@stash_folder)
      end
    end


    # == Configuration Options

    # If instance pages are paginated, <b>you must override</b> 
    # this method to return the next URL, given the current URL and its index.
    #
    # If instance pages aren't paginated, there's no need to override this.
    #
    # Recursion stops if the fetching URL returns an empty string or an error.
    #
    # e.g. next_instance_page_url("http://whatever.com/article/upton-sinclairs-the-jungle?page=1", 2)
    # ought to return "http://whatever.com/article/upton-sinclairs-the-jungle?page=2"
    def next_instance_page_url(url, index)
      ""
    end

    # If index pages are paginated, <b>you must override</b>
    # this method to return the next URL, given the current URL and its index.
    #
    # If index pages aren't paginated, there's no need to override this.
    #
    # Recursion stops if the fetching URL returns an empty string or an error.
    #
    # e.g. +next_index_page_url("http://whatever.com/articles?page=1", 2)+
    # ought to return "http://whatever.com/articles?page=2"
    def next_index_page_url(url, index)
      ""
    end

    def scrape_to_csv filename, &blk
      require 'csv'
      unless self.url_array
        self.url_array = self.get_index
      end
      CSV.open filename, 'wb' do |csv|
        self.scrape_from_list(self.url_array, blk).each{|document| csv << document }
      end
    end

    protected


    #Handles getting pages with RestClient or getting them from the local stash
    def get_page(url, stash=false)
      return "" if url.empty?

      #the filename for each stashed version is a cleaned version of the URL.
      if stash && File.exists?( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ) )
        puts "usin' a stashed copy of " + url if @verbose
        resp = open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "")), 'r:UTF-8').read .encode("UTF-8", :invalid => :replace, :undef => :replace )
      else
        begin
          puts "getting " + url if @verbose
          sleep @sleep_time_between_requests
          resp = RestClient.get(url, {:accept=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})

          #this is silly, but rest-client needs to get on their game.
          #cf https://github.com/jcoyne/rest-client/blob/fb80f2c320687943bc4fae1503ed15f9dff4ce64/lib/restclient/response.rb#L26
          if ((200..207).include?(resp.net_http_res.code.to_i) && content_type = resp.net_http_res.content_type)
            charset = if set = resp.net_http_res.type_params['charset'] 
              set
            elsif content_type == 'text/xml'
              'us-ascii'
            elsif content_type.split('/').first == 'text'
              'iso-8859-1'
            end
            resp.force_encoding(charset) if charset
          end

        rescue RestClient::ResourceNotFound
          puts "404 error, skipping: #{url}" if @verbose
          resp = ""
        rescue RestClient::InternalServerError
          puts "500 Error, skipping: #{url}" if @verbose
          resp = ""
        rescue URI::InvalidURIError
          puts "Invalid URI: #{url}" if @verbose
          resp = ""
        end
        if stash
          puts "I just stashed (#{resp.code if resp.respond_to?(:code)}): #{url}" if @verbose
          open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ), 'w:UTF-8'){|f| f.write(resp.encode("UTF-8", :invalid => :replace, :undef => :replace ) )}
        end
      end
      resp
    end

    # Return a list of URLs for the instances you want to scrape.
    # This can optionally be overridden if, for example, the list of instances
    # comes from an API.
    def get_index
      parse_index(get_index_pages(@index_url, 1), @index_selector, @index_selector_method)
    end

    # Using the XPath or CSS selector and selector_method that uniquely locates
    # the links in the index, return those links as strings.
    def parse_index(text, selector, selector_method=:xpath)
      Nokogiri::HTML(text).send(selector_method, selector).to_a.map{|l| l["href"] }
    end

    # Returns the concatenated output of each member of a paginated index,
    # e.g. a site listing links with 2+ pages.
    def get_index_pages(url, index)
      resp = self.get_page(url, @index_debug)
      if !resp.empty? 
        next_url = self.next_index_page_url(url, index + 1)
        unless next_url == url
          next_resp = self.get_index_pages(next_url, index + 1).to_s 
          resp += next_resp
        end
      end
      resp
    end

    # Returns the article at `url`.
    # 
    # If the page is stashed, returns that, otherwise, fetches it from the web.
    #
    # If an instance is paginated, returns the concatenated output of each 
    # page, e.g. if a news article has two pages.
    def get_instance(url, index=0)
      resp = self.get_page(url, @debug)
      if !resp.empty? 
        next_url = self.next_instance_page_url(url, index + 1)
        unless next_url == url
          next_resp = self.get_instance(next_url, index + 1).to_s 
          resp += next_resp
        end
      end
      resp
    end

    # Just a helper for +scrape+.
    def scrape_from_list(list, blk)
      puts "Scraping #{list.size} instances" if @verbose
      list.each_with_index.map do |instance_url, index|
        blk.call(get_instance(instance_url), instance_url, index)
      end
    end

    # it's often useful to have this slug method for uniquely (almost certainly) identifying pages.
    def slug(url)
      url.split("/")[-1].gsub(/\?.*/, "").gsub(/.html.*/, "")
    end

  end
end