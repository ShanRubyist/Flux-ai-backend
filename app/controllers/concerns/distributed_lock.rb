module DistributedLock
  extend ActiveSupport::Concern

  included do |base|
  end

  module ClassMethods
  end

  def redis_client
    Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" })
  end

  def with_redis_lock(key, timeout = 100)
    lock_key = "lock:#{key}"
    lock_value = SecureRandom.uuid

    attempt = 0
    while attempt < 5
      if redis_client.set(lock_key, lock_value, nx: true, ex: timeout)
        begin
          return yield
        ensure
          redis_client.eval(
            "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end",
            keys: [lock_key],
            argv: [lock_value]
          )
        end
      else
        attempt += 1
        sleep (2 ** attempt + rand(10))
      end

    end
    raise "Failed to acquire lock for #{key}"
  end
end