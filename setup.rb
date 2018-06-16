require 'rubygems'
require 'bundler/setup'

require "sqlite3"
require 'fileutils'


require_relative 'lib/domain'

domain = ARGV[0]

if domain.nil?
  puts "Please use ruby setup.rb <domain name>"
  exit 1
end

FileUtils.mkdir_p domain

domain = Domain.new domain

FileUtils.rm_f domain.db_path
FileUtils.rm_r Dir.glob("#{domain.data_dir}/*")


db = SQLite3::Database.new domain.db_path

db.execute <<-SQL
  create table parsed_urls (
    url     varchar(5000),
    file    varchar(500)
  );
SQL

db.execute "create unique index key_on_parsed_urls on parsed_urls(url);"


db.execute <<-SQL
  create table locks (
    key     varchar(3000)
  );
SQL

db.execute "create unique index key_on_locks on locks(key);"


db.execute <<-SQL
  create table pending_urls (
    url     varchar(5000),
    id integer PRIMARY KEY autoincrement
  );
SQL

db.execute "create index key_on_pending_urls on pending_urls(url);"


db.execute <<-SQL
  create table tree (
    source_url     varchar(5000),
    target_url     varchar(5000)
  );
SQL

db.execute "create index key_on_tree_source on tree(source_url);"


__END__

db.execute <<-SQL, 'caca'
insert into locks values (?);
SQL

p db.execute "select * from locks"


db.execute "delete from locks where key = ?", 'caca'

p db.execute "select * from locks"
