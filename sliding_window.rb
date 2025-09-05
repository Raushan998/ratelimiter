require 'thread'
require_relative './simple_cache.rb'

# In real life scenario it is a nosql database storing the information about each user/ip/token.
CONFIG_STORE = {
    user_123456:{
        "time_window_sec": 1,
        "capacity": 100
    },
    user_123457:{
        "time_window_sec": 1,
        "capacity": 115
    },
    user_123458:{
        "time_window_sec": 1,
        "capacity": 112
    }
}

REQUEST_STORE = {
    user_123456:{
        "1757106001": 12,
        "1757106002": 16,
        "1757106003": 18,
        "1757106004": 12,
        "1757106005": 12,
        "1757106006": 14,
        "1757106007": 15,
        "1757106008": 17,
        "1757106009": 18,
        "1757106010": 16,
        "1757106011": 11
    },
    user_123457:{
        "1557106120": 16,
        "1577106120": 13,
        "1597106120": 18,
        "1617106120": 13,
        "1637106120": 12,
        "1657106120": 10,
        "1677106120": 18,
        "1697106120": 19,
        "1717106120": 17,
        "1737106120": 13,
        "1757106120": 17,
        "1777106120": 13
    }
}

class DeviceEngine
    def initialize
        @cache = SimpleCache.new
        @mutex = Mutex.new
    end

    def get_ratelimit_config(key)
        value = @cache.get(key)

        if value.nil?
            value = CONFIG_STORE[key]
            @cache.set(key, value)
        end
        value
    end

    def get_current_window(key, start_time)
        ts_data = REQUEST_STORE[key]

        total_requests = 0
        @mutex.synchronize do
            ts_data.each do |k,v|
                if k.to_s.to_i >= start_time
                    total_requests += v
                else
                    ts_data.delete(k)
                end
            end
        end       

        total_requests
    end

    def register_request(key, ts)
        @mutex.synchronize do
            REQUEST_STORE[key][ts] ||= {}
            REQUEST_STORE[key][ts] = REQUEST_STORE[key][ts].to_s.to_i + 1
        end
    end

    def allow?(key, ts)
        config = get_ratelimit_config(key.to_sym)
        start_time = ts - config[:time_window_sec]

        total_requests = get_current_window(key.to_sym, start_time)

        if total_requests < config[:capacity]
            register_request(key.to_sym, ts)
            return true
        else
            false
        end
    end
end

engine = DeviceEngine.new

puts engine.allow?("user_123456", 1757106001)
puts engine.allow?("user_123456", 1757106002)
puts engine.allow?("user_123456", 1757106003)
puts engine.allow?("user_123456", 1757106004)
puts engine.allow?("user_123456", 1757106005)
puts engine.allow?("user_123456", 1757106006)
puts engine.allow?("user_123456", 1757106007)
puts engine.allow?("user_123456", 1757106008)
puts engine.allow?("user_123456", 1757106009)
puts engine.allow?("user_123456", 1757106010)
puts engine.allow?("user_123456", 1757106011)
