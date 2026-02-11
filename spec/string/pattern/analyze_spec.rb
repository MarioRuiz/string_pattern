require "string_pattern"

RSpec.describe StringPattern, ".analyze" do
  describe "single pattern" do
    it "returns a Pattern struct for simple length:symbol_type" do
      p = StringPattern.analyze("10:N")
      expect(p).to be_a(Struct)
      expect(p.min_length).to eq(10)
      expect(p.max_length).to eq(10)
      expect(p.symbol_type).to eq("N")
      expect(p.unique).to eq(false)
    end

    it "returns pattern with range min-max" do
      p = StringPattern.analyze("5-15:L")
      expect(p.min_length).to eq(5)
      expect(p.max_length).to eq(15)
      expect(p.symbol_type).to include("L")
    end
  end

  describe "symbol types" do
    it "parses N/n for numbers" do
      p = StringPattern.analyze("3:N")
      expect(p.symbol_type.downcase).to include("n")
      expect(p.string_set).to include(*StringPattern::NUMBER_SET)
    end

    it "parses L for letters" do
      p = StringPattern.analyze("4:L")
      expect(p.symbol_type).to include("L")
      expect(p.string_set).to include("a", "A")
    end

    it "parses x for lowercase" do
      p = StringPattern.analyze("2:x")
      expect(p.symbol_type).to include("x")
    end

    it "parses X for uppercase" do
      p = StringPattern.analyze("2:X")
      expect(p.symbol_type).to include("X")
    end

    it "parses @ for email" do
      p = StringPattern.analyze("20:@")
      expect(p.symbol_type).to eq("@")
    end
  end

  describe "required and excluded data" do
    it "parses required characters /x/" do
      p = StringPattern.analyze("6:XN/x/")
      expect(p.required_data).not_to be_empty
    end

    it "parses excluded characters [%0%]" do
      p = StringPattern.analyze("10:N[%0%]")
      expect(p.excluded_data).not_to be_empty
      expect(p.excluded_data.flatten).to include("0")
    end

    it "parses data_provided [abc]" do
      p = StringPattern.analyze("5:[abc]")
      expect(p.data_provided).to include("a", "b", "c")
    end
  end

  describe "unique flag" do
    it "sets unique true when pattern ends with &" do
      p = StringPattern.analyze("6-10:L&")
      expect(p.unique).to eq(true)
      expect(p.symbol_type).to eq("L")
    end

    it "sets unique false when no &" do
      p = StringPattern.analyze("6:L")
      expect(p.unique).to eq(false)
    end
  end

  describe "deny pattern !" do
    it "includes ! in symbol_type when pattern starts with !" do
      p = StringPattern.analyze("!10:N")
      expect(p.symbol_type).to start_with("!")
    end
  end

  describe "silent" do
    it "returns pattern string for invalid pattern and does not put when silent: true" do
      expect { StringPattern.analyze(":N", silent: true) }.not_to output.to_stdout
      expect(StringPattern.analyze(":N", silent: true)).to eq(":N")
    end

    it "prints message for invalid pattern when silent: false" do
      expect { StringPattern.analyze(":N", silent: false) }.to output(/pattern argument not valid/).to_stdout
      expect(StringPattern.analyze(":N", silent: false)).to eq(":N")
    end
  end

  describe "caching" do
    it "returns cached result for same pattern" do
      p1 = StringPattern.analyze("7:Tn")
      p2 = StringPattern.analyze("7:Tn")
      expect(p1.min_length).to eq(p2.min_length)
      expect(p1.symbol_type).to eq(p2.symbol_type)
    end
  end
end
