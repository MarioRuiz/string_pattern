class Array
  # It will generate an string following the pattern specified
  # The positions with string patterns need to be supplied like symbols:
  # [:"10:N", "fixed", :"10-20:XN/x/"].generate #> "1024320001fixed4OZjNMTnuBibwwj"
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias_method :gen, :generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: self, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias_method :val, :validate
end

class String
  # it will generate an string following the pattern specified
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias_method :gen, :generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: self, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias_method :val, :validate
end


class Symbol
  # it will generate an string following the pattern specified
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias_method :gen, :generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: self.to_s, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias_method :val, :validate
end


module Kernel
  public
  # if string or symbol supplied it will generate a string with the supplied pattern specified on the string
  # if array supplied then it will generate a string with the supplied patterns. If a position contains a pattern supply it as symbol, for example: [:"10:N", "fixed", :"10-20:XN/x/"]
  def generate(pattern, expected_errors: [], **synonyms)
    if pattern.kind_of?(String) or pattern.kind_of?(Array) or pattern.kind_of?(Symbol)
      StringPattern.generate(pattern, expected_errors: expected_errors, **synonyms)
    else
      puts " Kernel generate method: class not recognized:#{pattern.class}"
    end
  end

  alias_method :gen, :generate
end

