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

require "json"
require "date"
require_relative '../util'

module JenkinsPullover
  module Github
    class Model

      include JenkinsPullover::Util

      JENKINS_PREFIX = "JenkinsPullover Build Initiated"

      attr_accessor :github_client, :github_user, :github_repo, :user, 
        :password, :base_branch
      attr_writer :debug

      # Parse the Github json into Ruby
      def self.parse_github_json(github_json)
        JSON.parse(github_json, {:symbolize_names => true})
      end

      # Class contructor overloaded
      def initialize(opts = {})
        initialize_opts(opts)
      end

      # Processs open pull requests for building
      def process_pull_requests
        raise RuntimeError,
          "Github client is not available" if @github_client.nil?

        raise RuntimeError, 
          "Github client is not ready" unless @github_client.ready

        pulls_requiring_build = []

        start_time = Time.now.to_f
        $stderr.puts("Starting Github inspection...") if @debug
        pulls_json = @github_client.pull_requests

        # Parse the JSON into JSON Objects
        pulls = JenkinsPullover::Github::Model.parse_github_json(pulls_json)

        if pulls.kind_of?(Hash) && pulls.has_key?(:message)
          raise RuntimeError,
            "Github responded with error: #{pulls[:message]}"
        end

        pulls.select {|pull| pull[:state] == "open"}.each do |pull|
          # Check the base branch matches
          next unless check_pull_base_branch(pull)

          # Examine the comments to detect whether build required
          if build_required(pull)
            $stderr
              .puts(" => Build required on pull #{pull[:number]}") if @debug
            
            pulls_requiring_build << pull
          end
        end

        epoc = (Time.now.to_f - start_time).round
        $stderr.puts("Completed Github inspection in #{epoc}s") if @debug

        pulls_requiring_build
      end

      # Checks the pull request against the base branch
      def check_pull_base_branch(pull)
        $stderr.puts(" => Processing pull #{pull[:number]}...") if @debug

        pull_detail = @github_client.pull_request(pull[:number]);
        detail = JenkinsPullover::Github::Model.parse_github_json(pull_detail)
        $stderr
          .puts(" => #{@base_branch} <== #{detail[:base][:label]}") if @debug

        result = @base_branch == detail[:base][:label]

        if @debug
          $stderr.puts(" => Skipping pull #{pull[:number]}") unless result
        end

        result
      end

      # Returns the comments for pull id
      def get_comments_for_pull(id)
        comments_json = @github_client.comments_for_pull_request(id)
        
        comments = JenkinsPullover::Github::Model.parse_github_json(comments_json)

        if @debug
          $stderr.puts(" => No comments for #{id}") unless comments.size > 0
        end

        comments
      end

      # Create a comment on pull with text
      def create_comment_for_pull(pull, comment)
        body = {:body => comment}
        @github_client.create_comment_for_pull(pull, JSON.generate(body))
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
            if comment[:body].scan(/^JenkinsPullover Build Initiated/).size > 0
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
    end
  end
end