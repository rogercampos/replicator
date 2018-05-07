require 'rubygems'
require 'bundler/setup'

require 'concurrent'
require "sqlite3"
require 'fileutils'
require "addressable/uri"

require_relative 'page_crawler'

class Replicator
  def initialize(name, url, n)
    @website = name
    @url = url
    @n = n
  end

  def run!
    FileUtils.mkdir_p(@website)

    if (urls = WorkerPool.pool(@website).borrow { |worker| worker.pending_urls } ) && urls.any?
      WorkerPool.pool(@website).borrow { |worker| worker.clean_pending_urls! }
      WorkerPool.push_work(@website, urls)

    else
      WorkerPool.push_work(@website, [@url])
    end
  end
end

class Worker
  def initialize(website)
    @website = website
    @db = SQLite3::Database.new "database.db"
  end

  def crawl_url(url)
    # Do all the work
    PageCrawler.new(@db, @website).run(url)
  end

  def store_pending_urls!(urls)
    @db.execute "insert into pending_urls values #{urls.map { |x| "('#{x}')" }.join(", ")};"
  end

  def pending_urls
    @db.execute("select url from pending_urls").map(&:first)
  end

  def clean_pending_urls!
    @db.execute("delete from pending_urls")
  end
end

trap("INT") {
  puts "Shutting down, please wait for current page parsings to finish..."
  WorkerPool.shutdown
}

module AlreadyVisitedUrls
  def self.registry
    @registry ||= Set.new(db.execute("select url from parsed_urls").map(&:first))
  end

  def self.add(url)
    registry << url
  end

  def self.include?(url)
    registry.include?(url)
  end

  def self.only_new!(urls)
    urls.delete_if { |x| include?(x) }
  end

  def self.db
    @db ||= SQLite3::Database.new "database.db"
  end
end

class WorkerPool
  N = 3

  def initialize(website)
    @website = website
    @workers = []
  end

  def size
    @workers.size
  end

  def borrow
    a = @workers.pop || Worker.new(@website)
    s = yield(a)
    @workers << a
    s
  end

  def self.pool(website)
    @pool ||= WorkerPool.new(website)
  end

  def self.thread_pool
    @thread_pool ||= Concurrent::FixedThreadPool.new(N)
  end

  def self.i
    @i ||= 1
    @i.tap { @i += 1 }
  end

  def self.push_work(website, urls)
    return if urls == []

    puts "> Starting generation #{i} with #{urls.size} urls..."

    futures = urls.map do |url|
      Concurrent::Future.execute(executor: thread_pool) {
        pool(website).borrow { |worker| worker.crawl_url(url) }
      }
    end

    urls = futures.flat_map do |future|
      next(nil) if @shutdown
      future.value
    end.compact.uniq

    urls = AlreadyVisitedUrls.only_new!(urls)

    futures.each do |f|
      raise(f.reason) if f.rejected?
    end

    if @shutdown
      pool(website).borrow { |worker|
        worker.store_pending_urls!(urls)
        puts "> Stored #{urls.size} urls to keep going later"
      }
    else
      push_work(@website, urls)
    end
  end

  def self.shutdown
    @shutdown = true
  end
end