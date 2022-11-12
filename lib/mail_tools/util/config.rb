# frozen_string_literal: true

require "yaml"
require "io/console"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/deep_dup"
require "active_support/inflector/methods"

require_relative "methods"
require_relative "behaviour"

module MailTools
  module Util
    class Config
      include Methods
      extend Behaviour

      default_behavior_like :store

      def initialize(default: {}, files: [], env_prefix: nil, env_map: {}, env: ENV)
        @store = object_apply(default, :to_s)
        files.reverse_each { |file| deep_merge_hashes(@store, object_apply(YAML.load_file(file), :to_s)) }
        deep_merge_hashes(@store, env_hash(env_prefix.to_s, object_apply(env_map, :to_s, values: true), env))
      end

      def missing?(*required_array, **required_hash)
        !missing(*required_array, **required_hash).blank?
      end

      def missing(*required_array, **required_hash)
        _missing(@store, object_apply([*required_array, required_hash], :to_s, values: true))&.reject(&:blank?)
      end

      def missing_paths(*required_array, **required_hash)
        missing(*required_array, **required_hash).map { |m| path(m) }.flatten(1)
      end
      
      def merge(more_options)
        deep_merge_hashes(@store, object_apply(more_options, :to_s))
      end

      def inspect
        @store.inspect
      end

      def to_s
        @store.to_s
      end

      def prompt_for_missing(*missing, input: $stdin)
        _prompt_for_missing(missing_paths(*missing), input)
      end

      def self.create(name, **options)
        options = { prompt: false, required: nil, input: $stdin, files: default_files(name),
                    env_prefix: name.upcase }.merge(options)
        config = new(**options.slice(:default, :env_prefix, :env_map, :env, :files))
        check_required(config, **options)
      end

      def self.default_files(name)
        name = "#{ActiveSupport::Inflector.underscore(name)}.yaml"
        [File.join(Dir.pwd, name), File.join(Dir.home, ".config", name)].select { |f| File.file?(f) }
      end

      private

      def self.check_required(config, required: nil, prompt: false, input: $stdin)
        return config unless required

        required_array = required.reject { |r| r.respond_to? :merge }
        required_hash = required.select { |r| r.respond_to? :merge }.reduce(&:merge)
        missing = config.missing(*required_array, **required_hash)
        return config if missing.blank?

        raise Error, "Missing config variables: #{missing.inspect}" unless prompt

        config._prompt_for_missing(missing, input)
      end

      def _prompt_for_missing(missing, input = $stdin)
        missing.each do |p|
          print "#{p.respond_to?(:join) ? p.join(" ") : p}: "
          value = (p.respond_to?(:include?) && p.include?("password")) || p == "password" ? input.getpass : input.gets
          deep_insert(@store, value.strip, *p)
        end
        self
      end

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
            [[k, p]]
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
    end
  end
end
