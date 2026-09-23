class StringPattern
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
  #                     T for the national characters defined on StringPattern.national_chars
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
  #                   Other uses:
  #                     @ for email
  #                     W for English words, capital and lower
  #                     w for English words only lower and words separated by underscore
  #                     P for Spanish words, capital and lower
  #                     p for Spanish words only lower and words separated by underscore
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
    rng = synonyms.delete(:_rng)
    if rng.nil?
      base = synonyms.key?(:seed) ? Random.new(synonyms[:seed]) : Random.new
      rng = StringPattern::RandomSource.new(base)
    end
    tries = 0
    begin
      good_result = true
      tries += 1
      string = ""

      expected_errors = synonyms[:errors] if synonyms.keys.include?(:errors)

      if expected_errors.kind_of?(Symbol)
        expected_errors = [expected_errors]
      end

      if pattern.kind_of?(Array)
        pattern.each { |pat|
          if pat.kind_of?(Array) # for the case it is one of the values
            pat = pat.sample(random: rng)
          end

          if pat.kind_of?(Symbol)
            if pat.to_s.scan(/^!?\d+-?\d*:.+/).size > 0
              string << StringPattern.generate(pat.to_s, expected_errors: expected_errors, _rng: rng)
            else
              string << pat.to_s
            end
          elsif pat.kind_of?(String)
            if @optimistic and pat.to_s.scan(/^!?\d+-?\d*:.+/).size > 0
              string << StringPattern.generate(pat.to_s, expected_errors: expected_errors, _rng: rng)
            else
              string << pat
            end
          else
            return StringPattern.fail_generation("StringPattern.generate: it seems you supplied wrong array of patterns: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::InvalidPatternError)
          end
        }
        return string
      elsif pattern.kind_of?(String) or pattern.kind_of?(Symbol)
        patt = StringPattern.analyze(pattern).clone
        unless patt.kind_of?(Struct)
          raise StringPattern::InvalidPatternError, "pattern argument not valid on StringPattern.generate: #{pattern.inspect}" if @raise_on_error
          return ""
        end

        min_length = patt.min_length.clone
        max_length = patt.max_length.clone
        symbol_type = patt.symbol_type.clone

        required_data = patt.required_data.clone
        excluded_data = patt.excluded_data.clone
        string_set = patt.string_set.clone
        all_characters_set = patt.all_characters_set.clone

        required_chars = Array.new
        unless required_data.size == 0
          required_data.each { |rd|
            required_chars << rd if rd.size == 1
          }
          unless excluded_data.size == 0
            if (required_chars.flatten & excluded_data.flatten).size > 0
              return StringPattern.fail_generation("pattern argument not valid on StringPattern.generate, a character cannot be required and excluded at the same time: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::InvalidPatternError)
            end
          end
        end

        string_set_not_allowed = Array.new
      elsif pattern.kind_of?(Regexp)
        return generate(pattern.to_sp, expected_errors: expected_errors, _rng: rng)
      else
        message = "pattern argument not valid on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
        raise StringPattern::InvalidPatternError, message if @raise_on_error
        StringPattern.log_message(message)
        return pattern.to_s
      end

      allow_empty = false
      deny_pattern = false
      if symbol_type[0..0] == "!"
        deny_pattern = true
        possible_errors = [:length, :value, :string_set_not_allowed]
        (rng.rand(possible_errors.size) + 1).times {
          expected_errors << possible_errors.sample(random: rng)
        }
        expected_errors.uniq!
        if symbol_type[1..1] == "0"
          allow_empty = true
        end
      elsif symbol_type[0..0] == "0"
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
          return StringPattern.fail_generation("required data not supplied on pattern so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
        end

        if excluded_data.size == 0 and expected_errors_left.include?(:excluded_data)
          return StringPattern.fail_generation("excluded data not supplied on pattern so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
        end

        if expected_errors_left.include?(:string_set_not_allowed)
          string_set_not_allowed = all_characters_set - string_set

          if string_set_not_allowed.size == 0
            return StringPattern.fail_generation("all characters are allowed so it won't be possible to generate a wrong string. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
          end
        end
      end

      if expected_errors_left.include?(:min_length) or
         expected_errors_left.include?(:max_length) or
         expected_errors_left.include?(:length)
        if expected_errors_left.include?(:min_length) or
           (min_length > 0 and expected_errors_left.include?(:length) and rng.rand(2) == 0)
          if min_length > 0
            if allow_empty
              length = rng.rand(min_length).to_i
            else
              length = rng.rand(min_length - 1).to_i + 1
            end
            if required_data.size > length and required_data.size < min_length
              length = required_data.size
            end
            expected_errors_left.delete(:length)
            expected_errors_left.delete(:min_length)
          else
            return StringPattern.fail_generation("min_length is 0 so it won't be possible to generate a wrong string smaller than 0 characters. StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
          end
        elsif expected_errors_left.include?(:max_length) or expected_errors_left.include?(:length)
          length = max_length + 1 + rng.rand(max_length).to_i
          expected_errors_left.delete(:length)
          expected_errors_left.delete(:max_length)
        end
      else
        if allow_empty and rng.rand(7) == 1
          length = 0
        else
          if max_length == min_length
            length = min_length
          else
            length = min_length + rng.rand(max_length - min_length + 1)
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

        if symbol_type == "!@" and expected_errors_left.size == 0 and !expected_errors.include?(:length) and
           (expected_errors.include?(:required_data) or expected_errors.include?(:excluded_data))
          expected_errors_left.push(:value)
        end
      end

      string = ""
      if symbol_type != "@" and symbol_type != "!@" and length != 0 and string_set.size != 0
        if string_set.size != 0
          1.upto(length) { |i|
            string << string_set.sample(random: rng).to_s
          }
        end
        if required_data.size > 0
          positions_to_set = (0..(string.size - 1)).to_a
          required_data.each { |rd|
            if (string.chars & rd).size > 0
              rd_to_set = (string.chars & rd).sample(random: rng)
            else
              rd_to_set = rd.sample(random: rng)
            end
            if ((0...string.length).find_all { |i| string[i, 1] == rd_to_set }).size == 0
              if positions_to_set.size == 0
                return StringPattern.fail_generation("pattern not valid on StringPattern.generate, not possible to generate a valid string: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
              else
                k = positions_to_set.sample(random: rng)
                string[k] = rd_to_set
                positions_to_set.delete(k)
              end
            else
              k = ((0...string.length).find_all { |i| string[i, 1] == rd_to_set }).sample(random: rng)
              positions_to_set.delete(k)
            end
          }
        end
        excluded_data.each { |ed|
          if (string.chars & ed).size > 0
            (string.chars & ed).each { |s|
              string.gsub!(s, string_set.sample(random: rng))
            }
          end
        }

        if expected_errors_left.include?(:value)
          string_set_not_allowed = all_characters_set - string_set if string_set_not_allowed.size == 0

          if string_set_not_allowed.size == 0
            return StringPattern.fail_generation("Not possible to generate a non valid string on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
          end
          (rng.rand(string.size) + 1).times {
            string[rng.rand(string.size)] = (all_characters_set - string_set).sample(random: rng)
          }
          expected_errors_left.delete(:value)
        end

        if expected_errors_left.include?(:required_data) and required_data.size > 0
          (rng.rand(required_data.size) + 1).times {
            chars_to_remove = required_data.sample(random: rng)
            chars_to_remove.each { |char_to_remove|
              string.gsub!(char_to_remove, (string_set - chars_to_remove).sample(random: rng))
            }
          }
          expected_errors_left.delete(:required_data)
        end

        if expected_errors_left.include?(:excluded_data) and excluded_data.size > 0
          (rng.rand(string.size) + 1).times {
            string[rng.rand(string.size)] = excluded_data.sample(random: rng).sample(random: rng)
          }
          expected_errors_left.delete(:excluded_data)
        end

        if expected_errors_left.include?(:string_set_not_allowed)
          string_set_not_allowed = all_characters_set - string_set if string_set_not_allowed.size == 0
          if string_set_not_allowed.size > 0
            (rng.rand(string.size) + 1).times {
              string[rng.rand(string.size)] = string_set_not_allowed.sample(random: rng)
            }
            expected_errors_left.delete(:string_set_not_allowed)
          end
        end
      elsif (symbol_type == "W" or symbol_type == "P" or symbol_type == "w" or symbol_type == "p") and length > 0
        if symbol_type == "W" || symbol_type == "w"
          load_english_words(camel: symbol_type == "W")
          words = symbol_type == "W" ? @words_camel : @words
        else
          load_spanish_words(camel: symbol_type == "P")
          words = symbol_type == "P" ? @palabras_camel : @palabras
        end
        words_short = words.sample(2000, random: rng)

        wordr = ""
        wordr_array = []
        tries = 0
        while wordr.length < min_length
          tries += 1
          length = max_length - wordr.length
          if tries > 1000
            wordr += "A" * length
            break
          end
          if symbol_type == "w" or symbol_type == "p"
            length = length - 1 if wordr_array.size > 0
            res = (words_short.select { |word| word.length <= length && word.length != length - 1 && word.length != length - 2 && word.length != length - 3 }).sample(random: rng).to_s
            unless res.to_s == ""
              wordr_array << res
              wordr = wordr_array.join(@word_separator)
            end
          else
            wordr += (words_short.select { |word| word.length <= length && word.length != length - 1 && word.length != length - 2 && word.length != length - 3 }).sample(random: rng).to_s
          end
          if (tries % 100) == 0
            words_short = words.sample(2000, random: rng)
          end
        end
        good_result = true
        string = wordr
      elsif (symbol_type == "@" or symbol_type == "!@") and length > 0
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
          string = ""
          alpha_set = ALPHA_SET_LOWER.clone + ALPHA_SET_CAPITAL.clone
          string_set = alpha_set + NUMBER_SET.clone + ["."] + ["_"] + ["-"]
          string_set_not_allowed = all_characters_set - string_set

          extension = "."
          at_sign = "@"

          if expected_errors_left.include?(:value)
            if rng.rand(2) == 1
              extension = (all_characters_set - ["."]).sample(random: rng).dup
              expected_errors_left.delete(:value)
              expected_errors_left.delete(:required_data)
            end

            if rng.rand(2) == 1
              1.upto(rng.rand(7)) { |i|
                extension << alpha_set.sample(random: rng).downcase
              }

              (rng.rand(extension.size) + 1).times {
                extension[rng.rand(extension.size)] = (string_set - alpha_set - ["."]).sample(random: rng)
              }

              expected_errors_left.delete(:value)
            else
              1.upto(rng.rand(3) + 2) { |i|
                extension << alpha_set.sample(random: rng).downcase
              }
            end

            if rng.rand(2) == 1
              at_sign = (string_set - ["@"]).sample(random: rng).dup
              expected_errors_left.delete(:value)
              expected_errors_left.delete(:required_data)
            end
          else
            if length > 6
              1.upto(rng.rand(3) + 2) { |i|
                extension << alpha_set.sample(random: rng).downcase
              }
            else
              1.upto(2) { |i|
                extension << alpha_set.sample(random: rng).downcase
              }
            end
          end
          length_e = length - extension.size - 1
          length1 = rng.rand(length_e - 1) + 1
          length2 = length_e - length1
          1.upto(length1) { |i| string << string_set.sample(random: rng) }

          string << at_sign

          domain = ""
          domain_set = alpha_set + NUMBER_SET.clone + ["."] + ["-"]
          1.upto(length2) { |i|
            domain << domain_set.sample(random: rng).downcase
          }

          if expected_errors.include?(:value) and rng.rand(2) == 1 and domain.size > 0
            (rng.rand(domain.size) + 1).times {
              domain[rng.rand(domain.size)] = (all_characters_set - domain_set).sample(random: rng)
            }
            expected_errors_left.delete(:value)
          end

          string << domain << extension

          if expected_errors_left.include?(:value) or expected_errors_left.include?(:string_set_not_allowed)
            (rng.rand(string.size) + 1).times {
              string[rng.rand(string.size)] = string_set_not_allowed.sample(random: rng)
            }
            expected_errors_left.delete(:value)
            expected_errors_left.delete(:string_set_not_allowed)
          end

          error_regular_expression = !StringPattern.valid_email?(string)

          if deny_pattern and expected_errors.include?(:length)
            good_result = true #it is already with wrong length
          else

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
          return StringPattern.fail_generation("Not possible to generate an email on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}", StringPattern::GenerationImpossibleError)
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
      if pattern.kind_of?(Symbol) and patt.unique
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
      if @block_list_enabled
        if @block_list.respond_to?(:call)
          good_result = false if @block_list.call(string)
        elsif @block_list.is_a?(Array)
          if @block_list_regexp
            @block_list.each do |bl|
              if string.match?(/#{bl}/i)
                good_result = false
                break
              end
            end
          else
            downcased = string.downcase
            @block_list.each do |bl|
              if downcased.include?(bl.to_s.downcase)
                good_result = false
                break
              end
            end
          end
        end
      end
    end until good_result or tries > 10000
    unless good_result
      msg = "Not possible to generate the string on StringPattern.generate: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
      msg += "\nTake in consideration if you are using StringPattern.dont_repeat=true that you don't try to generate more strings that are possible to be generated"
      return StringPattern.fail_generation(msg, StringPattern::GenerationImpossibleError)
    end
    return string
  end

  def self.fail_generation(message, error_class)
    raise error_class, message if @raise_on_error
    log_message(message)
    ""
  end

  def self.word_data_path(*parts)
    File.join(__dir__, "..", "..", "..", "data", *parts)
  end

  def self.load_english_words(camel: false)
    require "json"
    if @words.nil? || @words.empty?
      nouns = JSON.parse(File.read(word_data_path("english", "nouns.json")))
      adjs = JSON.parse(File.read(word_data_path("english", "adjs.json")))
      @words = adjs + nouns
    end
    if camel && (@words_camel.nil? || @words_camel.empty?)
      @words_camel = @words.map(&:to_camel_case)
    end
  end

  def self.load_spanish_words(camel: false)
    require "json"
    if @palabras.nil? || @palabras.empty?
      @palabras = (0..11).flat_map do |i|
        JSON.parse(File.read(word_data_path("spanish", "palabras#{i}.json")))
      end
    end
    if camel && (@palabras_camel.nil? || @palabras_camel.empty?)
      @palabras_camel = @palabras.map(&:to_camel_case)
    end
  end
end
