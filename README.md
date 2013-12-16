Upton
==========
Upton is a framework for easy web-scraping with a useful debug mode that doesn't hammer your target's servers. It does the repetitive parts of writing scrapers, so you only have to write the unique parts for each site.

Documentation
----------------------

With Upton, you can scrape complex sites to a CSV in just a few lines of code:

```ruby
scraper = Upton::Scraper.new("http://www.propublica.org", "section#river h1 a")
scraper.scrape_to_csv "output.csv" do |html|
  Nokogiri::HTML(html).search("#comments h2.title-link").map &:text
end
```

Just specify a URL to a list of links -- or simply a list of links --, an XPath expression or CSS selector for the links and a block of what to do with the content of the pages you've scraped. Upton comes with some pre-written blocks (Procs, technically) for scraping simple lists and tables, like the `list` function above.

Upton operates on the theory that, for most scraping projects, you need to scrape two types of pages:

1. Instance pages, which are the goal of your scraping, e.g. job listings or news articles.
1. Index pages, which list instance pages. For example, a job search site's search page or a newspaper's homepage.

For more complex use cases, subclass `Upton::Scraper` and override the relevant methods. If you're scraping links from an API, you would override `get_index`; if you need to log in before scraping a site or do something special with the scraped instance page, you would override `get_instance`.

The `get_instance` and `get_index` methods use a protected method `get_page(url)` which, well, gets a page. That's not very special. The more interesting part is that `get_page(url, stash)` transparently stashes the response of each request if the second parameter, `stash`, is true. Whenever you repeat a request (with `true` as the second parameter), the stashed HTML is returned without going to the server. This is helpful in the development stages of a project when you're testing some aspect of the code and don't want to hit a server each time. If you are using `get_instance` and `get_index`, this can be en/disabled per instance of `Upton::Scraper` or its subclasses with the `@debug` option. Setting the `stash` parameter of the `get_page` method should only be used if you've overridden `get_instance` or `get_index` in a subclass.

Upton also sleeps (by default) 30 seconds between non-stashed requests, to reduce load on the server you're scraping. This is configurable with the `@sleep_time_between_requests` option.

Upton can handle pagination too. Scraping paginated index pages that use a query string parameter to track the current page (e.g. `/search?q=test&page=2`) is possible by setting `@paginated` to true. Use `@pagination_param` to set the query string parameter used to specify the current page (the default value is `page`). Uses @pagination_max_pages to specify the number of pages to scrape (the default is two pages) See the Examples section below.

To handle non-standard pagination, you can override the `next_index_page_url` and `next_instance_page_url` methods; Upton will get each page's URL returned by these functions and return their contents.

<b>For more complete documentation</b>, see [the RDoc](http://rubydoc.info/gems/upton/frames/index).

<b>Important Note:</b> Upton is alpha software. The API may change at any time. 

####How is this different than Nokogiri?
Upton is, in essence, sugar around RestClient and Nokogiri. If you just used those tools by themselves to write scrapers, you'd be responsible for writing code to fetch, save (maybe), debug and sew together all the pieces in a slightly different way for each scraper. Upton does most of that work for you, so you can skip the boilerplate.

####Upton doesn't quite fit your needs?
Here are some similar libraries to check out for inspiration. No promises, since I've never used them, but they seem similar and were [recommended by various HN commenters](https://news.ycombinator.com/item?id=6086031): 

- [Pismo](https://github.com/peterc/pismo)
- [Spidey](https://github.com/joeyAghion/spidey)
- [Anemone](http://anemone.rubyforge.org/)
- [Pupa.rb](https://github.com/opennorth/pupa-ruby) / [Pupa](https://github.com/opencivicdata/pupa)

And these are some libraries that do related things:

- [SelectorGadget](http://selectorgadget.com/)
- [HayStax](https://github.com/danhillreports/haystax)


Examples
----------------------
If you want to scrape ProPublica's website with Upton, this is how you'd do it. (Scraping our [RSS feed](http://feeds.propublica.org/propublica/main) would be smarter, but not every site has a full-text RSS feed...)

```ruby
scraper = Upton::Scraper.new("http://www.propublica.org", "section#river section h1 a")
scraper.scrape do |article_string|
  puts "here is the full text of the ProPublica article: \n #{article_string}"
  #or, do other stuff here.
end
```

Simple sites can be scraped with pre-written `list` block in `Upton::Utils', as below:

```ruby
scraper = Upton::Scraper.new("http://nytimes.com", "ul.headlinesOnly a")
scraper.scrape_to_csv("output.csv", &Upton::Utils.list("h6.byline"))
```

A `table` block also exists in `Upton::Utils` to scrape tables to an array of arrays, as below:

```ruby
> scraper = Upton::Scraper.new(["http://website.com/story.html"])
> scraper.scrape(&Upton::Utils.table("//table[2]"))
[["Jeremy", "$8.00"], ["John Doe", "$15.00"]]
```

This example shows how to scrape the first three pages of ProPublica's search results for the term `tools`:

```ruby
> scraper = Upton::Scraper.new("http://www.propublica.org/search/search.php?q=tools",
                               ".compact-list a.title-link")
> scraper.paginated = true
> scraper.pagination_param = 'p'    # default is 'page'
> scraper.pagination_max_pages = 3  # default is 2
> scraper.scrape_to_csv("output.csv", &Upton::Utils.list("h2"))
```


Contributing
----------------------
I'd love to hear from you if you're using Upton. I also appreciate your suggestions/complaints/bug reports/pull requests. If you're interested, check out the issues tab or [drop me a note](http://github.com/jeremybmerrill).

In particular, if you have a common, *abstract* use case, please add them to [lib/utils.rb](https://github.com/propublica/upton/blob/master/lib/utils.rb). Check out the `table_to_csv` and `list_to_csv` methods for examples.

(The pull request process is pretty easy. Fork the project in Github (or via the `git` CLI), make your changes, then submit a pull request on Github.) 

Why "Upton"
----------------------
Upton Sinclair was a pioneering, muckraking journalist who is most famous for _The Jungle_, a novel portraying the reality of immigrant labor struggles in Chicago meatpacking plants at the start of the 1900s. Upton, the gem, sprang out of a ProPublica project pertaining to labor issues.

Notes
------------------------
Test data is copyrighted by either ProPublica or various Wikipedia contributors.
In either case, it's reproduced here under a Creative Commons license. In ProPublica's case, it's BY-NC-ND; in Wikipedia's it's BY-SA.
