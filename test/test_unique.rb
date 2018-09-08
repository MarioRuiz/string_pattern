require 'minitest/autorun'
require './lib/string_pattern'

class TestUnique < Minitest::Test
  def test_symbol
    res=Array.new()
	10.times{
		res<<:"1:N&".gen
	}
	res.uniq!
	assert res.size==10
  end
  
  def test_dont_repeat
	StringPattern.dont_repeat=true
    res=Array.new()
	10.times{
		res<<:"1:N".gen
	}
	res.uniq!
	StringPattern.dont_repeat=false
	assert res.size==10
  end
end


