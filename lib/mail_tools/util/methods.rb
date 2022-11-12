# frozen_string_literal: true

module MailTools
  module Util
    module Methods
      private

      def object_apply(object, sym, values: false)
        if object.respond_to? :each_pair
          object.map { |k, v| [k.public_send(sym), object_apply(v, sym, values:)] }.to_h
        elsif object.respond_to? :each
          object.map { |o| object_apply(o, sym, values:) }
        else
          values ? object.public_send(sym) : object
        end
      end

      def deep_merge_hashes(target, other)
        raise Error unless other.respond_to? :each_pair

        other.each_pair do |k, v|
          v.respond_to?(:each_pair) ? deep_merge_hashes(target[k] ||= {}, v) : target[k] = v
        end
        target
      end

      def deep_insert(hash, value, *path)
        path[0...-1]&.each do |key|
          hash[key] ||= {}
          hash = hash[key]
        end
        hash[path[-1]] = value
      end
    end
  end
end
