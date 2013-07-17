Upton
==========
Upton is a framework for easy web-scraping with a useful debug mode that doesn't hammer your target's servers. It does the repetitive parts of writing scrapers, so you only have to write the unique parts for each site.

Documentation
----------------------

With Upton, you can scrape complex sites to a CSV in just one line of code.

    Upton::Scraper.new("http://website.com/list_of_stories.html").
        scrape_to_csv("output.csv", &Upton::Utils.list("#comments li a.commenter-name", :css))

Just specify a URL to a list of links -- or simply a list of links --, an XPath or CSS selector for the links and a block of what to do with the content of the pages you've scraped. Upton comes with some pre-written blocks (Procs, technically) for scraping simple lists and tables, like the `list` function above.

Upton operates on the theory that, for most scraping projects, you need to scrape two types of pages:

1. Instance pages, which are the goal of your scraping, e.g. job listings or news articles.
1. Index pages, which list instance pages. For example, a job search site's search page or a newspaper's homepage.

For more complex use cases, subclass `Upton::Scraper` and override the relevant methods. If you're scraping links from an API, you would override `get_index`; if you need to log in before scraping a site or do something special with the scraped instance page, you would override `get_instance`.

The `get_instance` and `get_index` methods use a protected method `get_page(url)` which, well, gets a page. That's not very special. The more interesting part is that `get_page(url, stash)` transparently stashes the response of each request if the second parameter, `stash`, is true. Whenever you repeat a request (with `true` as the second parameter), the stashed HTML is returned without going to the server. This is helpful in the development stages of a project when you're testing some aspect of the code and don't want to hit a server each time. If you are using `get_instance` and `get_index`, this can be en/disabled per instance of `Upton::Scraper` or its subclasses with the `@debug` option. Setting the `stash` parameter of the `get_page` method should only be used if you've overridden `get_instance` or `get_index` in a subclass.

Upton also sleeps (by default) 30 seconds between non-stashed requests, to reduce load on the server you're scraping. This is configurable with the `@sleep_time_between_requests` option.

<b>For more complete documentation</b>, see [the RDoc](http://propublica.github.io/upton).

<b>Important Note:</b> Upton is alpha software. The API may change at any time. 

Example
----------------------
If you want to scrape ProPublica's website with Upton, this is how you'd do it. (Scraping our [RSS feed](http://feeds.propublica.org/propublica/main) would be smarter, but not every site has a full-text RSS feed...)

      Upton::Scraper.new("http://www.propublica.org", "section#river section h1 a", :css).scrape do |article_string|
        puts "here is the full text of the ProPublica article: \n #{article_string}"
        #or, do other stuff here.
      end

Shortcuts
----------
Upton includes a handful of "shortcut" methods to scrape a table or a list certain elements on a series of pages into a CSV. See `lib/utils.rb` for these, but they include:

Utils::table("#article table", :css) and
Utils::list("a#byline", :css)

Contributing
----------------------
I'd love to hear from you if you're using Upton. I also appreciate your suggestions/complaints/bug reports/pull requests. If you're interested, check out the issues tab or [drop me a note](http://github.com/jeremybmerrill).

In particular, if you have a common, *abstract* use case, please add them to [lib/utils.rb](https://github.com/propublica/upton/blob/master/lib/utils.rb). Check out the `table_to_csv` and `list_to_csv` methods for examples.

(The pull request process is pretty easy. Fork the project in Github (or via the `git` CLI), make your changes, then submit a pull request on Github.) 

Why "Upton"
----------------------
Upton Sinclair was a pioneering, muckraking journalist who is most famous for _The Jungle_, a novel portraying the reality of immigrant labor struggles in Chicago meatpacking plants at the start of the 1900s. Upton, the gem, sprang out of a ProPublica project pertaining to labor issues.

License (MIT)
------------------------

Copyright (c) 2013 ProPublica

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Notes
------------------------
Test data is copyrighted by either ProPublica or various Wikipedia contributors.
In either case, it's reproduced here under a Creative Commons license. In ProPublica's case, it's BY-NC-ND; in Wikipedia's it's BY-SA.