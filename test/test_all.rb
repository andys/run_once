
require 'test/unit'
require "./#{File.dirname(__FILE__)}/../lib/run_once.rb"

class TestRunOnce < Test::Unit::TestCase
  class TestException < Exception ; end

  def setup
    @fn = './run_once.db'
    File.unlink @fn rescue nil
    RunOnce.use_file = @fn
  end
  
  def teardown
    File.unlink @fn rescue nil
  end
  
  def test_db_file
    assert File.exists?(@fn)
  end
  
  def test_db_ops
    assert_equal nil, RunOnce.lookup_db('A')
    RunOnce.update_db('A', 1.1)
    assert_equal 1.1, RunOnce.lookup_db('A').to_f
    RunOnce.update_db('A', 2.2)
    assert_equal 2.2, RunOnce.lookup_db('A').to_f
  end
  
  def test_manual_context
    assert_raises TestException do
      RunOnce.with_context('test').in(0.5) { raise TestException.new }
    end
    3.times do
      assert_nothing_raised TestException do
        RunOnce.with_context('test').in(0.5) { raise TestException.new }
      end
      sleep 0.1
    end
    sleep 0.3
    assert_raises TestException do
      RunOnce.with_context('test').in(0.5) { raise TestException.new }
    end
  end

  def test_auto_context
    block = lambda do 
      RunOnce.in(0.5) { raise TestException.new }
    end
    assert_raises TestException, &block
    3.times do
      assert_nothing_raised TestException, &block
      sleep 0.1
    end
    sleep 0.3
    assert_raises TestException, &block
  end
  
  def test_1_sec
    stop_time = Time.now + 0.95
    counter = 0
    while(stop_time > Time.now)
      RunOnce.in(0.1) { counter += 1 }
    end
    assert_equal 10, counter
  end
end
