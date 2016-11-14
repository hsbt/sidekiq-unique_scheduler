require 'test_helper'

class Sidekiq::UniqueSchedulerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::UniqueScheduler::VERSION
  end

  def test_unique_scheduler_lock
    Diplomat::Session.expects(:list).returns([]).once
    Diplomat::Session.expects(:create).returns('foo').once
    Diplomat::Lock.expects(:acquire).with("/sidekiq-unique_scheduler/lock", 'foo').returns(true).once
    assert Sidekiq::UniqueScheduler.lock
  end

  def test_unique_scheduler_unlock
    Diplomat::Session.expects(:list).returns([{'Node' => Socket.gethostname.chomp, 'Name' => "sidekiq-unique_scheduler"}]).once
    Diplomat::Session.expects(:destroy).once
    Sidekiq::UniqueScheduler.unlock
  end

  def test_unique_scheduler_lock_with_dirty_exit
    Diplomat::Session.expects(:list).returns([{'Node' => Socket.gethostname.chomp + "-2", 'Name' => "sidekiq-unique_scheduler"}]).once
    Diplomat::Health.expects(:node).with(Socket.gethostname.chomp + "-2").returns([{'ID' => 'foo', 'Status' => 'critical'}]).once
    Diplomat::Session.expects(:destroy).with(any_parameters).once

    Diplomat::Session.expects(:create).returns('bar').once
    Diplomat::Lock.expects(:acquire).with("/sidekiq-unique_scheduler/lock", 'bar').returns(true).once
    assert Sidekiq::UniqueScheduler.lock
  end
end
