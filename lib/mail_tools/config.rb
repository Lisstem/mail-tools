# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/deep_dup"
require "active_support/inflector/methods"

require_relative "util"

module MailTools
  class Config
    include Util

    def initialize(default: {}, files: [], env_prefix: nil, env_map: {}, env: ENV)
      @store = object_apply(default, :to_s)
      files.reverse_each { |file| merge(@store, object_apply(YAML.load_file(file), :to_s)) }
      merge(@store, env_hash(env_prefix.to_s, object_apply(env_map, :to_s, values: true), env))
    end

    def missing?(*required_array, **required_hash)
      missing(*required_array, **required_hash).blank?
    end

    def missing(*required_array, **required_hash)
      _missing(@store, object_apply([*required_array, required_hash], :to_s, values: true))&.reject(&:blank?)
    end

    def respond_to_missing?(symbol)
      @store.respond_to? symbol
    end

    def method_missing(symbol, *args, **hash, &block)
      @store.public_send(symbol, *args, **hash, &block)
    end

    def missing_paths(*required_array, **required_hash)
      missing(*required_array, **required_hash)&.map { |m| path(m) }&.flatten(1)
    end

    def inspect
      @store.inspect
    end

    def to_s
      @store.to_s
    end

    def prompt_for_missing(required)
      missing_paths(*required).each do |p|
        print "#{p.join(" ")}: "
        deep_insert(@store, gets.strip, *p)
      end
      self
    end

    def self.load(name, files: :default, prompt: false, required: nil, **options)
      files = default_files(name) if files == :default
      options[:env_prefix] ||= name.upcase
      config = new(files:, **options.slice(:default, :env_prefix, :env_map, :env))
      return config unless required
      
      missing = config.missing(*required)
      return config unless missing
      
      raise Error, "Missing config variables: #{missing.inspect}" unless prompt
      
      config.prompt_for_missing(required)
    end

    def self.default_files(name)
      name = "#{ActiveSupport::Inflector.underscore(name)}.yaml"
      [File.join(Dir.pwd, name), File.join(Dir.home, ".config", name)].select { |f| File.file?(f) }
    end

    private

    def path(missing)
      if missing.respond_to? :each_pair
        path_hash(missing)
      elsif missing.respond_to? :each
        missing.map { |m| path(m) }.flatten(1)
      else
        missing
      end
    end

    def path_hash(hash)
      hash.map do |k, v|
        p = path(v)
        if p.respond_to?(:map)
          p.map { |e| e.respond_to?(:unshift) ? e.unshift(k) : [k, e] }
        else
          [k, p]
        end
      end.flatten(1)
    end

    def _missing(present, required)
      return required unless present

      if required.respond_to? :each_pair
        required.map { |k, v| [k, _missing(present[k], v)] }.to_h.compact
      elsif required.respond_to? :each
        required.map { |e| _missing(present, e) }.compact
      else
        present[required].blank? ? required : nil
      end
    end

    def env_hash(env_prefix, env_map, envs)
      env = {}
      extract_from_env(envs, env_prefix, env_map.transform_keys(&:upcase))
        .each_pair { |k, v| deep_insert(env, v, *k.downcase.split("_")) }
      env
    end

    def extract_from_env(envs, env_prefix, env_map)
      envs.select { |k, _| k.match?(/\A#{env_prefix.upcase}_/) }.transform_keys { |k| k[env_prefix.length + 1..] }
          .merge!(envs.slice(*env_map.keys).transform_keys { |k| env_map[k] })
    end

    def deep_insert(hash, value, *path)
      path[0...-1]&.each do |key|
        hash[key] ||= {}
        hash = hash[key]
      end
      hash[path[-1]] = value
    end

    def merge(target, other)
      raise Error unless other.respond_to? :each_pair

      other.each_pair do |k, v|
        v.respond_to?(:each_pair) ? merge(target[k], v) : target[k] = v
      end
      target
    end
  end
end
