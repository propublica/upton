*skrapojan
==========
Skrapojan is a framework for easy web-scraping with a useful debug mode that doesn't hammer your target's servers. It does the repetitive parts of writing scrapers, so you only have to write the unique parts for each site.

Documentation
----------------------
Skrapojan works best if your scraper class inherits from Skrapojan::Scraper, e.g. 

     class MyScraper < Skrapojan::Scraper 
     ...
     end

Skrapojan is implemented as an abstract class. For basic use cases, you only have to implement one method -- the `get_index` method -- and a block argument for `scrape` to do something with the scraped pages. In more complicated cases, you may need to write additional methods; for instance, if you need to log in to a site before scraping the instance pages, you would need to subclass the scrape method.

You get, for free, methods like `_get_page(url, stash=false)` which, well, gets a page. That's not very special. The more interesting part is that `_get_page(url, stash=false)` transparently stashes the response of each request. Whenever you repeat a request with `true` as the second parameter, the stashed HTML is returned without going to the server. This is helpful in the development stages of a project when you're testing some aspect of the code and don't want to hit a server each time.

Skrapojan also sleeps (by default) 30 seconds between non-stashed requests, to reduce load on the server you're scraping. This is configurable with the @nice_sleep_time option.

Example
----------------------
If you want to scrape ProPublica's website with Skrapojan, this is how you'd do it. (Scraping our [RSS feed](http://feeds.propublica.org/propublica/main) would be smarter, but not every site has a full-text RSS feed...)


      class ProPublicaScraper < Skrapojan::Scraper
        def self.get_index
          url = "http://www.propublica.org"
          doc = Nokogiri::HTML(self._get_page(url, true))
          doc.css("section#river section h1 a").to_a.map{|l| + l["href"] } #map the Nokogiri link elements to a string representation of a URL.
        end
      end

      ProPublicaScraper.scrape do |article_string|
        puts "here is the full text of the ProPublica article: \n #{article_string}"
        #or, do other stuff here.
      end


Credits
----------------------
Jeremy B. Merrill, ProPublica, jeremy dot merrill at propublica dot org

Etymology
----------------------
According to the [Online Etymological Dictionary](http://www.etymonline.com/index.php?allowed_in_frame=0&search=scrape&searchmode=none), "scrape" comes from the reconstructed Proto-Germanic word *skrapojan.