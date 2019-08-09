require "string_pattern"

RSpec.describe StringPattern, "#generate" do
  describe "pattern" do
    describe "general" do
      it "pattern with wrong type" do
        expect(StringPattern.generate(5)).to eq "5"
        expect { StringPattern.generate(5) }.to output(/pattern argument not valid on StringPattern.generate/).to_stdout
      end
    end
    describe "length" do
      it "generates with fix length" do
        expect("10:L".gen.size).to eq 10
      end
      it "generates with fix length min and max" do
        expect("10-10:L".gen.size).to eq 10
      end
      it "generates with length between min and max" do
        expect("1-10:L".gen.size).to be_between(1, 10)
      end
      it "display error if non existing min_length" do
        #expect(':N'.gen).to eq ''
        expect { ':N'.gen}.to output(/pattern argument not valid on StringPattern.generate/).to_stdout
      end
    end

    describe "lower" do
      it "generates correct pattern" do
        expect("10:x".gen).to match(/^[a-z]{10}$/)
      end
    end

    describe "capital" do
      it "generates correct pattern" do
        expect("10:X".gen).to match(/^[A-Z]{10}$/)
      end
    end

    describe "letters" do
      it "generates correct pattern" do
        expect("10:L".gen).to match(/^[A-Za-z]{10}$/)
      end
    end

    describe "national_chars" do
      before(:all) do
        @national_chars = StringPattern.national_chars
      end

      after(:each) do
        StringPattern.national_chars = @national_chars
      end

      it "generates correct pattern when default national_chars" do
        expect("10:T".gen).to match(/^[a-zA-Z]{10}$/)
      end
      it "generates correct pattern when modified national_chars" do
        StringPattern.national_chars = "a"
        expect("10:T".gen).to match(/^[a]{10}$/)
      end
    end

    describe "number" do
      it "generates correct pattern" do
        expect("10:N".gen).to match(/^[0-9]{10}$/)
        expect("10:n".gen).to match(/^[0-9]{10}$/)
      end
    end

    describe "special characters" do
      it "generates correct pattern" do
        special_set = class StringPattern; SPECIAL_SET.join("\\"); end
        expect("10:$".gen).to match(/^[#{special_set}]{10}$/)
      end
    end

    describe "blank space" do
      it "generates correct pattern" do
        expect("10:_".gen).to match(/^[\s]{10}$/)
      end
    end

    describe "all characters" do
      it "generates correct pattern" do
        special_set = class StringPattern; SPECIAL_SET.join("\\"); end
        expect("10:*".gen).to match(/^[a-zA-Z0-9#{special_set}]{10}$/)
      end
    end

    describe "specific characters" do
      it "generates correct pattern" do
        expect("10:[b]".gen).to match(/^[b]{10}$/)
      end
      it "generates correct pattern when adding ]" do
        expect("10:[]]".gen).to match(/^[\]]{10}$/)
      end
      it "generates correct pattern when adding %" do
        expect("10:[%%]".gen).to match(/^[%]{10}$/)
      end
      it 'generates correct pattern when adding "' do
        expect("10:[\"]".gen).to match(/^[\"]{10}$/)
      end
      it 'generates correct pattern when adding \\' do
        expect("10:[\\]".gen).to match(/^[\\]{10}$/)
      end
      it "generates correct pattern when adding [" do
        expect("10:[\[]".gen).to match(/^[\[]{10}$/)
      end
    end

    describe "exclude characters" do
      it "generates correct pattern when specific and excluded" do
        expect("10:[ab%b%]".gen).to match(/^[a]{10}$/)
      end
      it "generates correct pattern when symbol and excluded" do
        expect("10:n[%012345678%]".gen).to match(/^[9]{10}$/)
      end
      it "generates correct pattern when adding %" do
        expect("10:[ab%b%%%]".gen).to match(/^[a]{10}$/)
      end
    end

    describe "required characters or symbols" do
      it "generates correct pattern when mandatory characters" do
        expect("10:n[/0/]".gen).to include("0")
      end
      it "generates correct pattern when mandatory character / added" do
        expect("10:n[/0///]".gen).to include("/")
      end
      it "generates correct pattern when mandatory symbol" do
        expect("10:L/N/".gen).to match(/[0-9]+/)
      end
      it "cannot require and exclude the same character" do
        expect("5:[b/a/%a%]".gen).to eq ""
        expect { "5:[b/a/%a%]".gen }.to output(/a character cannot be required and excluded/).to_stdout
      end
    end

    describe "allow empty string" do
      before(:all) do
        StringPattern.cache_values = {}
      end
      it "returns empty string" do
        values = []
        #it needs to be a symbol :"xxxxx"
        11.times do values << :"1:0N&".gen end
        expect(values).to include("")
      end
    end

    describe "unique strings" do
      before(:each) do
        StringPattern.cache_values = {}
      end
      after(:each) do
        StringPattern.dont_repeat = false
      end
      it "returns unique strings" do
        values = []
        #it needs to be a symbol :"xxxxx"
        10.times do values << :"1:N&".gen end
        values.uniq!
        expect(values.size).to eq(10)
      end
      it "returns empty string if not possible to generate" do
        values = []
        #it needs to be a symbol :"xxxxx"
        11.times do values << :"1:N&".gen end
        expect(values[-1]).to eq("")
      end
      it "is possible to use StringPattern.dont_repeat = true" do
        StringPattern.dont_repeat = true
        values = []
        10.times do values << "1:N".gen end
        values.uniq!
        expect(values.size).to eq(10)
      end
      it "is possible to use StringPattern.dont_repeat = false" do
        StringPattern.dont_repeat = false
        values = []
        15.times do values << "1:N".gen end
        values.delete("")
        expect(values.size).to eq(15)
      end
      it "display error when no more combinations allowed" do
        StringPattern.dont_repeat = true
        10.times do '1:N'.gen end
        expect('1:N'.gen).to eq ''
        expect { '1:N'.gen}.to output(/Take in consideration if you are using StringPattern.dont_repeat=true/).to_stdout
      end
    end

    describe "email" do
      it "generates correct email" do
        expect("30:@".gen).to match(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        expect("30:@".gen.size).to eq(30)
      end
      it "display error when not possible to generate email" do
        expect('3:@'.gen).to eq ''
        expect { '3:@'.gen}.to output(/Not possible to generate an email on StringPattern.generate/).to_stdout
      end
    end

    describe "expected errors" do
      it "returns string with wrong length" do
        expect("30:L".gen(errors: :length).size).not_to be(30)
      end
      it "returns string with wrong min_length" do
        expect("30:L".gen(errors: :min_length).size).to be < 30
      end
      it "returns string with wrong max_length" do
        expect("30:L".gen(errors: :max_length).size).to be > 30
      end
      it "returns string with wrong value" do
        expect("30:L".gen(errors: :value)).not_to match(/^[a-zA-Z]+$/)
      end
      it "returns string with wrong required_data" do
        expect("30:L/n/".gen(errors: :required_data)).not_to match(/[0-9]/)
      end
      it "returns correct string with excluded_data" do
        expect("30:n[%5%]".gen(errors: :excluded_data)).to include("5")
      end
      it "returns correct string with string_set_not_allowed" do
        expect("30:n".gen(errors: :string_set_not_allowed)).not_to match(/^[0-9]+$/)
      end
      it "returns string not following the pattern" do
        expect("!30:n".gen).not_to match(/^[0-9]{30}$/)
      end
      it "accepts alias expected errors" do
        expect("30:L".gen(expected_errors: :length).size).not_to be(30)
      end
      it "accepts alias errors" do
        expect("30:L".gen(errors: :length).size).not_to be(30)
      end
      it "accepts array of expected errors" do
        expect("30:L".gen(expected_errors: [:length, :value]).size).not_to be(30)
        expect("30:L".gen(expected_errors: [:length, :value])).not_to match(/^[a-zA-Z]+$/)
      end
      it "display error when expected error is :required_data but not :required_data on pattern" do
        expect('10:N'.gen(errors: :required_data)).to eq ''
        expect { '10:N'.gen(errors: :required_data) }.to output(/required data not supplied on pattern so it won't be possible to generate a wrong string/).to_stdout
      end
      it "display error when expected error is :excluded_data but not :excluded_data on pattern" do
        expect('10:N'.gen(errors: :excluded_data)).to eq ''
        expect { '10:N'.gen(errors: :excluded_data) }.to output(/excluded data not supplied on pattern so it won't be possible to generate a wrong string/).to_stdout
      end
      it "display error when expected error is :string_set_not_allowed but not :string_set_not_allowed on pattern" do
        expect('10:*'.gen(errors: :string_set_not_allowed)).to eq ''
        expect { '10:*'.gen(errors: :string_set_not_allowed) }.to output(/all characters are allowed so it won't be possible to generate a wrong string/).to_stdout
      end
      it "display error when expected error is :value but all chars accepted on pattern" do
        expect('10:*'.gen(errors: :value)).to eq ''
        expect { '10:*'.gen(errors: :value) }.to output(/Not possible to generate a non valid string on StringPattern.generate/).to_stdout
      end
      it "display error when expected error is :min_length but the min_length of the pattern is 0" do
        expect('0-2:N'.gen(errors: :min_length)).to eq ''
        expect { '0-2:N:*'.gen(errors: :min_length) }.to output(/min_length is 0 so it won't be possible to generate a wrong string smaller than 0 characters/).to_stdout
      end
      
    end

    describe "array of patterns" do
      after(:all) do
        StringPattern.optimistic = true
      end
      it "returns correct string" do
        pattern = ["uno:", :"5:N", "dos"]
        expect(pattern.gen).to match(/^uno:[0-9]{5}dos$/)
      end
      it "returns correct string with selection values" do
        pattern = ["uno:", :"5:N", ["dos", "tres", :'3:X']]
        expect(pattern.gen).to match(/^uno:[0-9]{5}(dos|tres|[A-Z]{3})$/)
      end
      it "accepts optimistic false" do
        StringPattern.optimistic = false
        expect(["5:X", "fixedtext", "3:N"].generate).to eq "5:Xfixedtext3:N"
      end
      it "returns random string when optimistic false and symbols supplied" do
        StringPattern.optimistic = false
        expect([:"5:X", "fixedtext", :"3:N"].generate).to match(/[A-Z]{5}fixedtext[0-9]{3}/)
      end
      it "accepts optimistic true" do
        StringPattern.optimistic = true
        expect(["5:X", "fixedtext", "3:N"].generate).to match(/[A-Z]{5}fixedtext[0-9]{3}/)
      end
      it "detects wrong array of patterns" do
        expect([:"5:X", 33].gen).to eq ""
        expect { [:"5:X", 33].gen }.to output(/StringPattern.generate: it seems you supplied wrong array of patterns/).to_stdout
      end
    end
  end

  describe "words" do
    after(:each) do
      StringPattern.word_separator = "_"
    end
    describe "english" do
      it "generates capital and lower" do
        expect("30:W".gen.size).to eq(30)
        expect("30:W".gen).to match(/^([A-Z]+[a-z]*)+$/)
      end
      it "words only lower and words separated by underscore" do
        expect("30:w".gen.size).to eq(30)
        expect("30:w".gen).to match(/^[a-z_]+$/)
      end
      it "words only lower and words separated by character specified" do
        StringPattern.word_separator = "-"
        expect("30:w".gen.size).to eq(30)
        expect("30:w".gen).to match(/^[a-z\-]+$/)
      end
    end
    describe "spanish" do
      it "generates capital and lower" do
        expect("30:P".gen.size).to eq(30)
        expect("30:P".gen).to match(/^([A-ZÁÉÍÓÚÜÑ]+[a-záéíóúüñ]*)+$/)
      end
      it "words only lower and words separated by underscore" do
        expect("30:p".gen.size).to eq(30)
        expect("30:p".gen).to match(/^[a-z_áéíóúüñ]+$/)
      end
      it "words only lower and words separated by character specified" do
        StringPattern.word_separator = "-"
        expect("30:p".gen.size).to eq(30)
        expect("30:p".gen).to match(/^[a-záéíóúüñ\-]+$/)
      end
    end
  end
  describe "regexp" do
    it "generates correct pattern for simple regexp" do
      expect(/b{10}/.gen).to match(/^[b]{10}$/)
    end
    it "generates correct pattern for more complex regexp" do
      regexp = /^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$/
      expect(regexp.gen).to match(regexp)
    end
    it 'accepts [abc]' do
      regexp = /[abc]/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    #todo: this is failing, it is generating a string of a b or c
    xit 'accepts [^abc]' do
      regexp = /[^abc]/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts start and end of line' do
      regexp = /^[a-z]+$/
      puts regexp.gen
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts .' do
      regexp = /.+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \s' do
      regexp = /\s+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \S' do
      regexp = /\S+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \d' do
      regexp = /\d+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \D' do
      regexp = /\D+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \w' do
      regexp = /\w+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts \W' do
      regexp = /\W+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    #todo: failing
    xit 'accepts \b' do
      regexp = /\b+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts (...)' do
      regexp = /(\w)+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts (a|b)' do
      regexp = /(a|b)+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts a?' do
      regexp = /a?b+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts a*' do
      regexp = /a*b+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts a+' do
      regexp = /a+/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts a{3}' do
      regexp = /a{3}/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    #todo: 3 or more is returning now always 3
    xit 'accepts a{3,}' do
      regexp = /a{3}/
      expect(regexp.gen.match?(regexp)).to eq true
    end
    it 'accepts a{3,6}' do
      regexp = /a{3,6}/
      expect(regexp.gen.match?(regexp)).to eq true
    end


  end
end
