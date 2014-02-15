# encoding: UTF-8

require_relative 'upton/scraper'
require_relative 'upton/utils'
require_relative 'upton/version'

##
# This module contains a scraper called Upton
##
module Upton
  ##
  # *Upton* is a framework for easy web-scraping with a useful debug mode
  # that doesn't hammer your target's servers. It does the repetitive parts of
  # writing scrapers, so you only have to write the unique parts for each site.
  #
  # Upton operates on the theory that, for most scraping projects, you need to
  # scrape two types of pages:
  #
  # 1. Index pages, which list instance pages. For example, a job search
  #     site's search page or a newspaper's homepage.
  # 2. Instance pages, which represent the goal of your scraping, e.g.
  #     job listings or news articles.
  #

end
