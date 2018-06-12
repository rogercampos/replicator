require_relative 'db_wrapper'

class Locker
  @instances = {}

  def self.instance(domain)
    @instances[domain.name] ||= new(domain)
  end


  LOCK_TIMEOUT = 100

  def initialize(domain)
    @domain = domain
  end

  def lock(key, start_time = Time.now.to_f)
    loop do
      begin
        db.execute "insert into locks values (?)", key
        break

      rescue SQLite3::ConstraintException
        if start_time < Time.now.to_f - LOCK_TIMEOUT
          raise "Timeout waiting for lock #{key}. [#{Time.now}]"
        end

        sleep 0.5
      end
    end

    begin
      yield
    ensure
      db.execute "delete from locks where key = ?", key
    end
  end

  def db
    @db ||= DbWrapper.new @domain
  end

  def flush
    db.execute "delete from locks"
  end
end