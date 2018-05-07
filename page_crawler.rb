require 'httparty'
require 'digest/md5'

class Parser
  A_REGEXP = /<a\s+(?:[^>]*?\s+)?href="([^"]*)"/
  IMG_REGEXP = /<img[^>]+src="([^">]+)"/
  LINK_REGEXP = /<link\s+(?:[^>]*?\s+)?href="([^"]*)"/
  SCRIPT_REGEXP = /<script[^>]+src="([^">]+)"/

  def initialize(html)
    @html = html
  end

  def urls(host:)
    urls = @html.scan(A_REGEXP).map(&:first)
    urls += @html.scan(IMG_REGEXP).map(&:first)
    urls += @html.scan(LINK_REGEXP).map(&:first)
    urls += @html.scan(SCRIPT_REGEXP).map(&:first)

    urls.select! { |x|
      uri = Addressable::URI.parse(Addressable::URI.escape(x))
      uri.host.nil? || uri.host == host
    }

    urls.map {|x|
      uri = Addressable::URI.parse(Addressable::URI.escape(x))

      if uri.host.nil?
        uri.host = "supercalorias.com"

        p uri


        uri.scheme = "https"
        uri.to_s
      else
        x
      end
    }
  end
end

class PageCrawler
  LOCK_TIMEOUT = 30

  def initialize(db, website)
    @db = db
    @website = website
  end

  def run(url)
    next_urls = []

    lock(url) do
      unless already_parsed?(url)
        @db.transaction do
          # print "."
          puts "Fetching [#{url}]"
          html = HTTParty.get(url).body

          uri = Addressable::URI.parse(url)
          uri.scheme = nil
          uri.host = nil
          path = uri.to_s

          next_urls = Parser.new(html).urls(host: "supercalorias.com")

          html = html.gsub("https://supercalorias.com/", "/")

          filename = Digest::MD5.hexdigest(path)

          File.write("#{@website}/#{filename}.data", html)

          p path
          @db.execute "insert into parsed_urls(url, file) values (?, ?)", [path, "#{filename}.data"]
        end

        AlreadyVisitedUrls.add(url)
      end
    end

    next_urls
  end

  def already_parsed?(url)
    AlreadyVisitedUrls.include?(url)
  end

  def lock(key, start_time = Time.now.to_f)
    begin
      @db.execute "insert into locks values (?)", key

    rescue SQLite3::ConstraintException
      if start_time < Time.now.to_f - LOCK_TIMEOUT
        raise "Timeout waiting for lock #{key}"
      end

      sleep(0.05)
      lock(key, start_time)

    else
      begin
        yield
      ensure
        @db.execute "delete from locks where key = ?", key
      end
    end

  end
end