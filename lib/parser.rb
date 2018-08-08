require 'nokogiri'
require "addressable/uri"

# - returns url-encoded urls
# - returns urls with host and scheme
# - does not return duplicates
# - only returns relative urls or the ones with host == host argument
class Parser
  A_REGEXP = /<a\s+(?:[^>]*?\s+)?href="([^"]*)"/i
  IMG_REGEXP = /<img[^>]+src="([^">]+)"/i
  LINK_REGEXP = /<link\s+(?:[^>]*?\s+)?href="([^"]*)"/i
  SCRIPT_REGEXP = /<script[^>]+src="([^">]+)"/i
  CSS_REGEXP = /[:,\s]\s*url\s*\(\s*(?:'(\S*?)'|"(\S*?)"|((?:\\\s|\\\)|\\\"|\\\'|\S)*?))\s*\)/i

  def initialize(original_url, html, scheme, opts = {})
    @original_url = original_url
    @html = html
    @scheme = scheme
    @opts = opts
  end

  def urls(host:)
    # Skip analyzing heavy files that "potentially" don't contain interesting urls
    # to follow (the site is expected to be static)
    return [] if @original_url =~ /\.(js|eot|woff|woff2|ttf|jpg|png|jpeg|gif)$/i

    begin
      urls = @html.scan(A_REGEXP).map(&:first)
      urls += @html.scan(IMG_REGEXP).map(&:first)
      urls += @html.scan(LINK_REGEXP).map(&:first)
      urls += @html.scan(SCRIPT_REGEXP).map(&:first)

      urls += @html.scan(CSS_REGEXP).flatten.compact.map { |x| x.gsub(/^&quot;/, '').gsub(/&quot;$/, '') }
    rescue ArgumentError => e
      # Ignore binary files
      if e.message == "invalid byte sequence in UTF-8"
        return []
      else
        raise
      end
    end

    urls.compact!

    urls.map! { |x| Nokogiri::HTML.parse(x).text }

    urls.select! { |x|
      begin
        uri = Addressable::URI.parse(Addressable::URI.escape(x))
        uri.host.nil? || uri.host == host
      rescue Addressable::URI::InvalidURIError
        nil
      end
    }

    urls.map! { |x|
      uri = Addressable::URI.parse(Addressable::URI.escape(x))

      if uri.host.nil?
        begin
          uri.host = host
        rescue Addressable::URI::InvalidURIError
          unless uri.path =~ /^\//
            base = Addressable::URI.parse(Addressable::URI.escape(@original_url))
            base.query = nil
            base.fragment = nil
            base.path = nil

            base.query = uri.query
            base.fragment = uri.fragment
            base.path = uri.path
            uri = base

            retry
          else
            next nil
          end
        end

        uri.scheme = @scheme
        uri.to_s
      else
        Addressable::URI.parse(Addressable::URI.escape(x)).to_s
      end
    }

    urls.compact!
    urls.uniq!
    urls
  end
end