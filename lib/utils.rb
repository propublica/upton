# encoding: UTF-8

module Upton

  #instance_html, instance_url, index
  def self.table_to_csv(table_selector, selector_method, csv_filename)
    require 'csv'
    return Proc.new do |instance_html|
      html = Nokogiri::HTML(instance_html)
      CSV.open(csv_filename, 'wb') do |csv|
        headers = html.call(selector_method, table_selector).css("th").map &:text
        csv << headers

        #data
        table = html.call(selector_method, table_selector).css("tr").each{|tr| csv << tr.css("td").map(&:text) }
      end
    end
  end

  def self.list_to_csv(list_selector, selector_method, csv_filename)
    require 'csv'
    return Proc.new do |instance_html|
      html = Nokogiri::HTML(instance_html)
      CSV.open(csv_filename, 'wb') do |csv|
        #data
        table = html.call(selector_method, list_selector).each{|tr| csv << tr.text }
      end
    end
  end
end