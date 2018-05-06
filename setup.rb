require 'rubygems'
require 'bundler/setup'

require "sqlite3"
require 'fileutils'

FileUtils.rm_f 'database.db'
FileUtils.rm_r Dir.glob('camaloon/*')

db = SQLite3::Database.new "database.db"

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
    url     varchar(5000)
  );
SQL

db.execute "create unique index key_on_pending_urls on pending_urls(url);"

__END__

db.execute <<-SQL, 'caca'
insert into locks values (?);
SQL

p db.execute "select * from locks"


db.execute "delete from locks where key = ?", 'caca'

p db.execute "select * from locks"
