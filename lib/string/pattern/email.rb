# frozen_string_literal: true

class StringPattern
  # Validates email format using the same rules as pattern type @:
  # - Forbids consecutive/adjacent invalid sequences (.. __ -- etc.)
  # - Local part: [a-z0-9]+([\+\._\-][a-z0-9])*
  # - Domain part: [0-9a-z]+([\.-][a-z0-9])*
  def self.valid_email?(string)
    return false if string.nil? || !string.is_a?(String)
    return false if string.index("@").to_i <= 0

    wrong = %w(.. __ -- ._ _. .- -. _- -_ @. @_ @- .@ _@ -@ @@)
    return false if Regexp.union(*wrong) === string

    local = string[0..(string.index("@") - 1)]
    domain = string[(string.index("@") + 1)..-1]
    local_ok = local.scan(/([a-z0-9]+([\+\._\-][a-z0-9]|)*)/i).join == local
    domain_ok = domain.scan(/([0-9a-z]+([\.-][a-z0-9]|)*)/i).join == domain
    local_ok && domain_ok
  end
end
