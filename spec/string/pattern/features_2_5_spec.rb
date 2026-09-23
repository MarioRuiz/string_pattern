require "json"
require "string_pattern"

RSpec.describe StringPattern, "2.5" do
  describe "seed isolation" do
    it "does not change Kernel rand" do
      srand(1234)
      before = Array.new(5) { rand(1000) }
      srand(1234)
      "20:N".gen(seed: 42)
      ["4:N", "-", "4:N"].gen(seed: 7)
      after = Array.new(5) { rand(1000) }
      expect(after).to eq(before)
    end

    it "keeps array patterns deterministic for one seed" do
      first = ["3:N", "-", "3:X"].gen(seed: 5)
      second = ["3:N", "-", "3:X"].gen(seed: 5)
      expect(first).to eq(second)
      expect(first).to match(/\A\d{3}-[A-Z]{3}\z/)
    end
  end

  describe "sample" do
    it "repeats the same series for the same seed" do
      first = StringPattern.sample("4:N", 3, seed: 7)
      second = StringPattern.sample("4:N", 3, seed: 7)
      expect(first).to eq(second)
      expect(first.uniq.size).to eq(3)
    end

    it "returns an empty array when n is 0" do
      StringPattern.dont_repeat = true
      expect(StringPattern.sample("2:N", 0)).to eq([])
      expect(StringPattern.dont_repeat).to eq(true)
    ensure
      StringPattern.dont_repeat = false
    end
  end

  describe "with and reset!" do
    it "restores settings after the block" do
      StringPattern.word_separator = "_"
      StringPattern.dont_repeat = false
      StringPattern.with(dont_repeat: true, word_separator: "-") do
        expect(StringPattern.dont_repeat).to eq(true)
        expect(StringPattern.word_separator).to eq("-")
      end
      expect(StringPattern.dont_repeat).to eq(false)
      expect(StringPattern.word_separator).to eq("_")
    end

    it "restores settings when the block raises" do
      StringPattern.dont_repeat = false
      expect {
        StringPattern.with(dont_repeat: true) { raise "boom" }
      }.to raise_error("boom")
      expect(StringPattern.dont_repeat).to eq(false)
    end

    it "rejects unknown options" do
      expect { StringPattern.with(nope: true) {} }.to raise_error(ArgumentError, /unknown option/)
    end

    it "reset! restores defaults and clears caches" do
      StringPattern.dont_repeat = true
      StringPattern.word_separator = "-"
      StringPattern.block_list_regexp = true
      StringPattern.cache["temp"] = "x"
      StringPattern.cache_values["temp"] = ["x"]
      StringPattern.reset!
      expect(StringPattern.dont_repeat).to eq(false)
      expect(StringPattern.word_separator).to eq("_")
      expect(StringPattern.block_list_regexp).to eq(false)
      expect(StringPattern.cache).to eq({})
      expect(StringPattern.cache_values).to eq({})
      expect(StringPattern::VERSION).to eq("2.5.0")
    end
  end

  describe "raise_on_error" do
    it "raises InvalidPatternError for a pattern of the wrong type" do
      StringPattern.with(raise_on_error: true) do
        expect { StringPattern.generate(5) }.to raise_error(StringPattern::InvalidPatternError)
      end
    end

    it "raises GenerationImpossibleError when the requested errors cannot be produced" do
      StringPattern.with(raise_on_error: true) do
        expect { "10:N".gen(errors: :required_data) }.to raise_error(StringPattern::GenerationImpossibleError)
      end
    end
  end

  describe "block_list" do
    it "matches entries as literals" do
      StringPattern.with(block_list_enabled: true, block_list: ["+"]) do
        5.times do
          value = "6:[ab+]".gen
          expect(value).to match(/\A[ab]{6}\z/)
        end
      end
    end

    it "can match entries as regular expressions" do
      StringPattern.with(block_list_enabled: true, block_list: ["a+"], block_list_regexp: true) do
        5.times do
          expect("6:L".gen).not_to match(/a/i)
        end
      end
    end
  end

  describe "spanish vocabulary" do
    it "loads every spanish word file" do
      expected = (0..11).sum do |index|
        JSON.parse(File.read(File.expand_path("../../../../data/spanish/palabras#{index}.json", __FILE__))).size
      end
      StringPattern.instance_variable_set(:@palabras, [])
      StringPattern.instance_variable_set(:@palabras_camel, [])
      expect("10-20:p".gen).to match(/\A[a-z_áéíóúüñ]+\z/)
      expect(StringPattern.instance_variable_get(:@palabras).size).to eq(expected)
    end
  end

  describe "regexp validation" do
    it "matches the whole string" do
      expect(StringPattern.valid?(text: "abc", pattern: /[a-z]+/)).to eq(true)
      expect(StringPattern.valid?(text: "abc1", pattern: /[a-z]+/)).to eq(false)
      expect(/[a-z]+/.validate("abc")).to eq([])
      expect(/[a-z]+/.val("abc1")).to eq([:value])
    end

    it "keeps regexp options" do
      expect(/abc/i.validate("ABC")).to eq([])
    end
  end

  describe "explain" do
    it "reports errors for a single pattern" do
      report = StringPattern.explain(text: "ab", pattern: "6:N")
      expect(report[:valid]).to eq(false)
      expect(report[:errors]).to include(:min_length, :length)
      expect(report[:message]).to start_with("invalid:")
      expect(report[:index]).to be_nil
    end

    it "reports a valid array of patterns" do
      report = StringPattern.explain(text: "333xxx", pattern: ["3:n", "3:x"])
      expect(report).to include(valid: true, errors: [], index: nil)
    end

    it "reports the failing segment of an array" do
      report = StringPattern.explain(text: "333111", pattern: ["3:n", "3:x"])
      expect(report[:valid]).to eq(false)
      expect(report[:index]).to eq(1)
      expect(report[:message]).to include("segment 1")
    end
  end

  describe "iban" do
    it "generates a valid IBAN for a known country" do
      iban = StringPattern.iban(country: "de")
      expect(iban).to start_with("DE")
      expect(iban.length).to eq(22)
      expect(StringPattern.valid_iban?(iban)).to eq(true)
    end

    it "validates a published example and rejects an unknown country" do
      expect(StringPattern.valid_iban?("DE89 3704 0044 0532 0130 00")).to eq(true)
      expect(StringPattern.valid_iban?("NOT-AN-IBAN")).to eq(false)
      expect { StringPattern.iban(country: "ZZ") }.to raise_error(ArgumentError, /unknown IBAN country/)
    end
  end

  describe "luhn" do
    it "generates a valid digit string" do
      number = StringPattern.luhn(length: 16)
      expect(number).to match(/\A\d{16}\z/)
      expect(StringPattern.valid_luhn?(number)).to eq(true)
    end

    it "checks a known number and rejects a short length" do
      expect(StringPattern.valid_luhn?("79927398713")).to eq(true)
      expect(StringPattern.valid_luhn?("79927398714")).to eq(false)
      expect { StringPattern.luhn(length: 1) }.to raise_error(ArgumentError, /length must be >= 2/)
    end
  end
end
