require 'test/unit'
require 'skrapojan'

class SkrapojanTest < Test::Unit::TestCase
  def test_english_hello
    assert_equal "hello world",
      Hola.hi("english")
  end
end
