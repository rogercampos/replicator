URL = 'https://supercalorias.com'
CONCURRENCY = 3

require_relative 'replicator'

Replicator.new('supercalorias', URL, CONCURRENCY).run!