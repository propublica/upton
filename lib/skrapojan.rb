module Skrapojan
  class AbstractMethodError < Exception; end
  class Scraper
    @verbose = false
    @debug = true
    @stash_folder = "stashes"

    def self._get_page(url, stash=false)
      return "" if url.empty?
      if stash && File.exists?( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ) )
        puts "usin' a stashed copy of " + url if @verbose
        resp = open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "")), 'r').read
      else
        begin
          puts "getting " + url if @verbose
          sleep 30
          resp = RestClient.get(url, {:accept=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
        rescue RestClient::ResourceNotFound
          resp = ""
        rescue RestClient::InternalServerError
          resp = ""
        end
        if stash
          puts "I just stashed (#{resp.code if resp.respond_to?(:code)}): #{url}" if @verbose
          open( File.join(@stash_folder, url.gsub(/[^A-Za-z0-9\-]/, "") ), 'w'){|f| f.write(resp)}
        end
      end
      resp
    end

    def self._get_instance(url, index=0)
      resp = self._get_page(url, @debug)
      if !resp.empty? 
        next_url = self.next_page_url(url, index + 1)
        unless next_url == url
          next_resp = self.get_article(next_url, index + 1).to_s 
          resp += next_resp
        end
      end
      resp
    end

    def self._scrape(list, blk)
      list.map do |listing_url|
        blk.call(scraper._get_instance(listing_url))
      end
    end

    def self.scrape &blk
      self._scrape(self.get_index, blk)
    end

    # Returns an array of URLs.
    def self.get_index
      raise AbstractMethodError
    end

    # Returns just the (hopefully canonical) slug that uniquely IDs the article.
    # Needs to ignore different types of URLs, like protocol differences, page numbers, etc.
    def self.slug(url)
      self.class.downcase + ":" + url.split("/")[-1].gsub(/\?.*/, "").gsub(/.html.*/, "")
    end
    def self.next_page_url(_, _)
      ""
    end
  end
end