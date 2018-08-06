require_relative 'replicator'
require_relative 'domain'
require_relative 'setup'
require_relative 'server'

require 'thor'

class CLI < Thor
  option :concurrency, type: :numeric, aliases: '-c', desc: "Concurrent fetching workers", default: 3
  desc 'store <domain> <store_dir>', 'Starts downloading process for a given website'
  def store(domain, store_dir)
    unless File.directory?(store_dir)
      puts "Directory #{store_dir} does not exists!"
      exit 1
    end

    domain = Domain.new domain, store_dir

    unless File.file?(domain.db_path)
      Setup.new(domain).setup!
    end

    Process.setproctitle("Replicator")

    Replicator.new(domain, options[:concurrency]).run!
  end


  desc 'serve <store folder>', 'Starts serving a website replicated on <store dir>'
  def serve(web_dir)
    Server.new(web_dir).serve
  end
end