class AlreadyVisitedUrls
  @instances = {}

  def self.instance(domain)
    @instances[domain.name] ||= new(domain)
  end

  def initialize(domain)
    @domain = domain
  end

  def registry
    @registry ||= Set.new(db.execute("select url from parsed_urls").map(&:first))
  end

  def add(url)
    registry << url
  end

  def include?(url)
    registry.include?(url)
  end

  def db
    @db ||= DbWrapper.new @domain
  end
end