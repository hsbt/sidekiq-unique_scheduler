require 'socket'
require 'diplomat'
require 'sidekiq-scheduler'
require "sidekiq/unique_scheduler/version"

module Sidekiq
  module UniqueScheduler
    class << self
      attr_accessor :schedule, :node_prefix, :node_suffix

      def lock
        cleanup_dirty_node
        sessionid = Diplomat::Session.create({:Node => nodename, :Name => "sidekiq-unique_scheduler"})
        if !(lock = Diplomat::Lock.acquire("/sidekiq-unique_scheduler/lock", sessionid))
          Diplomat::Session.destroy(sessionid)
        end
        lock
      end

      def unlock
        if node_session = session_list.find{|s| s['Node'] == nodename }
          Diplomat::Session.destroy(node_session['ID'])
        end
      end

      private

      def session_list
        Diplomat::Session.list.select{|s| s['Name'] == "sidekiq-unique_scheduler" }
      end

      def cleanup_dirty_node
        session_list.each do |session|
          node = Diplomat::Health.node(session['Node'])
          if node[0] && node[0]['Status'] == 'critical'
            Diplomat::Session.destroy(session['ID'])
          end
        end
      end

      def nodename
        "#{node_prefix}#{Socket.gethostname.chomp}#{node_suffix}"
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    if Sidekiq::UniqueScheduler.lock
      Sidekiq.schedule = Sidekiq::UniqueScheduler.schedule
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
