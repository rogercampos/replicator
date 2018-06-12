require 'httparty'

class Downloader
  def initialize(url)
    @url = url
  end

  def get
    with_retry { HTTParty.get(@url).body }
  end

  def works?
    with_retry { HTTParty.get(@url).success? }
  end

  private

  def with_retry
    i = 1
    yield

  rescue Net::OpenTimeout, OpenSSL::SSL::SSLError, Errno::ETIMEDOUT
    if i < 3 # 3 tries
      i += 1
      retry
    else
      raise
    end
  end
end