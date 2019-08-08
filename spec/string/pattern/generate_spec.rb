require "string_pattern"

RSpec.describe StringPattern, "#generate" do
  describe "pattern" do
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

    describe "mandatory characters or symbols" do
      it "generates correct pattern when mandatory characters" do
        expect("10:n[/0/]".gen).to include("0")
      end
      it "generates correct pattern when mandatory character / added" do
        expect("10:n[/0///]".gen).to include("/")
      end
      it "generates correct pattern when mandatory symbol" do
        expect("10:L/N/".gen).to match(/[0-9]+/)
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
    end

    describe "email" do
      it "generates correct email" do
        expect("30:@".gen).to match(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        expect("30:@".gen.size).to eq(30)
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
end
