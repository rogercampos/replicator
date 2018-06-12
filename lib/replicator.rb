require 'rubygems'
require 'bundler/setup'

require 'concurrent'
require "sqlite3"
require 'fileutils'

require_relative 'page_crawler'
require_relative "locker"
require_relative 'db_wrapper'

class Replicator
  def initialize(domain, n)
    @domain = domain
    @n = n
  end

  def run!
    verify_exit_status!

    Locker.instance(@domain).flush
    FileUtils.mkdir_p @domain.data_dir

    urls = WorkerPool.pool(@domain).borrow { |worker| worker.pending_urls }

    if urls && urls.any?
      puts "Resuming paused execution, #{urls.size} urls to go."
      WorkerPool.pool(@domain).borrow { |worker| worker.clean_pending_urls! }
      WorkerPool.push_work(@domain, urls)

    else
      puts "Starting fresh with root url."
      WorkerPool.push_work(@domain, ["#{@domain.scheme}://#{@domain.name}"])
    end
  end

  def verify_exit_status!
    db = DbWrapper.new @domain
    unvisited_url = db.execute "select target_url from tree left join parsed_urls ON tree.target_url = parsed_urls.url where parsed_urls.url is null limit 1;"
    pending_urls = WorkerPool.pool(@domain).borrow { |worker| worker.pending_urls }

    if unvisited_url.nil? && pending_urls.nil?
      puts "This domain is already completed!"
      exit 0
    end
  end
end

class Worker
  def initialize(domain)
    @domain = domain
    @db = DbWrapper.new @domain
  end

  def crawl_url(url)
    # Do all the work
    PageCrawler.new(@db, @domain).run(url)
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
  WorkerPool.shutdown!
}

class AlreadyVisitedUrls
  @instances = {}

  def self.instance(domain)
    @instances[domain.name] ||= new(domain)
  end

  def initialize(domain)
    @domain = domain
  end

  def registry
    @registry ||= Set.new(db.execute("select url from parsed_urls").map(&:first))
  end

  def add(url)
    registry << url
  end

  def include?(url)
    registry.include?(url)
  end

  def db
    @db ||= DbWrapper.new @domain
  end
end

class WorkerPool
  N = 5

  def initialize(domain)
    @domain = domain
    @workers = []
  end

  def size
    @workers.size
  end

  def borrow
    a = @workers.pop || Worker.new(@domain)

    result = yield(a)
    @workers << a

    result
  end

  def self.pool(domain)
    @pool ||= WorkerPool.new(domain)
  end

  def self.thread_pool
    @thread_pool ||= Concurrent::FixedThreadPool.new(N)
  end

  def self.i
    @i ||= 1
    @i.tap { @i += 1 }
  end

  def self.push_work(domain, urls)
    return if urls == []

    puts "\n> Starting generation #{i} with #{urls.size} urls..."

    futures = urls.map do |url|
      Concurrent::Future.execute(executor: thread_pool) {

        result = pool(domain).borrow { |worker| worker.crawl_url(url) }

        [url, result]


        # todo !! give as a result the 2 values, curren url and the next urls for that.
        # if the next urls result empgy after removing already parsed urls, then, if the current url is
        # already parsed as well, then consider next urls = all results
      }
    end

    urls = []
    resolved_futures = []

    wait_for_futures(urls, futures, resolved_futures)
    urls.uniq!

    visited_urls = AlreadyVisitedUrls.instance(domain)

    urls.delete_if do |x|
      visited_urls.include?(PathNormalizer.clean(x))
    end

    resolved_futures.each do |f|
      raise(f.reason) if f.rejected?
    end

    if @shutdown
      pool(domain).borrow { |worker|
        worker.store_pending_urls!(urls)
        puts "> Stored #{urls.size} urls to keep going later"
      }
    else
      push_work(domain, urls)
    end
  end

  def self.wait_for_futures(results, futures, resolved_futures)
    shutdown_done = false

    loop do
      return if futures.empty?

      if @shutdown && !shutdown_done
        previous_size = futures.size
        futures.delete_if { |x| x.cancel }
        puts "#{futures.size}/#{previous_size} alive futures pending to finish..."
        shutdown_done = true
      end

      # Prefer to wait for futures that are already scheduled
      a = futures.find { |x| x.state != :pending } || futures.shift
      a.value # block here

      results.concat(a.value) unless a.value.nil?
      futures.delete(a)
      resolved_futures << a
    end
  end

  def self.shutdown!
    @shutdown = true
  end
end