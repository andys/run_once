
require 'test/unit'
require "./#{File.dirname(__FILE__)}/../lib/only_once.rb"

class TestOnlyOnce < Test::Unit::TestCase
  class TestException < Exception ; end

  def setup
    @fn = './only_once.db'
    File.unlink @fn rescue nil
    OnlyOnce.use_path = '.'
  end
  
  def test_db_file
    assert File.exists?(@fn)
  end
  
  def test_db_ops
    assert_equal nil, OnlyOnce.lookup_db('A')
    OnlyOnce.update_db('A','b')
    assert_equal 'b', OnlyOnce.lookup_db('A')
  end
  
  def test_manual_context
    assert_raises TestException do
      OnlyOnce.with_context('test').in(5) { raise TestException.new }
    end
    3.times do
      assert_nothing_raised TestException do
        OnlyOnce.with_context('test').in(5) { raise TestException.new }
      end
      sleep 1
    end
    sleep 3
    assert_raises TestException do
      OnlyOnce.with_context('test').in(5) { raise TestException.new }
    end
  end

  def test_auto_context
    block = lambda do 
      OnlyOnce.in(5) { raise TestException.new }
    end
    assert_raises TestException, &block
    3.times do
      assert_nothing_raised TestException, &block
      sleep 1
    end
    sleep 3
    assert_raises TestException, &block
  end
end
