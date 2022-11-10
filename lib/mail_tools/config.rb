# frozen_string_literal: true

require "optimist"

require_relative "util/config"

module MailTools
  module Config
    class << self
      def init
        name = "MailTools"
        opts = command_line_options
        env = opts.slice(:user, :password, :port, :host, :dbname).compact
                  .transform_keys { |k| "#{name.upcase}_#{k.to_s.upcase}" }
        env = ENV.merge!(env)
        files = (opts[:files] || []).concat(Util::Config.default_files(name))
        default = { host: "localhost", port: 5432, dbname: "mail" }
        required = %i[user password dbname]
        Util::Config.create(name, prompt: opts[:prompt], required:, env:, default:, files:)
      end

      @config = nil

      def config
        @config ||= init
      end

      private

      def command_line_options
        Optimist::options do
          opt :help, "Show this message"
          opt :prompt, "Prompt for missing options"
          opt :user, "User of primary server", type: :string
          opt :password, "Password for primary server", type: :string
          opt :host, "Host for primary server", type: :string
          opt :port, "Port for primary server", type: :string
          opt :dbname, "name of primary db", type: :string
          opt :config, "Additional config files", type: :string, multi: true
        end.compact
      end
    end
  end
end
