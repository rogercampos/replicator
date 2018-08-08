require 'rubygems'
require 'bundler/setup'

require 'concurrent'
require "sqlite3"
require 'fileutils'

require_relative 'page_crawler'
require_relative 'db_wrapper'
require_relative 'already_visited_urls'


class Replicator
  def initialize(domain, n, opts = {})
    @domain = domain
    @n = n
    @opts = opts
  end

  def run!
    verify_exit_status!

    FileUtils.mkdir_p @domain.data_dir

    unless there_are_pending_urls
      db.execute "insert into pending_urls (url) values (?)", "#{@domain.scheme}://#{@domain.name}"
      puts "Created initial root url"
    end

    threads = Array.new(@n) do |i|
      Thread.start do
        Worker.new(@domain, i, @n, @opts).start!
      end
    end

    threads.each(&:join)
  end

  def there_are_pending_urls
    @there_are_pending_urls ||= db.execute("select 1 from pending_urls limit 1;")[0]
  end

  def db
    @db ||= DbWrapper.instance @domain
  end

  def verify_exit_status!
    there_are_parsed_urls = db.execute("select 1 from parsed_urls limit 1;")[0]

    if !there_are_parsed_urls.nil? && there_are_pending_urls.nil?
      puts "This domain is already completed!"
      exit 0
    end
  end
end

class Worker
  def initialize(domain, index, total, opts)
    @index = index
    @total = total
    @domain = domain
    @db = DbWrapper.instance @domain
    @opts = opts
  end

  def start!
    page_crawler = PageCrawler.new(@db, @domain, @opts)

    # Finish condition is when there're no more pending_urls. However, when starting a site
    # for the first time there's only the initial root url and this would be wrongly
    # interpreted as a false positive finish condition. This dirty solution is to wait some
    # time for re-confirmation of this condition.
    empty_counter = 0

    loop do
      next_url = @db.execute("select url from pending_urls order by random() limit 1;")[0]

      if next_url.nil?
        puts "No more urls to go. Worker ##{@index}. Retry ##{empty_counter}"

        if empty_counter > 1
          puts "Terminated Worker ##{@index}"
          break

        else
          empty_counter += 1
          sleep 0.5 * empty_counter
        end
      else

        page_crawler.run(next_url[0])
      end
    end
  end
end