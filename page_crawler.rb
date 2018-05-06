require 'httparty'
require 'digest/md5'

class Parser
  REGEXP = /<a\s+(?:[^>]*?\s+)?href="([^"]*)"/

  def initialize(html)
    @html = html
  end

  def urls(only_host: nil)
    urls = @html.scan(REGEXP).map(&:first)

    if only_host.nil?
      urls
    else
      urls.select { |x| URI(x).host == only_host rescue false }
    end
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
          puts "Fetching [#{url}]..."
          html = HTTParty.get(url).body

          uri = URI(url)

          next_urls = Parser.new(html).urls(only_host: uri.host)

          filename = Digest::MD5.hexdigest(uri.path)

          File.write("#{@website}/#{filename}.data", html)

          @db.execute "insert into parsed_urls(url, file) values (?, ?)", [url, "#{filename}.data"]
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