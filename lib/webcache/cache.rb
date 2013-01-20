# WebCache Cache
#
#   Copyright (c) 2013  Dmitry Borodaenko <angdraug@debian.org>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 3 or later.
#
# vim: et sw=2 sts=2 ts=8 tw=0

require 'singleton'

module WebCache

class CacheEntry
  def initialize
    @mutex = Mutex.new
    @value = nil
    record_access
  end

  attr_accessor :value
  attr_reader :mutex

  def record_access
    @atime = Time.now
  end

  def override_index
    - ((Time.now - @atime)/60).ceil * @value.size
  end
end

class Cache
  include Singleton

  SIZE = 5242880
  LOCK_TICK = 0.04

  def initialize
    @mutex = Mutex.new
    @cache = {}
    @size = 0
  end

  def delete(key)
    @mutex.synchronize do
      @cache.delete(key)
    end
  end

  def []=(key, value)
    return value unless value.respond_to?(:size) and value.size <= SIZE
    entry = get_locked_entry(key)
    begin
      @mutex.synchronize do
        @size += value.size
        entry.value = value
        check_size
      end
      return value
    ensure
      entry.mutex.unlock
    end
  end

  def [](key)
    entry = get_locked_entry(key, false)
    return nil if entry.nil?
    begin
      return entry.value
    ensure
      entry.mutex.unlock
    end
  end

  private

  def get_locked_entry(key, add_if_missing = true)
    entry = nil
    entry_locked = false
    until entry_locked do
      @mutex.synchronize do
        entry = @cache[key]

        if entry.nil?
          if add_if_missing
            entry = @cache[key] = CacheEntry.new
          else
            return nil
          end
        end

        entry_locked = entry.mutex.try_lock
      end
      sleep(rand * LOCK_SLEEP) unless entry_locked
    end

    entry.record_access
    entry
  end

  def check_size
    while @size > SIZE do
      key = @cache.keys.min {|a, b| @cache[a].override_index <=> @cache[b].override_index }
      if key
        entry = @cache.delete(key)
        @size -= entry.value.size
      end
    end
  end
end

end
