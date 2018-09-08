require 'minitest/autorun'
require './lib/string_pattern'

class TestLength < Minitest::Test
  def test_fix_length
	assert :"10:LN".gen.length==10
  end

  def test_min_length
	assert :"10-20:LN".gen.length>=10
  end

  def test_max_length
	assert :"10-20:LN".gen.length<=20
  end

end
