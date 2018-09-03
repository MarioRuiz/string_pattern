require 'minitest/autorun'
require './lib/string_pattern'

class TestValue < Minitest::Test
  def test_alphanumeric
	assert :"1000:LN".gen.scan(/^[a-zA-Z\d]+$/).size>0
  end
  
  def test_mandatory_character
	assert :"1000:L/N/".gen.scan(/\d+/).size>0
  end

  def test_exclude_character
	assert :"1000:N[%0%]".gen.include?("0")==false
  end

  def test_include_character
	assert :"1000:N[abc]".gen.scan(/^[abc\d]+$/).size>0
  end
  
end


