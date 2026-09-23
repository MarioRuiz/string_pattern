class StringPattern
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
  def StringPattern.validate(text: "", pattern: "", expected_errors: [], not_expected_errors: [], **synonyms)
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
    if pattern.is_a?(Regexp)
      return false if text_to_validate.nil?
      detected_errors = StringPattern.regexp_full_match?(pattern, text_to_validate.to_s) ? [] : [:value]
      return StringPattern.validation_decision(detected_errors, expected_errors, not_expected_errors)
    end
    if pattern.kind_of?(Array) and pattern.size == 1
      pattern = pattern[0]
    elsif pattern.kind_of?(Array) and pattern.size > 1
      total_min_length = 0
      total_max_length = 0
      all_errors_collected = Array.new
      result = true
      num_patt = 0
      patterns = Array.new
      pattern.each { |pat|
        if (pat.kind_of?(String) and (!StringPattern.optimistic or
                                      (StringPattern.optimistic and pat.to_s.scan(/(\d+)-(\d+):(.+)/).size == 0 and pat.to_s.scan(/^!?(\d+):(.+)/).size == 0))) #fixed text
          symbol_type = ""
          min_length = max_length = pat.length
        elsif pat.kind_of?(Symbol) or (pat.kind_of?(String) and StringPattern.optimistic and
                                       (pat.to_s.scan(/(\d+)-(\d+):(.+)/).size > 0 or pat.to_s.scan(/^!?(\d+):(.+)/).size > 0))
          #patt = Marshal.load(Marshal.dump(StringPattern.analyze(pat))) #deep copy
          patt = StringPattern.analyze(pat).clone
          min_length = patt.min_length.clone
          max_length = patt.max_length.clone
          symbol_type = patt.symbol_type.clone
        else
          StringPattern.log_message("String pattern class not supported (#{pat.class} for #{pat})")
          return false
        end

        patterns.push({ pattern: pat, min_length: min_length, max_length: max_length, symbol_type: symbol_type })

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
      patterns.each { |patt|
        tmp_result = false
        (patt[:min_length]..patt[:max_length]).each { |n|
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
            elsif res.kind_of?(TrueClass)
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
      symbol_type = ""
      min_length = max_length = pattern.length
    else #symbol
      #patt = Marshal.load(Marshal.dump(StringPattern.analyze(pattern))) #deep copy
      patt = StringPattern.analyze(pattern).clone
      min_length = patt.min_length.clone
      max_length = patt.max_length.clone
      symbol_type = patt.symbol_type.clone

      required_data = patt.required_data.clone
      excluded_data = patt.excluded_data.clone
      string_set = patt.string_set.clone
      all_characters_set = patt.all_characters_set.clone

      required_chars = Array.new
      required_data.each { |rd|
        required_chars << rd if rd.size == 1
      }
      if (required_chars.flatten & excluded_data.flatten).size > 0
        message = "pattern argument not valid on StringPattern.validate, a character cannot be required and excluded at the same time: #{pattern.inspect}, expected_errors: #{expected_errors.inspect}"
        raise StringPattern::InvalidPatternError, message if @raise_on_error
        StringPattern.log_message(message)
        return ""
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

    if symbol_type == "" #fixed text
      if pattern.to_s != text.to_s #not equal
        detected_errors.push(:value)
        detected_errors.push(:required_data)
      end
    else # pattern supplied
      if symbol_type != "@"
        if required_data.size > 0
          required_data.each { |rd|
            if (text_to_validate.chars & rd).size == 0
              detected_errors.push(:value)
              detected_errors.push(:required_data)
              break
            end
          }
        end
        if excluded_data.size > 0
          if (excluded_data.flatten & text_to_validate.chars).size > 0
            detected_errors.push(:value)
            detected_errors.push(:excluded_data)
          end
        end
        string_set_not_allowed = all_characters_set - string_set
        text_to_validate.chars.each { |st|
          if string_set_not_allowed.include?(st)
            detected_errors.push(:value)
            detected_errors.push(:string_set_not_allowed)
            break
          end
        }
      else #symbol_type=="@"
        error_regular_expression = !StringPattern.valid_email?(text_to_validate)
        if error_regular_expression
          detected_errors.push(:value)
        end
      end
    end

    StringPattern.validation_decision(detected_errors, expected_errors, not_expected_errors)
  end

  def self.validation_decision(detected_errors, expected_errors, not_expected_errors)
    if expected_errors.size == 0 && not_expected_errors.size == 0
      detected_errors.uniq
    elsif (expected_errors & detected_errors) == expected_errors && (not_expected_errors & detected_errors).empty?
      true
    else
      false
    end
  end

  # True when +text+ matches the whole +regexp+, not a substring.
  def self.regexp_full_match?(regexp, text)
    return false unless text.is_a?(String)
    anchored = Regexp.new("\\A(?:#{regexp.source})\\z", regexp.options)
    anchored.match?(text)
  rescue RegexpError
    false
  end

  # Describes why +text+ does or does not match +pattern+.
  # @return [Hash] :valid, :errors, :message, and :index (segment index for arrays)
  def self.explain(text: nil, pattern: nil, **synonyms)
    text = synonyms[:text_to_validate] if text.nil? && synonyms.key?(:text_to_validate)
    text = synonyms[:validate] if text.nil? && synonyms.key?(:validate)

    if pattern.is_a?(Array) && pattern.size > 1
      return explain_array(text, pattern)
    end

    errors = validate(text: text, pattern: pattern)
    if errors == true || (errors.is_a?(Array) && errors.empty?)
      { valid: true, errors: [], message: "valid", index: nil }
    elsif errors.is_a?(Array)
      { valid: false, errors: errors, message: "invalid: #{errors.join(', ')}", index: nil }
    else
      { valid: false, errors: [:value], message: "invalid", index: nil }
    end
  end

  def self.explain_array(text, patterns)
    ok, index, errors = match_segments(text.to_s, patterns, 0)
    if ok
      { valid: true, errors: [], message: "valid", index: nil }
    else
      { valid: false, errors: errors, message: "segment #{index} does not match: #{errors.join(', ')}", index: index }
    end
  end

  def self.match_segments(text, patterns, index)
    if patterns.empty?
      return [true, nil, []] if text.empty?
      return [false, index, [:length]]
    end

    if patterns.size == 1
      errors = validate(text: text, pattern: patterns[0])
      return [true, nil, []] if errors == true || (errors.is_a?(Array) && errors.empty?)
      errs = errors.is_a?(Array) ? errors : [:value]
      return [false, index, errs]
    end

    info = segment_bounds(patterns[0])
    return [false, index, [:value]] if info.nil?

    best = nil
    (info[:min]..info[:max]).each do |n|
      next if n > text.length
      errors = validate(text: text[0, n], pattern: patterns[0])
      next unless errors == true || (errors.is_a?(Array) && errors.empty?)
      ok, idx, errs = match_segments(text[n..], patterns[1..], index + 1)
      return [true, nil, []] if ok
      best = [idx, errs] if best.nil? || idx > best[0]
    end

    return [false, best[0], best[1]] if best

    errors = validate(text: text, pattern: patterns[0])
    errs = errors.is_a?(Array) ? errors : [:value]
    errs = [:value] if errs.empty?
    [false, index, errs]
  end

  def self.segment_bounds(pat)
    pattern_like = pat.to_s.scan(/(\d+)-(\d+):(.+)/).size > 0 || pat.to_s.scan(/^!?(\d+):(.+)/).size > 0
    if pat.is_a?(String) && (!optimistic || !pattern_like)
      { min: pat.length, max: pat.length }
    elsif pat.is_a?(Symbol) || pat.is_a?(String)
      analyzed = analyze(pat, silent: true)
      return nil unless analyzed.is_a?(Struct)
      { min: analyzed.min_length, max: analyzed.max_length }
    end
  end
end
