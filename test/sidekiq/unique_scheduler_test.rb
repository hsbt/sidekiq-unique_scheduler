require 'test_helper'

class Sidekiq::UniqueSchedulerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::UniqueScheduler::VERSION
  end
end
