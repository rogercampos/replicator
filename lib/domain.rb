require "addressable/uri"

require_relative 'downloader'

class Domain
  def initialize(domain, root_data_dir)
    @domain = domain
    @root_data_dir = root_data_dir
  end

  def db_path
    @db_path ||= File.join @root_data_dir, @domain, 'database.db'
  end

  def data_dir
    @data_dir ||= File.join @root_data_dir, @domain, 'data'
  end

  def name
    @domain
  end

  def scheme
    @scheme ||= begin
      uri = Addressable::URI.parse "https://#{name}"

      if Downloader.new(uri.to_s).works?
        uri.scheme

      else
        uri = Addressable::URI.parse "http://#{name}"

        if Downloader.new(uri.to_s).works?
          uri.scheme
        else
          raise "Provided domain #{name} does not seem to work either with http nor https"
        end
      end
    end
  end
end
