# frozen_string_literal: true

require_relative "mail_tools/version"
require_relative "mail_tools/config"
require_relative "mail_tools/util"
require_relative "mail_tools/db"
require_relative "mail_tools/command"

module MailTools
  class Error < StandardError; end

end
