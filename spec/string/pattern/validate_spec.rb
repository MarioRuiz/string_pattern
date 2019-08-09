require "string_pattern"

RSpec.describe StringPattern, "#validate" do
  describe "generic" do
    it "returns empty when good validation" do
      expect("6:N".validate("333444")).to eq([])
    end
    it "returns true when good validation for array of patterns" do
      expect(["3:n", "3:x"].validate("333xxx")).to eq(true)
    end
    it "accepts symbols as patterns" do
      expect(:"6:N".validate("333444")).to eq([])
    end
    it "display error when wrong type on array of patterns" do
      expect(['1:N',3].validate('3')).to eq false
      expect { ['1:N',3].validate('3')}.to output(/String pattern class not supported/).to_stdout
    end
  end
  describe "length" do
    it "returns :min_length when wrong :min_length" do
      expect("6:N".validate("33344")).to include(:min_length)
    end
    it "returns :length when wrong :min_length" do
      expect("6:N".validate("33344")).to include(:length)
    end
    it "returns :max_length when wrong :max_length" do
      expect("6:N".validate("4433344")).to include(:max_length)
    end
    it "returns :length when wrong :max_length" do
      expect("6:N".validate("5466633344")).to include(:length)
    end
    it "returns false when array of patterns and wrong :min_length" do
      expect(["3:n", "3:x"].validate("333xx")).to eq false
    end
    it "returns false when array of patterns and wrong :max_length" do
      expect(["3:n", "3:x"].validate("3333xxxx")).to eq false
    end
  end
  describe "value" do
    it "returns :value when wrong :value" do
      expect("6:N".validate("33d344")).to include(:value)
    end
    it "returns :excluded_data when including :excluded_data" do
      expect("6:N[%0%]".validate("330344")).to include(:excluded_data)
    end
    it "returns :required_data when missing :required_data" do
      expect("6:N[/0/]".validate("334344")).to include(:required_data)
    end
    it "returns :string_set_not_allowed when including string_set_not_allowed" do
      expect("6:N".validate("33a344")).to include(:string_set_not_allowed)
    end
    it "returns false when array of patterns and wrong :value" do
      expect(["3:n", "3:x"].validate("3x3xxx")).to eq false
    end
  end

  describe "expected_errors" do
    it "admits alias :errors" do
      expect("6:N".validate("335344", errors: [:value])).to eq(false)
    end
    it "returns false when good :value" do
      expect("6:N".validate("335344", expected_errors: [:value])).to eq(false)
    end
    it "returns true when wrong :value" do
      expect("6:N".validate("33d344", expected_errors: [:value])).to eq(true)
    end
    it "allows array of patterns" do
      expect(["3:n", "3:x"].validate("333xx3", errors: [:value])).to be true
    end
  end

  describe "not expected_errors" do
    it "admits alias :not_errors" do
      expect("6:N".validate("335344", not_errors: [:value])).to eq(true)
    end
    it "admits alias :non_expected_errors" do
      expect("6:N".validate("335344", non_expected_errors: [:value])).to eq(true)
    end
    it "returns true when good :value" do
      expect("6:N".validate("335344", not_expected_errors: [:value])).to eq(true)
    end
    it "returns false when wrong :value" do
      expect("6:N".validate("33d344", not_expected_errors: [:value])).to eq(false)
    end
    it "allows array of patterns" do
      expect(["3:n", "3:x"].validate("333xx", not_errors: [:value])).to be true
    end
  end
end
