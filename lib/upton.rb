# encoding: UTF-8

# **Upton** is a framework for easy web-scraping with a useful debug mode 
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

module Upton

  # Upton::Scraper is implemented as an abstract class. Implement a class to
  # inherit from Upton::Scraper. 
  class Scraper

    attr_accessor :verbose, :debug, :nice_sleep_time, :stash_folder

    # ## Basic use-case methods.

    # This is the main user-facing method for a basic scraper.
    # Call `scrape` with a block; this block will be called on 
    # the text of each instance page, (and optionally, its URL and its index
    # in the list of instance URLs returned by `get_index`).
    def scrape &blk
      self.scrape_from_list(self.get_index(@index_url, @index_selector, @index_selector_method), blk)
    end

    # Return a list of URLs for the instances you want to scrape.
    #
    # You probably want to use Nokogiri or another HTML parser to find the
    # links to the instances within the HTML of the index page; alternatively,
    # you might make a call to a search API in this method.

    # ## Configuration Variables
    def initialize(index_url, selector, selector_method=:xpath)

      # If true, then Upton prints information about when it gets
      # files from the internet and when it gets them from its stash.
      @verbose = false

      # If true, then Upton fetches each page only once
      # future requests for that file are responded to with the locally stashed
      # version.
      # You may want to set @debug to false for production (but maybe not).
      # You can also control stashing behavior on a per-call basis with the
      # optional second argument to get_page, if, for instance, you want to 
      # stash instance pages, but not index pages.
      @debug = true

      # In order to not hammer servers, Upton waits for, by default, 30  
      # seconds between requests to the remote server.
      @nice_sleep_time = 30 #seconds

      # Folder name for stashes, if you want them to be stored somewhere else,
      # e.g. under /tmp.
      @stash_folder = "stashes"
      unless Dir.exists?(@stash_folder)
        Dir.mkdir(@stash_folder)
      end
      
      @index_url = index_url
      @index_selector = selector
      @index_selector_method = selector_method
    end



    # ## Advanced use-case methods.

    # If instance pages (not index pages) are paginated, **you must override**
    # this method to return the next URL, given the current URL and its index.
    #
    # If instance pages aren't paginated, there's no need to override this.
    #
    # Return URLs that are empty strings are ignored (and recursion stops.)
    # e.g. next_instance_page_url("http://whatever.com/article/upton-sinclairs-the-jungle?page=1", 2)
    # ought to return "http://whatever.com/article/upton-sinclairs-the-jungle?page=2"
    def next_instance_page_url(url, index)
      ""
    end

    def next_index_page_url(url, index)
      ""
    end


    protected

    #Handles getting pages with RestClient or getting them from the local stash
    def get_page(url, stash=false)
      return "" if url.empty?

      #the filename for each stashed version is a cleaned version of the URL.
      if stash && File.exists?( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ) )
        puts "usin' a stashed copy of " + url if @verbose
        resp = open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "")), 'r').read
      else
        begin
          puts "getting " + url if @verbose
          sleep @nice_sleep_time
          resp = RestClient.get(url, {:accept=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
        rescue RestClient::ResourceNotFound
          resp = ""
        rescue RestClient::InternalServerError
          resp = ""
        end
        if stash
          puts "I just stashed (#{resp.code if resp.respond_to?(:code)}): #{url}" if @verbose
          open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ), 'w:UTF-8'){|f| f.write(resp.encode("UTF-8", :invalid => :replace, :undef => :replace ))}
        end
      end
      resp
    end

    
    def get_index(url, selector, selector_method=:xpath) #TODO needs better name
      parse_index(get_index_pages(url, 1), "//table[@class='table_search']//tr/td[2]/a", selector_method)
    end

    def parse_index(text, selector, selector_method=:xpath)
      Nokogiri::HTML(text).send(selector_method, selector).to_a.map{|l| l["href"] }
    end

    # Returns the concatenated output of each member of a paginated index,
    # e.g. a site listing links with 2+ pages.
    def get_index_pages(url, index) #maybe needs better name
      resp = self.get_page(url, @debug)
      if !resp.empty? 
        next_url = self.next_index_page_url(url, index + 1)
        unless next_url == url
          next_resp = self.get_index_pages(next_url, index + 1).to_s 
          resp += next_resp
        end
      end
      resp
    end


    # Returns the concatenated output of each member of a paginated instance,
    # e.g. a news article with 2 pages.
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

    # Just a helper for `scrape`
    def scrape_from_list(list, blk)
      puts "Scraping #{list.size} instances" if @verbose
      list.each_with_index.map do |instance_url, index|
        blk.call(get_instance(instance_url), instance_url, index)
      end
    end


    # it's often useful to have this slug method for uniquely (almost certainly) identifying pages.
    def slug(url)
      "wapo:" + url.split("/")[-1].gsub(/\?.*/, "").gsub(/.html.*/, "")
    end

  end
end