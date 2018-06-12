class DbWrapper
  def initialize(domain)
    @db = SQLite3::Database.new domain.db_path
  end

  def method_missing(name, *args, &block)
    @db.send name, *args, &block
  end

  def execute(*args)
    i = 0

    begin
      @db.execute *args

    rescue SQLite3::BusyException
      i += 1

      if i < 4
        sleep 0.1
        retry
      else
        raise
      end
    end

  end
end