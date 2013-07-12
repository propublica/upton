# encoding: UTF-8

module Upton
  module Utils
    #instance_html, instance_url, index
    def self.table(table_selector, selector_method=:xpath)
      require 'csv'
      return Proc.new do |instance_html|
        html = ::Nokogiri::HTML(instance_html)
        output = []
        headers = html.send(selector_method, table_selector).css("th").map &:text
        output << headers

        table = html.send(selector_method, table_selector).css("tr").each{|tr| output << tr.css("td").map(&:text) }
        output
      end
    end

    def self.list(list_selector, selector_method=:xpath)
      require 'csv'
      return Proc.new do |instance_html|
        html = ::Nokogiri::HTML(instance_html)
        html.send(selector_method, list_selector).map{|list_element| list_element.text }
      end
    end
  end
end