require 'octokit'
require 'furik/core_ext/string'
require 'furik/configurable'
require 'furik/pull_requests'
require 'furik/events'
require "furik/version"

module Furik
  class << self
    def gh_client
      Octokit::Client.new Configurable.github_octokit_options
    end

    def ghe_client
      Octokit::Client.new Configurable.github_enterprise_octokit_options
    end

    def events_with_grouping(gh: true, ghe: true, from: nil, to: nil, &block)
      events = []

      if gh
        gh_events = Events.new(gh_client).events_with_grouping(from, to, &block)
        events.concat gh_events if gh_events.is_a?(Array)
      end

      if ghe
        ghe_events = Events.new(ghe_client).events_with_grouping(from, to, &block)
        events.concat ghe_events if ghe_events.is_a?(Array)
      end

      events
    end

    def pull_requests(gh: true, ghe: true, owner: nil, &block)
      pulls = []

      if gh
        gh_pulls = PullRequests.new(gh_client, owner).all(&block)
        pulls.concat gh_pulls if gh_pulls.is_a?(Array)
      end

      if ghe
        ghe_pulls = PullRequests.new(ghe_client, owner).all(&block)
        pulls.concat ghe_pulls if ghe_pulls.is_a?(Array)
      end

      pulls
    end
  end
end
