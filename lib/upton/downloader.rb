require "fileutils"
require "open-uri"
require "tmpdir"
require "restclient"

module Upton

  # This class is used internally to download and cache the webpages
  # that are requested.
  #
  # By default, the cache location is the output of `Dir.tmpdir`/upton.
  # The Dir.tmpdir returns the temporary directory of the operating system.
  class Downloader

    attr_reader :uri, :cache_location, :verbose
    def initialize(uri, options = {})
      @uri = uri
      @cache = options.fetch(:cache) { true }
      @cache_location = options[:cache_location] || "#{Dir.tmpdir}/upton"
      @verbose = options[:verbose] || false
      initialize_cache!
    end

    def get
      if cache_enabled?
        puts "Reading from cache enabled. Will try reading #{uri} data from cache"
        download_from_cache
      else
        puts "Reading from cache not enabled. Will download from the internet"
        download_from_resource
      end
    end

    private

    def download_from_resource
      begin
        puts "Downloading from #{uri}" if verbose
        resp = RestClient.get(uri)
        puts "Downloaded #{uri}" if verbose
      rescue RestClient::ResourceNotFound
        puts "404 error, skipping: #{uri}" if verbose
      rescue RestClient::InternalServerError
        puts "500 Error, skipping: #{uri}" if verbose
      rescue URI::InvalidURIError
        puts "Invalid URI: #{uri}" if verbose
      rescue RestClient::RequestTimeout
        puts "Timeout: #{uri}" if verbose
        retry
      end
      resp ||= ""
    end

    def download_from_cache
      file = if cached_file_exists?
               puts "Cache of #{uri} available"
               open(cached_file).read
             else
               puts "Cache of #{uri} unavailable. Will download from the internet"
               download_from_resource
             end
      unless cached_file_exists?
        puts "Writing #{uri} data to the cache"
        File.write(cached_file, file)
      end
      file
    end

    def cache_enabled?
      !!@cache
    end

    def hashed_filename_based_on_uri
      Digest::MD5.hexdigest(uri)
    end

    def cached_file
      "#{cache_location}/#{hashed_filename_based_on_uri}"
    end

    def cached_file_exists?
      File.exists?(cached_file)
    end

    def initialize_cache!
      unless Dir.exists?(cache_location)
        Dir.mkdir(cache_location)
        FileUtils.chmod 0700, cache_location
      end
    end

  end
end
