require "string_pattern"

RSpec.describe StringPattern, "#add_to_ruby" do
  describe "array class" do
    it "responds to generate" do
      expect(["uno", "2:n"].generate).to match(/uno[0-9]{2}/)
    end
    it "responds to gen" do
      expect(["uno", "2:n"].gen).to match(/uno[0-9]{2}/)
    end
    it "responds to validate" do
      expect(["uno", "2:n"].validate("uno33")).to eq true
    end
    it "responds to val" do
      expect(["uno", "2:n"].val("uno33")).to eq true
    end
  end

  describe "string class" do
    it "responds to generate" do
      expect("2:n".generate).to match(/[0-9]{2}/)
    end
    it "responds to gen" do
      expect("2:n".gen).to match(/[0-9]{2}/)
    end
    it "responds to validate" do
      expect("2:n".validate("33")).to eq []
    end
    it "responds to val" do
      expect("2:n".val("33")).to eq []
    end
    it "responds to to_camel_case" do
      expect("ccccc aaa".to_camel_case).to eq "CccccAaa"
    end
    it "responds to to_snake_case" do
      expect("Caaaa bjjAm, ; Djjáb".to_snake_case).to eq "caaaa_bjj_am_djj_b"
    end
    it 'returns camel case of Spanish characters' do
      expect("caña de albóndiga".to_camel_case).to eq "CañaDeAlbóndiga"
    end
  end

  describe "symbol class" do
    it "responds to generate" do
      expect(:'2:n'.generate).to match(/[0-9]{2}/)
    end
    it "responds to gen" do
      expect(:'2:n'.gen).to match(/[0-9]{2}/)
    end
    it "responds to validate" do
      expect(:'2:n'.validate("33")).to eq []
    end
    it "responds to val" do
      expect(:'2:n'.val("33")).to eq []
    end
  end

  describe "regexp class" do
    it "responds to generate" do
      expect(/\d{2}/.generate).to match(/[0-9]{2}/)
    end
    it "responds to gen" do
      expect(/\d{2}/.gen).to match(/[0-9]{2}/)
    end
    it "responds to to_sp" do
      expect(/\d{2}/.to_sp).to eq "2:n"
    end
    it "/[^abc]+/i.to_sp" do
      expect(/[^abc]+/i.to_sp).to eq "1-10:[%aAbBcC%]*"
    end
    it "/[abc]+/i.to_sp" do 
      expect(/[abc]+/i.to_sp).to eq "1-10:[aAbBcC]"
    end
    it "/[a-z]+/i.to_sp" do
      expect(/[a-z]+/i.to_sp).to eq "1-10:L"
    end
    it "/[a-z]+/.to_sp" do
      expect(/[a-z]+/.to_sp).to eq "1-10:x"
    end
    it "/[m-z]+/i.to_sp" do
      expect(/[m-z]+/i.to_sp).to eq '1-10:[mnopqrstuvwxyzMNOPQRSTUVWXYZ]'
    end
    it '/[m-z]+\d+\w+[ab]+/i.to_sp' do
      expect(/[m-z]+\d+\w+[ab]+/i.to_sp).to eq ["1-10:[mnopqrstuvwxyzMNOPQRSTUVWXYZ]", "1-10:n", "1-10:Ln_", "1-10:[aAbB]"]
    end
    it '/a{3,}/.to_sp' do
      expect(/a{3,}/.to_sp).to eq '3-13:[a]'
    end
    it '/a{3,8}/.to_sp' do
      expect(/a{3,8}/.to_sp).to eq '3-8:[a]'
    end
    it '/a{3}/.to_sp' do
      expect(/a{3}/.to_sp).to eq '3:[a]'
    end
    it '/a{15,}/.to_sp' do
      expect(/a{15,}/.to_sp).to eq '15-25:[a]'
    end

  end

  describe "from Kernel" do
    it "responds to generate" do
      expect(generate("2:N")).to match(/[0-9]{2}/)
    end
    it "responds to gen" do
      expect(gen("2:N")).to match(/[0-9]{2}/)
    end
    it "display error when wrong type on array of patterns" do
        expect { generate(3)}.to output(/Kernel generate method: class not recognized/).to_stdout
    end
  
  end
end
