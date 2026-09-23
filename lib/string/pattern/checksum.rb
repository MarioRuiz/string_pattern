# frozen_string_literal: true

class StringPattern
  # IBAN lengths we can generate. Validation accepts any well-formed IBAN.
  IBAN_LENGTHS = {
    "ES" => 24,
    "DE" => 22,
    "FR" => 27,
    "GB" => 22,
    "PT" => 25,
    "IT" => 27,
    "NL" => 18,
    "BE" => 16
  }.freeze

  # Generates a random IBAN for +country+ (ISO 13616). The BBAN is random, not a real bank account.
  # @param country [String, Symbol] two-letter country code
  # @return [String]
  # @raise [ArgumentError] when the country is not in {IBAN_LENGTHS}
  def self.iban(country:)
    code = country.to_s.upcase
    length = IBAN_LENGTHS[code]
    raise ArgumentError, "unknown IBAN country: #{country.inspect}" unless length

    rng = Random.new
    alphabet = [*("0".."9"), *("A".."Z")]
    bban = Array.new(length - 4) { alphabet.sample(random: rng) }.join
    "#{code}#{iban_check_digits(code, bban)}#{bban}"
  end

  # Returns true when +str+ is a well-formed IBAN (format and mod-97), ignoring spaces.
  # @param str [String]
  # @return [Boolean]
  def self.valid_iban?(str)
    return false unless str.is_a?(String)

    compact = str.gsub(/\s+/, "").upcase
    return false unless compact.match?(/\A[A-Z]{2}\d{2}[A-Z0-9]+\z/)
    return false unless (15..34).cover?(compact.length)

    rearranged = compact[4..] + compact[0, 4]
    iban_mod97(iban_to_digits(rearranged)) == 1
  end

  # Generates a digit string of +length+ that satisfies the Luhn checksum.
  # @param length [Integer] total number of digits, at least 2
  # @return [String]
  # @raise [ArgumentError] when length is below 2
  def self.luhn(length:)
    length = Integer(length)
    raise ArgumentError, "length must be >= 2" if length < 2

    rng = Random.new
    digits = Array.new(length - 1) { rng.rand(10) }
    digits << luhn_check_digit(digits)
    digits.join
  end

  # Returns true when +str+ is a digit string with a valid Luhn checksum.
  # @param str [String]
  # @return [Boolean]
  def self.valid_luhn?(str)
    return false unless str.is_a?(String) && str.match?(/\A\d{2,}\z/)

    luhn_sum(str.chars.map(&:to_i)) % 10 == 0
  end

  def self.iban_check_digits(country, bban)
    remainder = iban_mod97(iban_to_digits("#{bban}#{country}00"))
    format("%02d", 98 - remainder)
  end

  def self.iban_to_digits(value)
    value.each_char.map { |char|
      if char >= "A" && char <= "Z"
        (char.ord - 55).to_s
      else
        char
      end
    }.join
  end

  def self.iban_mod97(digit_string)
    remainder = 0
    digit_string.scan(/.{1,9}/).each do |chunk|
      remainder = "#{remainder}#{chunk}".to_i % 97
    end
    remainder
  end

  def self.luhn_check_digit(payload)
    (10 - (luhn_sum(payload + [0]) % 10)) % 10
  end

  def self.luhn_sum(digits)
    digits.reverse.each_with_index.sum do |digit, index|
      value = digit.to_i
      if index.odd?
        value *= 2
        value -= 9 if value > 9
      end
      value
    end
  end
  private_class_method :iban_check_digits, :iban_to_digits, :iban_mod97, :luhn_check_digit, :luhn_sum
end
