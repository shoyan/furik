require 'octokit'

module Furik
  class PullRequests
    def initialize(client, owner = nil)
      @client = client
      @login = client.login
      @owner = owner
    end

    def request_manager
      limit = @client.rate_limit
      if !limit.limit.zero? && limit.remaining.zero?
        puts "Oops! #{limit}"
        sleep limit.resets_in
      end
    # No rate limit for white listed users
    rescue Octokit::NotFound
    end

    def all(&block)
      @block = block
      @all || all!
    end

    def all!
      @all = all_repo_names.each.with_object([]) do |repo_name, memo|
        if @owner.nil? || repo_name.match(/#{@owner}\/.*/)
          pulls = pull_requests(repo_name)
          memo.concat pulls if pulls.is_a?(Array)
          request_manager
        end
     end
    end

    def org_name_from(repo_name)
      repo_name.split('/').first
    end

    # Use the issues api so specify the creator
    def pull_requests(repo_name)
      org_name = org_name_from(repo_name)

      unless @block
        if @org_name == org_name
          print '-'
        else
          puts ''
          print "#{org_name} -"
          @org_name = org_name
        end
      end

      issues = @client.issues(repo_name, creator: @login, state: 'open').
        select { |issue| issue.pull_request }
      issues.concat @client.issues(repo_name, creator: @login, state: 'closed').
        select { |issue| issue.pull_request }

      @block.call(repo_name, issues) if @block

      issues
    rescue Octokit::ClientError
    rescue => e
      puts e
    end

    def all_repo_names
      self.user_repo_names.concat(self.orgs_repo_names).uniq
    end

    # It contains repositories of your organization, If you are a public member
    # of the organization.
    def user_repo_names
      @client.repos.map(&:full_name)
    end

    def user_orgs_names
      @client.orgs.map(&:login)
    end

    # It contains all repositories for your organization.
    def org_repo_names(org_name)
      @client.org_repos(org_name).map(&:full_name)
    end

    def orgs_repo_names
      user_orgs_names.each_with_object([]) do |org_name, memo|
        memo.concat org_repo_names(org_name)
      end
    end
  end
end
