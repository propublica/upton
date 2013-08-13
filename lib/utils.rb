# encoding: UTF-8

##
# This module contains a collection of helpers for Upton
##
module Upton

  ##
  # This class contains a collection of helpers for Upton
  #
  # Each method returns a Proc that (with an & ) can be used as the final
  # argument to Upton's `scrape` and `scrape_to_csv`
  ##
  module Utils

    ##
    # Scrapes an HTML <table> element into an Array of Arrays. The header, if
    # present, is returned as the first row.
    ##
    def self.table(table_selector, deprecated=nil)
      return Proc.new do |instance_html|
        html = ::Nokogiri::HTML(instance_html)
        output = []
        headers = html.search(table_selector).css("th").map &:text
        output << headers

        table = html.search(table_selector).css("tr").each{|tr| output << tr.css("td").map(&:text) }
        output
      end
    end

    ##
    # Scrapes any set of HTML elements into an Array. 
    ##
    def self.list(list_selector, deprecated=nilh)
      return Proc.new do |instance_html|
        html = ::Nokogiri::HTML(instance_html)
        html.search(list_selector).map{|list_element| list_element.text }
      end
    end

    ##
    # Takes :_href and resolves it to an absolute URL according to
    #  the supplied :_page_url. They can be either Strings or URI
    #  instances.
    #
    # raises ArgumentError if either href or page_url is nil
    # raises ArgumentError if page_url is not absolute
    #
    # returns: a String with absolute URL
    def self.resolve_url(_href, _page_url)
      
      page_url = URI(_page_url).dup
      raise ArgumentError, "#{page_url} must be absolute" unless page_url.absolute?

      href = URI(_href).dup

      # return :href if :href is already absolute
      return href.to_s if href.absolute?


      # TODO: There may be edge cases worth considering
      # but this should handle the following non-absolute href possibilities:
      # //anothersite.com (keeps scheme, too!)
      # /root/dir
      # relative/dir
      # ?query=2
      # #bang

      URI.join(page_url, href).to_s    
    end

  end
end