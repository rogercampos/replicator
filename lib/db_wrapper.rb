class DbWrapper
  @instances = {}

  def self.instance(domain)
    @instances[domain.name] ||= new(domain)
  end

  def initialize(domain)
    @db = SQLite3::Database.new domain.db_path
    @mutex = Mutex.new
  end

  def method_missing(name, *args, &block)
    @db.send name, *args, &block
  end

  def transaction(&block)
    @mutex.synchronize do
      @db.transaction &block
    end
  end
end