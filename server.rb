require 'rubygems'
require 'bundler/setup'

require 'rack'
require 'rack/server'

require "sqlite3"

require_relative 'lib/domain'

domain = ARGV[0]

if domain.nil?
  puts "Please use ruby server.rb <domain name>"
  exit 1
end

$domain = Domain.new domain

class StaticReplica
  def self.call(env)
    request = Rack::Request.new env
    db = SQLite3::Database.new $domain.db_path

    path = request.fullpath

    result = db.execute "select file from parsed_urls where url = '#{path}';"

    if result.empty?
      [404, {}, []]
    else
      filename = result[0][0]
      [200, {}, [File.read(File.join($domain.data_dir, filename))]]
    end
  end
end

Rack::Server.start app: StaticReplica