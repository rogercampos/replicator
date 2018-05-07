require 'rubygems'
require 'bundler/setup'

require 'rack'
require 'rack/server'

require "sqlite3"


class HelloWorld
  def response
    [200, {}, ['Hello World']]
  end
end

class HelloWorldApp
  def self.call(env)
    request = Rack::Request.new env
    db = SQLite3::Database.new "database.db"

    path = request.path

    result = db.execute "select file from parsed_urls where url = '#{path}';"

    if result.empty?
      [404, {}, []]
    else
      filename = result[0][0]
      [200, {}, [File.read(File.expand_path("supercalorias/#{filename}"))]]
    end
  end
end

Rack::Server.start :app => HelloWorldApp