require_relative 'lib/replicator'
require_relative 'lib/domain'

Process.setproctitle("Replicator")

domain = ARGV[0]

if domain.nil?
  puts "Please use ruby init.rb <domain name>"
  exit 1
end

domain = Domain.new domain

Replicator.new(domain, 5).run!