require 'rubygems'
require 'bundler/setup'

require 'rack'
require 'rack/server'

require "sqlite3"

require_relative 'domain'

class StaticReplica
  def initialize(domain)
    @domain = domain
  end

  def call(env)
    request = Rack::Request.new env
    db = SQLite3::Database.new @domain.db_path

    path = request.fullpath

    result = db.execute "select file from parsed_urls where url = '#{path}'"

    if result.empty?
      [404, {}, []]
    else
      filename = result[0][0]
      data = File.binread(File.join(@domain.data_dir, filename))

      [200, {}, [Zlib::Inflate.inflate(data)]]
    end
  end
end

class Server
  def initialize(website_dir)
    @website_dir = website_dir
    @domain = Domain.new File.basename(website_dir), File.dirname(website_dir)
  end

  def serve
    Rack::Server.start app: StaticReplica.new(@domain)
  end
end
