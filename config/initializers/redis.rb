require 'redis'

uri = URI.parse('localhost:6379')
Redis.current = Redis.new(host: uri.host, port: uri.port)
