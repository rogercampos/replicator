require "addressable/uri"

require_relative 'downloader'

class Domain
  def initialize(domain)
    @domain = domain
  end

  def db_path
    @db_path ||= File.expand_path 'database.db', @domain
  end

  def data_dir
    @data_dir ||= File.expand_path 'data', @domain
  end

  def name
    @domain
  end

  def scheme
    @scheme ||= begin
      uri = Addressable::URI.parse "http://#{name}"

      if Downloader.new(uri.to_s).works?
        uri.scheme

      else
        uri = Addressable::URI.parse "https://#{name}"

        if Downloader.new(uri.to_s).works?
          uri.scheme
        else
          raise "Provided domain #{name} does not seem to work either with http nor https"
        end
      end
    end
  end
end
