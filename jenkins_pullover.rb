# Jenkins Pullover Main Application

# Author::    Sam de Freyssinet (sam@def.reyssi.net)
# Copyright:: Copyright (c) 2012 Sittercity, Inc. All Rights Reserved. 
# License::   MIT License
# 
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

require 'optparse'
require 'ostruct'
require_relative 'lib/daemon'
require_relative 'lib/github/client'
require_relative 'lib/github/model'
require_relative 'lib/jenkins/client'
require_relative 'lib/jenkins/model'

VERSION = {:major=>0, :minor=>1, :revision=>0}

module JenkinsPullover
    class CommandLine

      ERR_OK                = 0
      ERR_NO_GITHUB_ACCOUNT = 1
      ERR_NO_GITHUB_REPO    = 2

      # Class constructor
      def initialize
        @options = OpenStruct.new
        @options.branch        = 'master'
        @options.debug         = false
        @options.frequency     = 60
        @options.logfile       = '/var/log/jenkins_pullover.log'
        @options.daemon        = false
        @options.jenkins_url   = 'http://localhost:8080'
        @options.jenkins_token = nil
        @options.jenkins_job   = nil
      end

      # JenkinsPullover::CommandLineOptionParser.parse(opts)
      def parse(args)
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: ruby jenkins-pullover.rb --account ACCOUNT --repo REPO [options]"
          opts.separator "       ruby jenkins-pullover.rb --account ACCOUNT --repo REPO --pull PULL --comment COMMENT"
          opts.separator ""
          opts.separator "Github:"

          # Mandentory
          opts.on("--account ACCOUNT", "[Required] The github account that owns the repository") do |account|
            @options.github_user = account
          end

          opts.on("--repo REPO", "[Required] The github repository to pull from") do |repo|
            @options.github_repo = repo
          end

          opts.on("--job JOB", "[Required] The jenkins job name") do |job|
            @options.github_repo = job
          end

          opts.separator "Options:"

          # Optional
          opts.on("--jenkins URL", "The jenkins server URL (default = localhost:8080)") do |url|
            @options.jenkins_url = url
          end

          opts.on("--token TOKEN", "The jenkins build token") do |token|
            @options.jenkins_token = token
          end

          opts.on("--username USERNAME", "Your github username") do |username|
            @options.user = username
          end
          
          opts.on("--password PASSWORD", "Your github password") do |password|
            @options.password = password
          end

          opts.on("-b", "--base BRANCH", "The base branch pulls are targeting (default = master)") do |branch|
            @options.branch = branch
          end

          opts.on("-d", "--daemon", "Daemonize the the process") do
            puts "Daemonising!!!"
            @options.daemon = true
          end

          opts.on("-D", "--debug", "Output debug information to STDERR") do
            @options.debug = true
          end

          opts.on("-f", "--frequency SECONDS", Float, "Frequency of Github polling in seconds (default = 60) (min = 1)") do |frequency|
            @frequency = frequency
          end

          opts.on("-l", "--log FILE", "Log to file (default = /var/log/jenkins_pullover.log) ") do |file|
            @options.logfile = file
          end

          opts.on_tail("-h", "--help", "This help dialog") do
            puts opts
            exit
          end

          opts.on_tail("-v", "--version", "Version information") do
            puts "Version #{VERSION.values.join('.')}"
            puts "Written by Sam de Freyssinet, all rights reserved"
            exit
          end
        end
        
        opts.parse!(args)

        if @options.github_user.nil?
          puts("Error: --account argument is required")
          puts opts
          exit JenkinsPullover::CommandLine::ERR_NO_GITHUB_ACCOUNT
        elsif @options.github_repo.nil?
          puts("Error: --repo argument is required")
          puts opts
          exit JenkinsPullover::CommandLine::ERR_NO_GITHUB_REPO
        end
      end

      # Runs the main application
      def main
        github_client = JenkinsPullover::Github::Client.new({
          :github_user => @options.github_user,
          :github_repo => @options.github_repo,
          :user        => @options.user,
          :password    => @options.password
        })

        jenkins_client = JenkinsPullover::Jenkins::Client.new({
          :jenkins_url       => @options.jenkins_url,
          :jenkins_build_key => @options.jenkins_token
        })

        jenkins = JenkinsPullover::Jenkins::Model.new({
          :jenkins_client    => jenkins_client
        })

        github = JenkinsPullover::Github::Model.new({
          :github_client => github_client,
          :debug         => @options.debug,
          :base_branch   => @options.branch
        }
        )

        github.process_pull_requests.each do |pull|
          github.create_comment_for_pull(
            pull[:number],
            JenkinsPullover::Github::Model::JENKINS_PREFIX
          )
          
          jenkins.trigger_build_for_job(@options.jenkins_job, {
            :GITHUB_ACCOUNT     => @options.github_user,
            :GITHUB_PULL_NUMBER => pull[:number],
            :GITHUB_USERNAME    => @options.user
          })
        end

        
      end
    end
end

# Invoke the application here
app = JenkinsPullover::CommandLine.new
app.parse(ARGV)

app.main
