require 'digest/md5'
require "addressable/uri"

require_relative "parser"
require_relative "locker"
require_relative "downloader"

module PathNormalizer
  def self.clean(url)
    uri = Addressable::URI.parse(url)
    raise "Must have a host" if uri.host.nil?
    raise "Must have a valid scheme" unless ["http", "https"].include?(uri.scheme)

    uri.scheme = nil
    uri.host = nil
    uri.path = "/" if uri.path == ""
    uri.to_s
  end
end


class PageCrawler
  def initialize(db, domain)
    @db = db
    @domain = domain
  end

  # expect full url, absolute
  def run(url)
    next_urls = []
    normalized_path = PathNormalizer.clean(url)

    Locker.instance(@domain).lock(normalized_path) do

      if already_parsed?(normalized_path)
        # The work has been done before, we just need to grab the next urls to continue
        next_urls = @db.execute("select target_url from tree where source_url = ?", normalized_path).map {|x|
          "#{@domain.scheme}://#{@domain.name}#{x[0]}"
        }
        print "*"

      else
        @db.transaction do
          html = sanitize_str(Downloader.new(url).get)

          next_urls = Parser.new(url, html, @domain.scheme).urls(host: @domain.name)

          html = html.gsub("#{@domain.scheme}://#{@domain.name}/", "/")

          md5 = Digest::MD5.hexdigest(normalized_path)

          filename = "#{md5}.data"

          File.write(File.join(@domain.data_dir, filename), html)

          @db.execute "insert into parsed_urls(url, file) values (?, ?)", [normalized_path, filename]

          if next_urls.any?
            insert_values = next_urls.map { |x| "('#{normalized_path}', '#{PathNormalizer.clean(x)}')" }
            @db.execute "insert into tree(source_url, target_url) values #{insert_values.join(",")}"
          end

          print "."
        end

        AlreadyVisitedUrls.instance(@domain).add(normalized_path)
      end
    end

    next_urls
  end

  def sanitize_str(value)
    begin
      value.scan(/a/) # Trigger byte sequence errors
      value
    rescue ArgumentError => e
      if e.message == "invalid byte sequence in UTF-8"
        value.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
      else
        raise
      end
    end
  end

  def already_parsed?(path)
    AlreadyVisitedUrls.instance(@domain).include?(path)
  end
end