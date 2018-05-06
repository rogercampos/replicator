URL = 'https://camaloon.es'
CONCURRENCY = 3

require_relative 'replicator'

Replicator.new('camaloon', URL, CONCURRENCY).run!