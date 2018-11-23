SP_ADD_TO_RUBY = true if !defined?(SP_ADD_TO_RUBY)
require_relative 'string/pattern/add_to_ruby' if SP_ADD_TO_RUBY

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
class StringPattern
  class << self
    attr_accessor :national_chars, :optimistic, :dont_repeat, :cache, :cache_values
  end
  @national_chars = (('a'..'z').to_a + ('A'..'Z').to_a).join
  @optimistic = true
  @cache = Hash.new()
  @cache_values = Hash.new()
  @dont_repeat = false
  NUMBER_SET = ('0'..'9').to_a
  SPECIAL_SET = [' ', '~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=', '{', '}', '[', ']', "'", ';', ':', '?', '>', '<', '`', '|', '/', '"']
  ALPHA_SET_LOWER = ('a'..'z').to_a
  ALPHA_SET_CAPITAL = ('A'..'Z').to_a


  Pattern = Struct.new(:min_length, :max_length, :symbol_type, :required_data, :excluded_data, :data_provided,
                       :string_set, :all_characters_set)

  ###############################################
  # Analyze the pattern supplied and returns an object of Pattern structure including:
  # min_length, max_length, symbol_type, required_data, excluded_data, data_provided, string_set, all_characters_set
  ###############################################
  def StringPattern.analyze(pattern, silent: false)
    return @cache[pattern.to_s] unless @cache[pattern.to_s].nil?
    min_length, max_length, symbol_type = pattern.to_s.scan(/(\d+)-(\d+):(.+)/)[0]
    if min_length.nil?
      min_length, symbol_type = pattern.to_s.scan(/^!?(\d+):(.+)/)[0]
      max_length = min_length
      if min_length.nil?
        puts "pattern argument not valid on StringPattern.generate: #{pattern.inspect}" unless silent
        return pattern.to_s
      end
    end

    symbol_type = '!' + symbol_type if pattern.to_s[0] == '!'
    min_length = min_length.to_i
    max_length = max_length.to_i

    required_data = Array.new
    excluded_data = Array.new
    required = false
    excluded = false
    data_provided = Array.new
    a = symbol_type
    begin_provided = a.index('[')
    excluded_end_tag = false
    unless begin_provided.nil?
      c = begin_provided + 1
      until c == a.size or (a[c..c] == ']' and a[c..c + 1] != ']]')
        if a[c..c + 1] == ']]'
          data_provided.push(']')
          c = c + 2
        elsif a[c..c + 1] == '%%' and !excluded then
          data_provided.push('%')
          c = c + 2
        else
          if a[c..c] == '/' and !excluded
            if a[c..c + 1] == '//'
              data_provided.push(a[c..c])
              if required
                required_data.push([a[c..c]])
              end
              c = c + 1
            else
              if !required
                required = true
              else
                required = false
              end
            end
          else
            if required
              required_data.push([a[c..c]])
            else
              if a[c..c] == '%'
                if a[c..c + 1] == '%%' and excluded
                  excluded_data.push([a[c..c]])
                  c = c + 1
                else
                  if !excluded
                    excluded = true
                  else
                    excluded = false
                    excluded_end_tag = true
                  end
                end
              else
                if excluded
                  excluded_data.push([a[c..c]])
                end
              end

            end
            if excluded == false and excluded_end_tag == false
              data_provided.push(a[c..c])
            end
            excluded_end_tag = false
          end
          c = c + 1
        end
      end
      symbol_type = symbol_type[0..begin_provided].to_s + symbol_type[c..symbol_type.size].to_s
    end

    required = false
    required_symbol = ''
    if symbol_type.include?("/")
      symbol_type.chars.each {|stc|
        if stc == '/'
          if !required
            required = true
          else
            required = false
          end
        else
          if required
            required_symbol += stc
          end
        end
      }
    end

    national_set = @national_chars.chars

    if symbol_type.include?('L') then
      alpha_set = ALPHA_SET_LOWER + ALPHA_SET_CAPITAL
    elsif symbol_type.include?('x')
      alpha_set = ALPHA_SET_LOWER
      if symbol_type.include?('X')
        alpha_set = alpha_set + ALPHA_SET_CAPITAL
      end
    elsif symbol_type.include?('X')
      alpha_set = ALPHA_SET_CAPITAL
    else
      alpha_set = []
    end
    if symbol_type.include?('T')
      alpha_set = alpha_set + national_set
    end

    unless required_symbol.nil?
      if required_symbol.include?('x')
        required_data.push ALPHA_SET_LOWER
      end
      if required_symbol.include?('X')
        required_data.push ALPHA_SET_CAPITAL
      end
      if required_symbol.include?('L')
        required_data.push(ALPHA_SET_CAPITAL + ALPHA_SET_LOWER)
      end
      if required_symbol.include?('T')
        required_data.push national_set
      end
      required_symbol = required_symbol.downcase
    end
    string_set = Array.new
    all_characters_set = ALPHA_SET_CAPITAL + ALPHA_SET_LOWER + NUMBER_SET + SPECIAL_SET + data_provided + national_set

    if symbol_type.include?('_')
      unless symbol_type.include?('$')
        string_set.push(' ')
      end
      if required_symbol.include?('_')
        required_data.push([' '])
      end
    end

    symbol_type = symbol_type.downcase

    if symbol_type.include?('x') or symbol_type.include?('l') or symbol_type.include?('t')
      string_set = string_set + alpha_set
    end
    if symbol_type.include?('n')
      string_set = string_set + NUMBER_SET
    end
    if symbol_type.include?('$')
      string_set = string_set + SPECIAL_SET
    end
    if symbol_type.include?('*')
      string_set = string_set + all_characters_set
    end
    if data_provided.size != 0
      string_set = string_set + data_provided
    end
    unless required_symbol.empty?
      if required_symbol.include?('n')
        required_data.push NUMBER_SET
      end
      if required_symbol.include?('$')
        required_data.push SPECIAL_SET
      end
    end
    unless excluded_data.empty?
      string_set = string_set - excluded_data.flatten
    end
    string_set.uniq!
    @cache[pattern.to_s] = Pattern.new(min_length, max_length, symbol_type, required_data, excluded_data, data_provided,
                                       string_set, all_characters_set)
    return @cache[pattern.to_s]
  end

  ###############################################
  #   Generate a random string based on the pattern supplied
  #   (if SP_ADD_TO_RUBY==true, by default is true) To simplify its use it is part of the String, Array, Symbol and Kernel Ruby so can be easily used also like this:
  #     "10-15:Ln/x/".generate    #generate method on String class (alias: gen)
  #     ['(', :'3:N', ')', :'6-8:N'].generate    #generate method on Array class (alias: gen)
  #     generate("10-15:Ln/x/")   #generate Ruby Kernel method
  #     generate(['(', :'3:N', ')', :'6-8:N'])   #generate Ruby Kernel method
  #     "(,3:N,) ,3:N,-,2:N,-,2:N".split(",").generate #>(937) #generate method on Array class (alias: gen)
  #     %w{( 3:N ) 1:_ 3:N - 2:N - 2:N}.gen #generate method on Array class, using alias gen method
  #   Input:
  #     pattern: array or string of different patterns. A pattern is a string with this info:
  #       "length:symbol_type" or "min_length-max_length:symbol_type"
  #		In case an array supplied, the positions using a string pattern should be supplied as symbols if StringPattern.optimistic==false
  #
  #   These are the possible string patterns you will be able to supply:
  #     If at the beginning we supply the character ! the resulting string won't fulfill the pattern. This character need to be the first character of the pattern.
  #     min_length -- minimum length of the string
  #     max_length (optional) -- maximum length of the string. If not provided the result will be with the min_length provided
  #     symbol_type -- the type of the string we want.
  #                   you can use a combination of any ot these:
  #                     x for alpha in lowercase
  #                     X for alpha in capital letters
  #                     L for all kind of alpha in capital and lower letters
  #                     T For the national characters defined on StringPattern.national_chars
  #                     n for number
  #                     $ for special characters (includes space)
  #                     _ for space
  #                     * all characters
  #                     [characters] the characters we want. If we want to add also the ] character you have to write: ]]. If we want to add also the % character you have to write: %%
  #                     %characters% the characters we don't want on the resulting string. %% to exclude the character %
  #                     /symbols or characters/ If we want these characters to be included on the resulting string. If we want to add also the / character you have to write: //
  #                   We can supply 0 to allow empty strings, this character need to be at the beginning
  #                   If you want to include the character " use \"
  #                   If you want to include the character \ use \\
  #                   If you want to include the character [ use \[
  #                   Another uses: @ for email
  #   Examples:
  #    [:"6:X", :"3-8:_N"]
  #       # it will return a string starting with 6 capital letters and then a string containing numbers and space from 3 to 8 characters, for example: "LDJKKD34 555"
  #    [:"6-15:L_N", "fixed text", :"3:N"]
  #       # it will return a string of 6-15 characters containing Letters-spaces-numbers, then the text: 'fixed text' and at the end a string of 3 characters containing numbers, for example: ["L_N",6,15],"fixed text",["N",3] "3 Am399 afixed text882"
  #    "10-20:LN[=#]"
  #       # it will return a string of 10-20 characters containing Letters and/or numbers and/or the characters = and #, for example: eiyweQFWeL#do4Vl
  #     "30:TN_[#=]/x/"
  #       # it will return a string of 30 characters containing national characters defined on StringPattern.national_chars and/or numbers and/or spaces and/or the characters # = and it is necessary the resultant string includes lower alpha chars. For example: HaEdQTzJ3=OtXMh1mAPqv7NCy=upLy
  #     "10:N[%0%]"
  #       # 10 characters length containing numbers and excluding the character 0, for example: 3523497757
  #     "10:N[%0%/AB/]"
  #       # 10 characters length containing numbers and excluding the character 0 and necessary to contain the characters A B, for example: 3AA4AA57BB
  #     "!10:N[%0%/AB/]"
  #       # it will generate a string that doesn't fulfill the pattern supplied, examples:
  #       # a6oMQ4JK9g
  #       # /Y<N6Aa[ae
  #       # 3444439A34B32
  #     "10:N[%0%/AB/]", errors: [:length]
  #       # it will generate a string following the pattern and with the errors supplied, in this case, length, example: AB44
  #   Output:
  #     the generated string
  ###############################################
  def StringPattern.generate(pattern, expected_errors: [], **synonyms)
    tries = 0
    begin
      good_result = true
      tries += 1
      string = ''

      expected_errors = synonyms[:errors] if synonyms.keys.include?(:errors)

      if expected_errors.kind_of?(Symbol)
        expected_errors = [expected_errors]
      end

      if pattern.kind_of?(Array)
        pattern.each {|pat|
          if pat.kind_of?(Symbol)
            if pat.to_s.scan(/^!?\d+-?\d*:.+/).size > 0
              string << StringPattern.generate(pat.to_s, expected_errors: expected_errors)
            else
              string << pat.to_s
            end
          elsif pat.kind_of?(String) then
            if @optimistic and pat.to_s.scan(/^!?\d+-?\d*:.+/).size > 0
              string << StringPattern.generate(pat.to_s, expected_errors: expected_errors)
            else
              string << pat
            end
          else
            puts "StringPattern.generate: it seems you supplied wrong array of patterns: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
            return ''
          end
        }
        return string
      elsif pattern.kind_of?(String) or pattern.kind_of?(Symbol)
        patt = StringPattern.analyze(pattern)
        min_length = patt.min_length
        max_length = patt.max_length
        symbol_type = patt.symbol_type

        required_data = patt.required_data
        excluded_data = patt.excluded_data
        string_set = patt.string_set
        all_characters_set = patt.all_characters_set

        required_chars = Array.new
        unless required_data.size == 0
          required_data.each {|rd|
            required_chars << rd if rd.size == 1
          }
          unless excluded_data.size == 0
            if (required_chars.flatten & excluded_data.flatten).size > 0
              puts "pattern argument not valid on StringPattern.generate, a character cannot be required and excluded at the same time: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
              return ''
            end
          end
        end
        string_set_not_allowed = Array.new

      else
        puts "pattern argument not valid on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
        return pattern.to_s
      end


      allow_empty = false
      deny_pattern = false
      if symbol_type[0..0] == '!'
        deny_pattern = true
        possible_errors = [:length, :value, :required_data, :excluded_data, :string_set_not_allowed]
        (rand(possible_errors.size) + 1).times {
          expected_errors << possible_errors.sample
        }
        expected_errors.uniq!
        if symbol_type[1..1] == '0'
          allow_empty = true
        end
      elsif symbol_type[0..0] == '0' then
        allow_empty = true
      end

      if expected_errors.include?(:min_length) or expected_errors.include?(:length) or
          expected_errors.include?(:max_length)
        allow_empty = !allow_empty
      elsif expected_errors.include?(:value) or
          expected_errors.include?(:excluded_data) or
          expected_errors.include?(:required_data) or
          expected_errors.include?(:string_set_not_allowed) and allow_empty
        allow_empty = false
      end

      length = min_length
      symbol_type_orig = symbol_type

      expected_errors_left = expected_errors.dup

      symbol_type = symbol_type_orig

      unless deny_pattern
        if required_data.size == 0 and expected_errors_left.include?(:required_data)
          puts "required data not supplied on pattern so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
          return ''
        end

        if excluded_data.size == 0 and expected_errors_left.include?(:excluded_data)
          puts "excluded data not supplied on pattern so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
          return ''
        end

        if expected_errors_left.include?(:string_set_not_allowed)
          string_set_not_allowed = all_characters_set - string_set
          if string_set_not_allowed.size == 0 then
            puts "all characters are allowed so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
            return ''
          end
        end
      end

      if expected_errors_left.include?(:min_length) or
          expected_errors_left.include?(:max_length) or
          expected_errors_left.include?(:length)
        if expected_errors_left.include?(:min_length) or
            (min_length > 0 and expected_errors_left.include?(:length) and rand(2) == 0)
          if min_length > 0
            if allow_empty
              length = rand(min_length).to_i
            else
              length = rand(min_length - 1).to_i + 1
            end
            if required_data.size > length and required_data.size < min_length
              length = required_data.size
            end
            expected_errors_left.delete(:length)
            expected_errors_left.delete(:min_length)
          else
            puts "min_length is 0 so it won't be possible to generate a wrong string smaller than 0 characters. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
            return ''
          end
        elsif expected_errors_left.include?(:max_length) or expected_errors_left.include?(:length)
          length = max_length + 1 + rand(max_length).to_i
          expected_errors_left.delete(:length)
          expected_errors_left.delete(:max_length)
        end
      else
        if allow_empty and rand(7) == 1
          length = 0
        else
          if max_length == min_length
            length = min_length
          else
            length = min_length + rand(max_length - min_length + 1)
          end
        end
      end

      if deny_pattern
        if required_data.size == 0 and expected_errors_left.include?(:required_data)
          expected_errors_left.delete(:required_data)
        end

        if excluded_data.size == 0 and expected_errors_left.include?(:excluded_data)
          expected_errors_left.delete(:excluded_data)
        end

        if expected_errors_left.include?(:string_set_not_allowed)
          string_set_not_allowed = all_characters_set - string_set
          if string_set_not_allowed.size == 0
            expected_errors_left.delete(:string_set_not_allowed)
          end
        end

        if symbol_type == '!@' and expected_errors_left.size == 0 and !expected_errors.include?(:length) and
            (expected_errors.include?(:required_data) or expected_errors.include?(:excluded_data))
          expected_errors_left.push(:value)
        end

      end

      string = ''
      if symbol_type != '@' and symbol_type != '!@' and length != 0 and string_set.size != 0
        if string_set.size != 0
          1.upto(length) {|i| string << string_set.sample.to_s
          }
        end
        if required_data.size > 0
          positions_to_set = (0..(string.size - 1)).to_a
          required_data.each {|rd|
            if (string.chars & rd).size > 0
              rd_to_set = (string.chars & rd).sample
            else
              rd_to_set = rd.sample
            end
            if ((0...string.length).find_all {|i| string[i, 1] == rd_to_set}).size == 0
              if positions_to_set.size == 0
                puts "pattern not valid on StringPattern.generate, not possible to generate a valid string: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
                return ''
              else
                k = positions_to_set.sample
                string[k] = rd_to_set
                positions_to_set.delete(k)
              end
            else
              k = ((0...string.length).find_all {|i| string[i, 1] == rd_to_set}).sample
              positions_to_set.delete(k)
            end
          }
        end
        excluded_data.each {|ed|
          if (string.chars & ed).size > 0
            (string.chars & ed).each {|s|
              string.gsub!(s, string_set.sample)
            }
          end
        }

        if expected_errors_left.include?(:value)
          string_set_not_allowed = all_characters_set - string_set if string_set_not_allowed.size == 0
          if string_set_not_allowed.size == 0
            puts "Not possible to generate a non valid string on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
            return ''
          end
          (rand(string.size) + 1).times {
            string[rand(string.size)] = (all_characters_set - string_set).sample
          }
          expected_errors_left.delete(:value)
        end

        if expected_errors_left.include?(:required_data) and required_data.size > 0
          (rand(required_data.size) + 1).times {
            chars_to_remove = required_data.sample
            chars_to_remove.each {|char_to_remove|
              string.gsub!(char_to_remove, (string_set - chars_to_remove).sample)
            }
          }
          expected_errors_left.delete(:required_data)
        end

        if expected_errors_left.include?(:excluded_data) and excluded_data.size > 0
          (rand(string.size) + 1).times {
            string[rand(string.size)] = excluded_data.sample.sample
          }
          expected_errors_left.delete(:excluded_data)
        end

        if expected_errors_left.include?(:string_set_not_allowed)
          string_set_not_allowed = all_characters_set - string_set if string_set_not_allowed.size == 0
          if string_set_not_allowed.size > 0
            (rand(string.size) + 1).times {
              string[rand(string.size)] = string_set_not_allowed.sample
            }
            expected_errors_left.delete(:string_set_not_allowed)
          end
        end

      elsif (symbol_type == '@' or symbol_type == '!@') and length > 0
        if min_length > 6 and length < 6
          length = 6
        end
        if deny_pattern and
            (expected_errors.include?(:required_data) or expected_errors.include?(:excluded_data) or
                expected_errors.include?(:string_set_not_allowed))
          expected_errors_left.push(:value)
          expected_errors.push(:value)
          expected_errors.uniq!
          expected_errors_left.uniq!
        end

        expected_errors_left_orig = expected_errors_left.dup
        tries = 0
        begin
          expected_errors_left = expected_errors_left_orig.dup
          tries += 1
          string = ''
          alpha_set = ALPHA_SET_LOWER + ALPHA_SET_CAPITAL
          string_set = alpha_set + NUMBER_SET + ['.'] + ['_'] + ['-']
          string_set_not_allowed = all_characters_set - string_set

          extension = '.'
          at_sign = '@'

          if expected_errors_left.include?(:value)
            if rand(2) == 1
              extension = (all_characters_set - ['.']).sample
              expected_errors_left.delete(:value)
              expected_errors_left.delete(:required_data)
            end
            if rand(2) == 1
              1.upto(rand(7)) {|i| extension << alpha_set.sample.downcase
              }
              (rand(extension.size) + 1).times {
                extension[rand(extension.size)] = (string_set - alpha_set - ['.']).sample
              }
              expected_errors_left.delete(:value)
            else
              1.upto(rand(3) + 2) {|i| extension << alpha_set.sample.downcase
              }
            end
            if rand(2) == 1
              at_sign = (string_set - ['@']).sample
              expected_errors_left.delete(:value)
              expected_errors_left.delete(:required_data)
            end
          else
            if length > 6
              1.upto(rand(3) + 2) {|i| extension << alpha_set.sample.downcase
              }
            else
              1.upto(2) {|i| extension << alpha_set.sample.downcase
              }
            end
          end
          length_e = length - extension.size - 1
          length1 = rand(length_e - 1) + 1
          length2 = length_e - length1
          1.upto(length1) {|i| string << string_set.sample}

          string << at_sign

          domain = ''
          domain_set = alpha_set + NUMBER_SET + ['.'] + ['-']
          1.upto(length2) {|i| domain << domain_set.sample.downcase
          }

          if expected_errors.include?(:value) and rand(2) == 1 and domain.size > 0
            (rand(domain.size) + 1).times {
              domain[rand(domain.size)] = (all_characters_set - domain_set).sample
            }
            expected_errors_left.delete(:value)
          end
          string << domain << extension

          if expected_errors_left.include?(:value) or expected_errors_left.include?(:string_set_not_allowed)
            (rand(string.size) + 1).times {
              string[rand(string.size)] = string_set_not_allowed.sample
            }
            expected_errors_left.delete(:value)
            expected_errors_left.delete(:string_set_not_allowed)
          end

          error_regular_expression = false

          if deny_pattern and expected_errors.include?(:length)
            good_result = true #it is already with wrong length
          else
            # I'm doing this because many times the regular expression checking hangs with these characters
            wrong = %w(.. __ -- ._ _. .- -. _- -_ @. @_ @- .@ _@ -@ @@)
            if !(Regexp.union(*wrong) === string) #don't include any or the wrong strings
              if string.index('@').to_i > 0 and
                  string[0..(string.index('@') - 1)].scan(/([a-z0-9]+([\+\._\-][a-z0-9]|)*)/i).join == string[0..(string.index('@') - 1)] and
                  string[(string.index('@') + 1)..-1].scan(/([0-9a-z]+([\.-][a-z0-9]|)*)/i).join == string[string[(string.index('@') + 1)..-1]]
                error_regular_expression = false
              else
                error_regular_expression = true
              end
            else
              error_regular_expression = true
            end

            if expected_errors.size == 0
              if error_regular_expression
                good_result = false
              else
                good_result = true
              end
            elsif expected_errors_left.size == 0 and
                (expected_errors - [:length, :min_length, :max_length]).size == 0
              good_result = true
            elsif expected_errors != [:length]
              if !error_regular_expression
                good_result = false
              elsif expected_errors.include?(:value)
                good_result = true
              end
            end
          end

        end until good_result or tries > 100
        unless good_result
          puts "Not possible to generate an email on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
          return ''
        end
      end
      if @dont_repeat
        if @cache_values[pattern.to_s].nil?
          @cache_values[pattern.to_s] = Array.new()
          @cache_values[pattern.to_s].push(string)
          good_result = true
        elsif @cache_values[pattern.to_s].include?(string)
          good_result = false
        else
          @cache_values[pattern.to_s].push(string)
          good_result = true
        end
      end
      if pattern.kind_of?(Symbol) and symbol_type[-1] == "&"
        if @cache_values[pattern.__id__].nil?
          @cache_values[pattern.__id__] = Array.new()
          @cache_values[pattern.__id__].push(string)
          good_result = true
        elsif @cache_values[pattern.__id__].include?(string)
          good_result = false
        else
          @cache_values[pattern.__id__].push(string)
          good_result = true
        end
      end
    end until good_result or tries > 10000
    unless good_result
      puts "Not possible to generate the string on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
      puts "Take in consideration if you are using StringPattern.dont_repeat=true that you don't try to generate more strings that are possible to be generated"
      return ''
    end

    return string
  end


  ##############################################
  # This method is defined to validate if the text_to_validate supplied follows the pattern
  # It works also with array of patterns but in that case will return only true or false
  #  input:
  #     text (String) (synonyms: text_to_validate, validate) --  The text to validate
  #     pattern -- symbol with this info: "length:symbol_type" or "min_length-max_length:symbol_type"
  #       min_length -- minimum length of the string
  #       max_length (optional) -- maximum length of the string. If not provided the result will be with the min_length provided
  #       symbol_type -- the type of the string we want.
  #     expected_errors (Array of symbols) (optional) (synonyms: errors) --  :length, :min_length, :max_length, :value, :required_data, :excluded_data, :string_set_not_allowed
  #     not_expected_errors (Array of symbols) (optional) (synonyms: not_errors, non_expected_errors) --  :length, :min_length, :max_length, :value, :required_data, :excluded_data, :string_set_not_allowed
  #  example:
  #     validate(text: "This text will be validated", pattern: :"10-20:Xn", expected_errors: [:value, :max_length])
  #
  #   Output:
  #     if expected_errors and not_expected_errors are not supplied: an array with all detected errors
  #     if expected_errors or not_expected_errors supplied: true or false
  #     if array of patterns supplied, it will return true or false
  ###############################################
  def StringPattern.validate(text: '', pattern: '', expected_errors: [], not_expected_errors: [], **synonyms)
    text_to_validate = text
    text_to_validate = synonyms[:text_to_validate] if synonyms.keys.include?(:text_to_validate)
    text_to_validate = synonyms[:validate] if synonyms.keys.include?(:validate)
    expected_errors = synonyms[:errors] if synonyms.keys.include?(:errors)
    not_expected_errors = synonyms[:not_errors] if synonyms.keys.include?(:not_errors)
    not_expected_errors = synonyms[:non_expected_errors] if synonyms.keys.include?(:non_expected_errors)
    #:length, :min_length, :max_length, :value, :required_data, :excluded_data, :string_set_not_allowed
    if (expected_errors.include?(:min_length) or expected_errors.include?(:max_length)) and !expected_errors.include?(:length)
      expected_errors.push(:length)
    end
    if (not_expected_errors.include?(:min_length) or not_expected_errors.include?(:max_length)) and !not_expected_errors.include?(:length)
      not_expected_errors.push(:length)
    end
    if pattern.kind_of?(Array) and pattern.size == 1
      pattern = pattern[0]
    elsif pattern.kind_of?(Array) and pattern.size > 1 then
      total_min_length = 0
      total_max_length = 0
      all_errors_collected = Array.new
      result = true
      num_patt = 0
      patterns = Array.new
      pattern.each {|pat|
        if (pat.kind_of?(String) and (!StringPattern.optimistic or
            (StringPattern.optimistic and pat.to_s.scan(/(\d+)-(\d+):(.+)/).size == 0 and pat.to_s.scan(/^!?(\d+):(.+)/).size == 0))) #fixed text
          symbol_type = ''
          min_length = max_length = pat.length
        elsif pat.kind_of?(Symbol) or (pat.kind_of?(String) and StringPattern.optimistic and
            (pat.to_s.scan(/(\d+)-(\d+):(.+)/).size > 0 or pat.to_s.scan(/^!?(\d+):(.+)/).size > 0))
          patt = StringPattern.analyze(pat)
          min_length = patt.min_length
          max_length = patt.max_length
          symbol_type = patt.symbol_type
        else
          puts "String pattern class not supported (#{pat.class} for #{pat})"
        end

        patterns.push({pattern: pat, min_length: min_length, max_length: max_length, symbol_type: symbol_type})

        total_min_length += min_length
        total_max_length += max_length

        if num_patt == (pattern.size - 1) # i am in the last one
          if text_to_validate.length < total_min_length
            all_errors_collected.push(:length)
            all_errors_collected.push(:min_length)
          end

          if text_to_validate.length > total_max_length
            all_errors_collected.push(:length)
            all_errors_collected.push(:max_length)
          end

        end
        num_patt += 1


      }

      num_patt = 0
      patterns.each {|patt|

        tmp_result = false
        (patt[:min_length]..patt[:max_length]).each {|n|
          res = StringPattern.validate(text: text_to_validate[0..n - 1], pattern: patt[:pattern], not_expected_errors: not_expected_errors)
          if res.kind_of?(Array)
            all_errors_collected += res
          end

          if res.kind_of?(TrueClass) or (res.kind_of?(Array) and res.size == 0) #valid
            #we pass in the next one the rest of the pattern array list: pattern: pattern[num_patt+1..pattern.size]
            res = StringPattern.validate(text: text_to_validate[n..text_to_validate.length], pattern: pattern[num_patt + 1..pattern.size], expected_errors: expected_errors, not_expected_errors: not_expected_errors)

            if res.kind_of?(Array)
              if ((all_errors_collected + res) - expected_errors).size > 0
                tmp_result = false
              else
                all_errors_collected += res
                tmp_result = true
              end
            elsif res.kind_of?(TrueClass) then
              tmp_result = true
            end
            return true if tmp_result
          end
        }

        unless tmp_result
          return false
        end
        num_patt += 1
      }
      return result
    end

    if (pattern.kind_of?(String) and (!StringPattern.optimistic or
        (StringPattern.optimistic and pattern.to_s.scan(/(\d+)-(\d+):(.+)/).size == 0 and pattern.to_s.scan(/^!?(\d+):(.+)/).size == 0))) #fixed text
      symbol_type = ''
      min_length = max_length = pattern.length
    else #symbol
      patt = StringPattern.analyze(pattern)
      min_length = patt.min_length
      max_length = patt.max_length
      symbol_type = patt.symbol_type

      required_data = patt.required_data
      excluded_data = patt.excluded_data
      string_set = patt.string_set
      all_characters_set = patt.all_characters_set

      required_chars = Array.new
      required_data.each {|rd|
        required_chars << rd if rd.size == 1
      }
      if (required_chars.flatten & excluded_data.flatten).size > 0
        puts "pattern argument not valid on StringPattern.validate, a character cannot be required and excluded at the same time: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
        return ''
      end

    end

    if text_to_validate.nil?
      return false
    end
    detected_errors = Array.new

    if text_to_validate.length < min_length
      detected_errors.push(:min_length)
      detected_errors.push(:length)
    end
    if text_to_validate.length > max_length
      detected_errors.push(:max_length)
      detected_errors.push(:length)
    end

    if symbol_type == '' #fixed text
      if pattern.to_s != text.to_s #not equal
        detected_errors.push(:value)
        detected_errors.push(:required_data)
      end
    else # pattern supplied
      if symbol_type != '@'
        if required_data.size > 0
          required_data.each {|rd|
            if (text_to_validate.chars & rd).size == 0
              detected_errors.push(:value)
              detected_errors.push(:required_data)
              break
            end
          }
        end
        if excluded_data.size > 0
          if (excluded_data & text_to_validate.chars).size > 0
            detected_errors.push(:value)
            detected_errors.push(:excluded_data)
          end
        end
        string_set_not_allowed = all_characters_set - string_set
        text_to_validate.chars.each {|st|
          if string_set_not_allowed.include?(st)
            detected_errors.push(:value)
            detected_errors.push(:string_set_not_allowed)
            break
          end
        }
      else #symbol_type=="@"
        string = text_to_validate
        wrong = %w(.. __ -- ._ _. .- -. _- -_ @. @_ @- .@ _@ -@ @@)
        if !(Regexp.union(*wrong) === string) #don't include any or the wrong strings
          if string.index('@').to_i > 0 and
              string[0..(string.index('@') - 1)].scan(/([a-z0-9]+([\+\._\-][a-z0-9]|)*)/i).join == string[0..(string.index('@') - 1)] and
              string[(string.index('@') + 1)..-1].scan(/([0-9a-z]+([\.-][a-z0-9]|)*)/i).join == string[string[(string.index('@') + 1)..-1]]
            error_regular_expression = false
          else
            error_regular_expression = true
          end
        else
          error_regular_expression = true
        end

        if error_regular_expression
          detected_errors.push(:value)
        end

      end
    end

    if expected_errors.size == 0 and not_expected_errors.size == 0
      return detected_errors
    else
      if expected_errors & detected_errors == expected_errors
        if (not_expected_errors & detected_errors).size > 0
          return false
        else
          return true
        end
      else
        return false
      end
    end
  end

end

