SP_ADD_TO_RUBY = true if !defined?(SP_ADD_TO_RUBY)
require_relative "string/pattern/add_to_ruby" if SP_ADD_TO_RUBY
require_relative "string/pattern/analyze"
require_relative "string/pattern/email"
require_relative "string/pattern/generate"
require_relative "string/pattern/validate"

# SP_ADD_TO_RUBY: (TrueFalse, default: true) You need to add this constant value before requiring the library if you want to modify the default.
#               If true it will add 'generate' and 'validate' methods to the classes: Array, String and Symbol. Also it will add 'generate' method to Kernel
#               aliases: 'gen' for 'generate' and 'val' for 'validate'
#               Examples of use:
#                 "(,3:N,) ,3:N,-,2:N,-,2:N".split(",").generate #>(937) 980-65-05
#                 %w{( 3:N ) 1:_ 3:N - 2:N - 2:N}.gen #>(045) 448-63-09
#                 ["1:L", "5-10:LN", "-", "3:N"].gen #>zqWihV-746
#                 gen("10:N") #>3433409877
#                 "20-30:@".gen #>dkj34MljjJD-df@jfdluul.dfu
#                 "10:L/N/[/-./%d%]".validate("12ds6f--.s") #>[:value, :string_set_not_allowed]
#                 "20-40:@".validate(my_email)
# national_chars: (Array, default: english alphabet)
#                 Set of characters that will be used when using T pattern
# optimistic: (TrueFalse, default: true)
#             If true it will check on the strings of the array positions if they have the pattern format and assume in that case that is a pattern.
# dont_repeat: (TrueFalse, default: false)
#             If you want to generate for example 1000 strings and be sure all those strings are different you can set it to true
# default_infinite: (Integer, default: 10)
#             In case using regular expressions the maximum when using * or + for repetitions
# word_separator: (String, default: '_')
#             When generating words using symbol types 'w' or 'p' the character to separate the english or spanish words.
# block_list: (Array, default: empty)
#             Array of words to be avoided from resultant strings.
# block_list_enabled: (TrueFalse, default: false)
#             If true block_list will be take in consideration
#
# @example Generate a string
#   StringPattern.generate("10:N")  # => "3448910834"
# @example Validate and get errors
#   StringPattern.validate(text: "ab", pattern: "6:N")  # => [:min_length, :length]
class StringPattern
  # Raised when an invalid pattern is used and {raise_on_error} is true.
  InvalidPatternError = Class.new(StandardError)
  # Raised when generation is impossible (e.g. exhausted by dont_repeat) and {raise_on_error} is true.
  GenerationImpossibleError = Class.new(StandardError)

  class << self
    # @return [String, nil] When set, warning messages are sent here instead of +puts+.
    attr_accessor :logger
    # @return [Boolean] When true, invalid patterns or impossible generation raise instead of returning "".
    attr_accessor :raise_on_error
    attr_accessor :national_chars, :optimistic, :dont_repeat, :cache, :cache_values, :default_infinite, :word_separator, :block_list, :block_list_enabled
  end
  @national_chars = (("a".."z").to_a + ("A".."Z").to_a).join
  @optimistic = true
  @cache = Hash.new()
  @cache_values = Hash.new()
  @dont_repeat = false
  @default_infinite = 10
  @word_separator = "_"
  @block_list_enabled = false
  @block_list = []
  @logger = nil
  @raise_on_error = false
  NUMBER_SET = ("0".."9").to_a
  SPECIAL_SET = [" ", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "}", "[", "]", "'", ";", ":", "?", ">", "<", "`", "|", "/", '"']
  ALPHA_SET_LOWER = ("a".."z").to_a
  ALPHA_SET_CAPITAL = ("A".."Z").to_a
  @palabras = []
  @palabras_camel = []
  @words = []
  @words_camel = []
  @palabras_short = []
  @words_short = []
  @palabras_camel_short = []
  @words_camel_short = []

  Pattern = Struct.new(:min_length, :max_length, :symbol_type, :required_data, :excluded_data, :data_provided,
                       :string_set, :all_characters_set, :unique)

  def self.national_chars=(par)
    @cache = Hash.new()
    @national_chars = par
  end

  def self.log_message(message)
    if @logger
      @logger.warn(message)
    else
      puts message
    end
  end

  # Returns true if +text+ matches +pattern+; false otherwise. Uses validate under the hood.
  # @param text [String] (synonyms: text_to_validate, validate)
  # @param pattern [String, Symbol, Array]
  # @return [Boolean]
  def self.valid?(text: nil, pattern: nil, **synonyms)
    text = synonyms[:text_to_validate] if text.nil? && synonyms.key?(:text_to_validate)
    text = synonyms[:validate] if text.nil? && synonyms.key?(:validate)
    return false if text.nil? || pattern.nil?
    result = validate(text: text, pattern: pattern, **synonyms)
    pattern.is_a?(Array) ? result == true : result.is_a?(Array) && result.empty?
  end

  # Generates up to +n+ distinct strings for +pattern+. Uses a temporary dont_repeat state.
  # @param pattern [String, Symbol, Array, Regexp]
  # @param n [Integer]
  # @return [Array<String>]
  def self.sample(pattern, n)
    return [] if n <= 0
    old_dont = @dont_repeat
    old_cache = @cache_values.dup
    @dont_repeat = true
    @cache_values = {}
    results = []
    n.times do
      s = generate(pattern)
      break if s.nil? || s.empty?
      results << s
    end
    results
  ensure
    @dont_repeat = old_dont
    @cache_values = old_cache
  end

  # Generates a random UUID v4 (e.g. "550e8400-e29b-41d4-a716-446655440000").
  # @return [String]
  def self.uuid
    require "securerandom"
    SecureRandom.uuid
  end

  # Returns true if +str+ is a valid UUID v4 format (8-4-4-4-12 hex with version and variant bits).
  # @param str [String]
  # @return [Boolean]
  def self.valid_uuid?(str)
    return false unless str.is_a?(String)
    str.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
  end
end
