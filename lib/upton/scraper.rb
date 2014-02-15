require 'uri'
require 'nokogiri'
require_relative './downloader'
require_relative './page'

module Upton
  # Upton::Scraper can be used as-is for basic use-cases by:
  # 1. specifying the pages to be scraped in `new` as an index page
  #      or as an Array of URLs.
  # 2.  supplying a block to `scrape` or `scrape_to_csv` or using a pre-build
  #      block from Upton::Utils.
  # For more complicated cases; subclass Upton::Scraper
  #    e.g. +MyScraper < Upton::Scraper+ and override various methods.
  ##
  class Scraper
    EMPTY_STRING = ''

    attr_accessor :verbose, :debug, :index_debug, :sleep_time_between_requests, :stash_folder, :url_array,
      :paginated, :pagination_param, :pagination_max_pages, :pagination_start_index, :readable_filenames

    ##
    # This is the main user-facing method for a basic scraper.
    # Call +scrape+ with a block; this block will be called on
    # the text of each instance page, (and optionally, its URL and its index
    # in the list of instance URLs returned by +get_index+).
    ##
    def scrape(&blk)
      self.url_array = self.get_index unless self.url_array
      self.scrape_from_list(self.url_array, blk)
    end

    ##
    # +index_url_or_array+: A list of string URLs, OR
    #              the URL of the page containing the list of instances.
    # +selector+: The XPath expression or CSS selector that specifies the
    #              anchor elements within the page, if a url is specified for
    #              the previous argument.
    #
    # These options are a shortcut. If you plan to override +get_index+, you
    # do not need to set them.
    # If you don't specify a selector, the first argument will be treated as a
    # list of URLs.
    ##
    def initialize(index_url_or_array, selector="")

      #if first arg is a valid URL, do already-written stuff;
      #if it's not (or if it's a list?) don't bother with get_index, etc.
      #e.g. Scraper.new(["http://jeremybmerrill.com"])

      #TODO: rewrite this, because it's a little silly. (i.e. should be a more sensical division of how these arguments work)
      if index_url_or_array.respond_to? :each_with_index
        @url_array = index_url_or_array
      else
        @index_url = index_url_or_array
        @index_selector = selector
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

      # If true, then Upton will attempt to scrape paginated index pages
      @paginated = false
      # Default query string parameter used to specify the current page
      @pagination_param = 'page'
      # Default number of paginated pages to scrape
      @pagination_max_pages = 2
      # Default starting number for pagination (second page is this plus 1).
      @pagination_start_index = 1
 
      # Folder name for stashes, if you want them to be stored somewhere else,
      # e.g. under /tmp.
      if @stash_folder
        FileUtils.mkdir_p(@stash_folder) unless Dir.exists?(@stash_folder)
      end
    end

    ##
    # If instance pages are paginated, <b>you must override</b>
    # this method to return the next URL, given the current URL and its index.
    #
    # If instance pages aren't paginated, there's no need to override this.
    #
    # Recursion stops if the fetching URL returns an empty string or an error.
    #
    # e.g. next_instance_page_url("http://whatever.com/article/upton-sinclairs-the-jungle?page=1", 2)
    # ought to return "http://whatever.com/article/upton-sinclairs-the-jungle?page=2"
    ##
    def next_instance_page_url(url, pagination_index)
      EMPTY_STRING
    end

    ##
    # Return the next URL to scrape, given the current URL and its index.
    #
    # Recursion stops if the fetching URL returns an empty string or an error.
    #
    # If @paginated is not set (the default), this method returns an empty string.
    #
    # If @paginated is set, this method will return the next pagination URL
    # to scrape using @pagination_param and the pagination_index.
    #
    # If the pagination_index is greater than @pagination_max_pages, then the
    # method will return an empty string.
    #
    # Override this method to handle pagination is an alternative way
    # e.g. next_index_page_url("http://whatever.com/articles?page=1", 2)
    # ought to return "http://whatever.com/articles?page=2"
    #
    ##
    def next_index_page_url(url, pagination_index)
      return EMPTY_STRING unless @paginated

      if pagination_index > @pagination_max_pages
        puts "Exceeded pagination limit of #{@pagination_max_pages}" if @verbose
        EMPTY_STRING
      else
        uri = URI.parse(url)
        query = uri.query ? Hash[URI.decode_www_form(uri.query)] : {}
        # update the pagination query string parameter
        query[@pagination_param] = pagination_index
        uri.query = URI.encode_www_form(query)
        puts "Next index pagination url is #{uri}" if @verbose
        uri.to_s
      end
    end

    ##
    # Writes the scraped result to a CSV at the given filename.
    ##
    def scrape_to_csv filename, &blk
      require 'csv'
      self.url_array = self.get_index unless self.url_array
      CSV.open filename, 'wb' do |csv|
        #this is a conscious choice: each document is a list of things, either single elements or rows (as lists).
        self.scrape_from_list(self.url_array, blk).compact.each do |document|
          if document[0].respond_to? :map
            document.each{|row| csv << row }
          else
            csv << document
          end
        end
        #self.scrape_from_list(self.url_array, blk).compact.each{|document| csv << document }
      end
    end

    def scrape_to_tsv filename, &blk
      require 'csv'
      self.url_array = self.get_index unless self.url_array
      CSV.open filename, 'wb', :col_sep => "\t" do |csv|
        #this is a conscious choice: each document is a list of things, either single elements or rows (as lists).
        self.scrape_from_list(self.url_array, blk).compact.each do |document|
          if document[0].respond_to? :map
            document.each{|row| csv << row }
          else
            csv << document
          end
        end
        #self.scrape_from_list(self.url_array, blk).compact.each{|document| csv << document }
      end
    end

    protected

    ##
    # Handles getting pages with Downlader, which handles stashing.
    ##
    def get_page(url, stash=false, options={})
      return EMPTY_STRING if url.nil? || url.empty? #url is nil if the <a> lacks an `href` attribute.
      global_options = {
        :cache => stash,
        :verbose => @verbose
      }
      if @readable_filenames
        global_options[:readable_filenames] = true
      end
      if @stash_folder
        global_options[:readable_filenames] = true
        global_options[:cache_location] = @stash_folder
      end
      resp_and_cache = Downloader.new(url, global_options.merge(options)).get
      if resp_and_cache[:from_resource]
        puts "sleeping #{@sleep_time_between_requests} secs" if @verbose
        sleep @sleep_time_between_requests
      end
      resp_and_cache[:resp]
    end


    ##
    # sometimes URLs are relative, e.g. "index.html" as opposed to "http://site.com/index.html"
    # resolve_url resolves them to absolute urls.
    # absolute_url_str must be a URL, as a string that represents an absolute URL or a URI
    ##
    def resolve_url(href_str, absolute_url_str)
      if absolute_url_str.class <= URI::Generic
        absolute_url = absolute_url_str.dup
      else
        begin
          absolute_url = URI(absolute_url_str).dup
        rescue URI::InvalidURIError
          raise ArgumentError, "#{absolute_url_str} must be represent a valid relative or absolute URI" 
        end
      end
      raise ArgumentError, "#{absolute_url} must be absolute" unless absolute_url.absolute?
      if href_str.class <= URI::Generic
        href = href_str.dup
      else
        begin
          href = URI(href_str).dup
        rescue URI::InvalidURIError
          raise ArgumentError, "#{href_str} must be represent a valid relative or absolute URI"
        end
      end

      # return :href if :href is already absolute
      return href.to_s if href.absolute?

      #TODO: edge cases, see [issue #8](https://github.com/propublica/upton/issues/8)
      URI.join(absolute_url.to_s, href.to_s).to_s
    end

    ##
    # Return a list of URLs for the instances you want to scrape.
    # This can optionally be overridden if, for example, the list of instances
    # comes from an API.
    ##
    def get_index
      index_pages = get_index_pages(@index_url, @pagination_start_index).map{|page| parse_index(page, @index_selector) }.flatten
    end

    # TODO: Not sure the best way to handle this
    # Currently, #parse_index is called upon #get_index_pages,
    #  which itself is dependent on @index_url
    # Does @index_url stay unaltered for the lifetime of the Upton instance?
    # It seems to at this point, but that may be something that gets
    #  deprecated later
    #
    # So for now, @index_url is used in conjunction with resolve_url
    # to make sure that this method returns absolute urls
    # i.e. this method expects @index_url to always have an absolute address
    # for the lifetime of an Upton instance
    def parse_index(text, selector)
      Nokogiri::HTML(text).search(selector).to_a.map do |a_element|
        href = a_element["href"]
        resolved_url = resolve_url( href, @index_url) unless href.nil?
        puts "resolved #{href} to #{resolved_url}" if @verbose && resolved_url != href
        resolved_url
      end
    end


    ##
    # Returns the concatenated output of each member of a paginated index,
    # e.g. a site listing links with 2+ pages.
    ##
    def get_index_pages(url, pagination_index, options={})
      resps = [self.get_page(url, @index_debug, options)]
      prev_url = url
      while !resps.last.empty?
        pagination_index += 1
        next_url = self.next_index_page_url(url, pagination_index)
        next_url = resolve_url(next_url, url)
        break if next_url == prev_url || next_url.empty?

        next_resp = self.get_page(next_url, @index_debug, options).to_s
        prev_url = next_url
        resps << next_resp
      end
      resps
    end

    ##
    # Returns the instance at `url`.
    #
    # If the page is stashed, returns that, otherwise, fetches it from the web.
    #
    # If an instance is paginated, returns the concatenated output of each
    # page, e.g. if a news article has two pages.
    ##
    def get_instance(url, pagination_index=0, options={})
      resps = [self.get_page(url, @debug, options)]
      pagination_index = pagination_index.to_i
      prev_url = url
      while !resps.last.empty?
        next_url = self.next_instance_page_url(url, pagination_index + 1)
        break if next_url == prev_url || next_url.empty?

        next_resp = self.get_page(next_url, @debug, options)
        prev_url = next_url
        resps << next_resp
      end
      resps
    end

    # Just a helper for +scrape+.
    def scrape_from_list(list, blk)
      puts "Scraping #{list.size} instances" if @verbose
      list.each_with_index.map do |instance_url, instance_index|
        instance_resps = get_instance instance_url, nil, :instance_index => instance_index
        instance_resps.each_with_index.map do |instance_resp, pagination_index|
          page = Page.new(instance_resp, instance_url, instance_index, pagination_index)
          blk.call(page)
        end
      end.flatten(1)
    end

    # it's often useful to have this slug method for uniquely (almost certainly) identifying pages.
    def slug(url)
      url.split("/")[-1].gsub(/\?.*/, "").gsub(/.html.*/, "")
    end

  end
end