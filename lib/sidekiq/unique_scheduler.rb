require 'sidekiq/scheduler'
require "sidekiq/unique_scheduler/version"

module Sidekiq
  module UniqueScheduler
    mattr_accessor :master_server

    def self.master_server?
      # すでに master が存在している状態で、新規にサーバーを立ち上げた場合に
      # 立ち上げたサーバーが `master_server` メソッドによりマスターサーバーとして
      # 判定されると `register_server` メソッドで無限ループするため、すでに
      # `master_server` として稼働しているサーバーが存在するときは scheduler の
      # ロードはスキップする
      !Sidekiq.redis {|conn| conn.get('sidekiq:schedules:master')} && (`hostname`.chomp == self.master_server&.call)
    end

    def self.register_server
      catch(:reset_master_server) do
        loop do
          master = Sidekiq.redis {|conn| conn.get('sidekiq:schedules:master')}
          if master
            Sidekiq.logger.warn("Scheduler master is #{master}, waiting to reset scheduler master")
            sleep 60
          else
            throw(:reset_master_server)
          end
        end
      end
      Sidekiq.redis {|conn| conn.set('sidekiq:schedules:master', `hostname`.chomp) }
    end

    def self.reset_master_server!
      if `hostname`.chomp == Sidekiq.redis {|conn| conn.get('sidekiq:schedules:master')}
        Sidekiq.redis {|conn| conn.del('sidekiq:schedules:master')}
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    if Sidekiq::UniqueScheduler.master_server?
      Sidekiq::UniqueScheduler.register_server
      Sidekiq::Scheduler.reload_schedule!
    else
      Sidekiq::Scheduler.enabled = false
    end
  end
  %i(quiet shutdown).each do |state|
    config.on(state) do
      Sidekiq::UniqueScheduler.reset_master_server!
    end
  end
end
