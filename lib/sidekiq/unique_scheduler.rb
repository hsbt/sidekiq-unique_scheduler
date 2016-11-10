require 'socket'
require 'diplomat'
require 'sidekiq-scheduler'
require "sidekiq/unique_scheduler/version"

module Sidekiq
  module UniqueScheduler
    def self.lock
      sessionid = Diplomat::Session.create({:Node => Socket.gethostname.chomp, :Name => "sidekiq-unique_scheduler"})
      Diplomat::Lock.acquire("/sidekiq-unique_scheduler/lock", sessionid)
    end

    def self.unlock
      if node_session = Diplomat::Session.list.select{|s| s['Node'] == Socket.gethostname.chomp }
        Diplomat::Session.destroy(node_session['ID'])
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    if Sidekiq::UniqueScheduler.lock
      Sidekiq::Scheduler.reload_schedule!
    else
      Sidekiq::Scheduler.enabled = false
    end
  end
  %i(quiet shutdown).each do |state|
    config.on(state) do
      Sidekiq::UniqueScheduler.unlock
    end
  end
end
