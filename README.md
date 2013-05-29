*skrapojan
==========
Skrapojan is a framework for easy web-scraping with a useful debug mode that doesn't hammer your target's servers.

Documentation
----------------------
Skrapojan works best if your scraper class inherits from Skrapojan::Scraper, e.g. 

     class MyScraper < Skrapojan::Scraper 
     ...
     end

You get, for free, methods like `_get_page(url, stash=false)` which, well, gets a page. That's not very special. The more interesting part is that `_get_page(url, stash=false)` transparently stashes the response of each request. Whenever you repeat a request with `true` as the second parameter, the stashed HTML is returned without going to the server. This is helpful in the development stages of a project when you're testing some aspect of the code and don't want to hit a server each time.

Skrapojan also sleeps (by default) 30 seconds between non-stashed requests, to reduce load on the server you're scraping. This is configurable ... #TK. 

Skrapojan assumes that most scraping projects involve scraping an index, then scraping the instances listed on the index. It also understands that indexes  may in turn consist


Credits
----------------------

Etymology
----------------------
According to the [Online Etymological Dictionary](http://www.etymonline.com/index.php?allowed_in_frame=0&search=scrape&searchmode=none), "scrape" comes from the reconstructed Proto-Germanic word *skrapojan.