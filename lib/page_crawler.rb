require 'digest/md5'
require "addressable/uri"

require_relative "parser"
require_relative "downloader"
require_relative "path_builder"

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
  def initialize(db, domain, opts)
    @db = db
    @domain = domain
    @opts = opts
  end

  # expect full url, absolute
  def run(url)
    normalized_path = PathNormalizer.clean(url)

    if already_parsed?(normalized_path)
      print "*"

    else

      html = sanitize_str(Downloader.new(url).get)

      next_urls = Parser.new(url, html, @domain.scheme, blacklisted_paths: @opts[:blacklisted_paths]).urls(host: @domain.name)
      next_urls = exclude_blacklisted(next_urls)

      # todo: replace only inside links, etc, not body text and only next_url's, not everything
      html = html.gsub(/https?:\/\/#{@domain.name}\//, "/")

      md5 = Digest::MD5.hexdigest(normalized_path)

      filename = "#{md5}.data"

      next_urls = exclude_already_visited(next_urls)


      @db.transaction do
        @db.execute "insert or ignore into parsed_urls(url, file) values (?, ?)", [normalized_path, filename]

        id = @db.execute "select id from parsed_urls where file = ?", filename

        if id[0]
          dir = PathBuilder.calculate(id[0][0])
          @db.execute "update parsed_urls set file = ? where id = ?", ["#{dir}/#{filename}", id[0][0]]

          FileUtils.mkdir_p File.join(@domain.data_dir, dir)

          File.binwrite(File.join(@domain.data_dir, dir, filename), Zlib::Deflate.deflate(html))

          if next_urls.any?
            @db.execute "insert or ignore into pending_urls (url) values #{next_urls.map { |x| "('#{x}')" }.join(", ")};"
          end

        end
      end

      print "."
    end

    @db.execute "delete from pending_urls where url = ?", url

    AlreadyVisitedUrls.instance(@domain).add(normalized_path)

    true
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

  def exclude_already_visited(urls)
    urls.reject do |url|
      path = url.gsub(/https?:\/\/#{@domain.name}\//, "/")
      already_parsed?(path)
    end
  end

  def exclude_blacklisted(urls)
    urls.reject {|url| blacklisted?(url) }
  end

  def blacklisted?(uri)
    path = uri.to_s.gsub(/https?:\/\/#{@domain.name}\//, "/")

    return false if path.nil?
    return false if @opts[:blacklisted_paths].nil?

    res = @opts[:blacklisted_paths].any? { |censured_path|
      path[0, censured_path.length] == censured_path
    }

    res
  end
end