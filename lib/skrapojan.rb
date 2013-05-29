module Skrapojan
  class AbstractMethodError < Exception; end
  class Scraper
    attr_accessor :verbose
    self.verbose = false

    def self._get_page(url, stash=false)
      return "" if url.empty?
      if stash && File.exists?("stashes/" + url.gsub(/[^A-Za-z0-9\-]/, ""))
        puts "usin' a stashed copy of " + url if self.verbose
        resp = open("stashes/" + url.gsub(/[^A-Za-z0-9\-]/, ""), 'r').read
      else
        begin
          puts "getting " + url if self.verbose
          sleep 30
          resp = RestClient.get(url, {:accept=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
        rescue RestClient::ResourceNotFound
          resp = ""
        rescue RestClient::InternalServerError
          resp = ""
        end
        if stash
          puts "I just stashed (#{resp.code if resp.respond_to?(:code)}): #{url}" if self.verbose
          open("stashes/" + url.gsub(/[^A-Za-z0-9\-]/, ""), 'w'){|f| f.write(resp)}
        end
      end
      resp
    end

    def self.get_instance(url, index=0)
      resp = self._get_page(url, $cyberenv == :debug)
      if !resp.empty? 
        next_url = self.next_page_url(url, index + 1)
        unless next_url == url
          next_resp = self.get_article(next_url, index + 1).to_s 
          resp += next_resp
        end
      end
      resp
    end

    # Returns an array of URLs.
    def self.get_index
      raise AbstractMethodError
    end

    # Returns just the (hopefully canonical) slug that uniquely IDs the article.
    # Needs to ignore different types of URLs, like protocol differences, page numbers, etc.
    def self.slug(url)
      url.split("/")[-1].gsub(/\?.*/, "").gsub(/.html.*/, "")
    end
    def self.next_page_url(_, _)
      ""
    end
  end
end