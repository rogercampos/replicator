require 'rubygems'
require 'bundler/setup'

require 'concurrent'
require "sqlite3"
require 'fileutils'

require_relative 'page_crawler'
require_relative "locker"
require_relative 'db_wrapper'
require_relative 'already_visited_urls'


class Replicator
  def initialize(domain, n)
    @domain = domain
    @n = n
  end

  def run!
    verify_exit_status!

    Locker.instance(@domain).flush
    FileUtils.mkdir_p @domain.data_dir

    unless there_are_pending_urls
      db.execute "insert into pending_urls (url) values (?)", "#{@domain.scheme}://#{@domain.name}"
      puts "Created initial root url"
    end

    threads = Array.new(@n) do |i|
      Thread.start do
        Worker.new(@domain, i, @n).start!
      end
    end

    threads.each(&:join)
  end

  def there_are_pending_urls
    @there_are_pending_urls ||= db.execute("select 1 from pending_urls limit 1;")[0]
  end

  def db
    @db ||= DbWrapper.new @domain
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
  def initialize(domain, index, total)
    @index = index
    @total = total
    @domain = domain
    @db = DbWrapper.new @domain
  end

  def start!
    page_crawler = PageCrawler.new(@db, @domain)

    empty_counter = 0

    loop do
      next_url = @db.execute("select url from pending_urls where id % ? = ? limit 1;", @total, @index)[0]

      if next_url.nil?
        if empty_counter > 3
          break
        else
          sleep 0.5
          empty_counter += 1
        end
      else
        page_crawler.run(next_url[0])
      end
    end
  end
end