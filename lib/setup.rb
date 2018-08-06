require "sqlite3"
require 'fileutils'

class Setup
  def initialize(domain)
    @domain = domain
  end

  def setup!
    FileUtils.mkdir_p File.dirname(@domain.db_path)
    FileUtils.mkdir_p @domain.data_dir

    db = SQLite3::Database.new @domain.db_path

    db.execute <<-SQL
  create table parsed_urls (
    url     varchar(5000),
    file    varchar(500),
    id integer PRIMARY KEY autoincrement
  );
    SQL

    db.execute "create unique index key_on_parsed_urls on parsed_urls(url);"


    db.execute <<-SQL
  create table pending_urls (
    url     varchar(5000),
    id integer PRIMARY KEY autoincrement
  );
    SQL

    db.execute "create index key_on_pending_urls on pending_urls(url);"
  end
end
