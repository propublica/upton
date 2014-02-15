require 'nokogiri'

module Upton
  class Page

    attr_reader :html, :raw_html, :url, :instance_index, :pagination_index

    def initialize(raw_html, url, instance_index, pagination_index)
      @html = Nokogiri::HTML(raw_html)
      @raw_html = raw_html
      @url = url
      @instance_index = instance_index
      @pagination_index = pagination_index
    end

    def empty?
      return @raw_html.empty?
    end

    alias_method :to_s, :raw_html

    private
      #Strangely enough, having ScrapedPage inherit from Nokogiri::HTML::Document just doesn't work.
      def method_missing(method, *args, &blk)
        self.html.send(method, *args, &blk)
      end
  end
end