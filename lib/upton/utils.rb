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
      return Proc.new do |html|
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
    def self.list(list_selector, deprecated=nil)
      return Proc.new do |html|
        html.search(list_selector).map{|list_element| list_element.text }
      end
    end

  end
end