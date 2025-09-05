class SimpleCache
    def initialize
        @store = {}
    end

    def get(key)
        return @store[key] if @store.key?(key)
        nil
    end

    def set(key, value)
        @store[key] = value
    end
end