require "lru/memcache/demo/version"

module Lru
  module Memcache
    module Demo
      class Cache
        attr_reader :mem_limit, :head, :tail, :size

        def initialize(mem_limit: 100)
          @mem_limit = mem_limit
          @lookup = {}
          @head = nil
          @tail = nil
          @size = 0
        end

        def store(key, val)
          @lookup[key] ? replace(key, val) : create(key, val)
        end

        def replace(key, val)
          elem = @lookup[key]
          elem.val = val
        end

        def create(key, val)
          new_element = Element.new(key, val)
          old_head = @head

          # attach new element to previous head
          new_element.next_elem = old_head
          old_head.prev_elem = new_element if old_head

          # set tail pointer if necessary
          @tail = new_element if new_element.next_elem.nil?
          @tail = old_head if old_head && old_head.next_elem.nil?

          # now move the head "pointer" var
          @head = new_element

          @size += 1
          shrink
          @lookup[key] = new_element
        end

        def pop
          return unless @tail

          # remove from lookup table
          @lookup.delete @tail.key

          # attach "pointer" to new tail and remove reference to old tail
          @tail = @tail.prev_elem
          @tail.next_elem = nil if @tail
          @size -= 1

          @tail
        end

        def shrink
          while (size > mem_limit)
            pop
          end
        end

        # Attempts to retrieve the value at key. Returns nil
        # if it does not exist.
        def retrieve(key)
          found_element = @lookup[key]

          if found_element
            prev_elem = found_element.prev_elem
            Element.swap found_element.prev_elem, found_element
            @head = found_element if found_element.prev_elem.nil?
            @tail = prev_elem if prev_elem&.next_elem.nil?
            found_element.read
          end
        end

        def list
          Enumerator.new do |y|
            current = @head
            while(current)
              y.yield current.key
              current = current.next_elem
            end
          end
        end
      end

      class Element
        def self.remove(elem)
          return unless elem
          before_elem = elem.prev_elem
          after_elem = elem.next_elem

          before_elem.next_elem = after_elem if before_elem
          after_elem.prev_elem = before_elem if after_elem
        end

        def self.swap(elem_a, elem_b)
          # no action if element is already head or tail of the list
          return true unless elem_a && elem_b

          # ensure elem_a and elem_b are actually neighbors
          return unless elem_a.next_elem == elem_b
          return unless elem_b.prev_elem == elem_a

          before_elem = elem_a.prev_elem
          after_elem = elem_b.next_elem

          before_elem.next_elem = elem_b if before_elem
          elem_b.prev_elem = before_elem
          elem_b.next_elem = elem_a
          elem_a.prev_elem = elem_b
          elem_a.next_elem = after_elem
          after_elem.prev_elem = elem_a if after_elem

          true
        end

        attr_accessor :key, :val
        attr_accessor :next_elem, :prev_elem
        attr_reader :accessed_at

        def initialize(key, val)
          @key = key
          @val = val
          touch
        end

        def read
          touch
          val
        end

        def touch
          @accessed_at = Time.now
        end

        def debug
          { key: key, next: next_elem&.key, prev: prev_elem&.key}
        end
      end

    end
  end
end
