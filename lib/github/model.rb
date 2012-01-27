# Jenkins Pullover Github Model

# Author::    Sam de Freyssinet (sam@def.reyssi.net)
# Copyright:: Copyright (c) 2012 Sittercity, Inc. All Rights Reserved. 
# License::   MIT License (http://www.opensource.org/licenses/mit-license.php)

# Copyright (c) 2012 Sittercity, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

require "date"
require_relative '../util'

module JenkinsPullover
  module Github
    class Model

      include JenkinsPullover::Util

      attr_accessor :github_client, :github_user, :github_repo, :user, 
        :password, :base_branch, :comment_prefix
      attr_writer :debug

      # Class contructor overloaded
      def initialize(opts = {})
        initialize_opts(opts)
      end

      # Report the ready state of the model
      def ready?
        return false if @github_client.nil?
        @github_client.ready?
      end

      # Processs open pull requests for building
      def process_pull_requests
        raise RuntimeError, 
          "Github client is not ready" unless ready?

        pulls_requiring_build = []

        start_time = Time.now.to_f
        $stderr.puts("Starting Github inspection...") if @debug
        pull_requests = @github_client.pull_requests

        pull_requests.select {|pull_request| 
          pull_request[:state] == "open"
        }.each do |pull_request|
          # Check the base branch matches
          next unless check_pull_base_branch(pull_request)

          # Examine the comments to detect whether build required
          if build_required(pull_request)
            $stderr
              .puts(" => Build required on pull #{pull_request[:number]}") if @debug
            
            pulls_requiring_build << pull
          end
        end

        epoc = (Time.now.to_f - start_time).round
        $stderr.puts("Completed Github inspection in #{epoc}s") if @debug

        pulls_requiring_build
      end

      # Checks the pull request against the base branch
      def check_pull_base_branch(pull)
        raise RuntimeError, 
          "Github client is not ready" unless ready?

        $stderr.puts(" => Processing pull #{pull[:number]}...") if @debug

        full_pull = @github_client.pull_request(pull[:number]);

        $stderr
          .puts(" => #{@base_branch} <== #{full_pull[:base][:label]}") if @debug

        result = @base_branch == full_pull[:base][:label]

        if @debug
          $stderr.puts(" => Skipping pull #{full_pull[:number]}") unless result
        end

        result
      end

      # Returns the comments for pull id
      def get_comments_for_pull(id)
        raise RuntimeError, 
          "Github client is not ready" unless ready?
        
        comments = @github_client.comments_for_pull_request(id)

        if @debug
          $stderr.puts(" => No comments for #{id}") unless comments.size > 0
        end

        comments
      end

      # Create a comment on pull with text
      def create_comment_for_pull(pull, comment)
        body = {:body => comment}
        @github_client.create_comment_for_pull(pull, body)
      end

      # Discover if a new build is required
      def build_required(pull)
        build_required = false

        if pull[:merged]
          $stderr.puts(" => Pull #{pull[:number]} already merged") if @debug
          return build_required
        end

        unless pull[:mergable]
          $stderr.puts(" => Pull #{pull[:number]} is not mergeable") if @debug
          return build_required
        end

        # Get comments for the current pull
        comments = get_comments_for_pull(pull[:number])
        pull_lastupdated = DateTime.strptime(pull[:updated_at])
        last_build = DateTime.new(0)

        if comments.size > 0
          previous_build = nil

          comments.each do |comment|
            if comment[:body].match("#{build_scheduled_message}")
              last_build = DateTime.strptime(comment[:created_at])
            end
          end

          if @debug && last_build != DateTime.new(0)
            $stderr
              .puts(" => Last build detected at #{last_build}")
          end

          # Decide if to build based on update vs last build
          build_required = true if last_build < pull_lastupdated
        else
          build_required = true
        end

        build_required
      end

      # Github build result message
      def build_result_message(build_number, state)
        if state == :success
          result = "SUCCESS"
        else
          result = "FAILURE"
        end

        "#{@comment_prefix} build:#{build_number} was a #{result}"
      end

      # Github build started message
      def build_started_message(build_number)
        "#{@comment_prefix} has started pull request build:#{build_number}"
      end

      # Github build scheduled message
      def build_scheduled_message
        "#{@comment_prefix} has scheduled a build"
      end

      # Github server process
      def process(options, task_model)

        raise RuntimeError, 
          "Github client is not ready" unless ready?

        raise RuntimeError, 
          "Task model is not ready" unless task_model.ready?

        process_pull_requests.each do |pull|
          create_comment_for_pull(
              pull[:number],
              build_scheduled_message
          ) if task_model.process(options, pull)
        end
      end
    end
  end
end