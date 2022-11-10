# frozen_string_literal: true

require_relative "base"
require_relative "input"

module MailTools
  module Command
    class Password < Base
      def default(user, password = nil)
        password = Input.encrypted_password(password)

        result = if user.match? /\A[^@]+@[^@]+\z/
                   db.exec_params("UPDATE users SET password = $1 WHERE address_id IN ("\
                                  "SELECT addresses.id FROM addresses INNER JOIN domains ON domains.id = domain_id "\
                                  "AND addresses.name = $2 AND domains.name = $3 LIMIT 1);",
                                  user.split("@").unshift(password))
                 else
                   db.exec_params("UPDATE users SET password = $1 WHERE name = $2", [password, user])
                 end
        result.check
      end
    end
  end
end
