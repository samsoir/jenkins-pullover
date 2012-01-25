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

VERSION = {:major=>0, :minor=>2, :revision=>0}

module JenkinsPullover
    class CommandLine

      ERR_OK                = 0
      ERR_NO_GITHUB_ACCOUNT = 1
      ERR_NO_GITHUB_REPO    = 2

      # Class constructor
      def initialize
        @options = OpenStruct.new
        @options.command = :daemon

        @options.daemon  = {
          :command      => nil, 
          :debug        => false, 
          :log_file     => 'var/log/jpullr.log',
          :frequency    => 5
        }

        @options.github  = {
          :command      => nil,
          :remote_name  => nil,
          :account      => nil,
          :repo         => nil,
          :branch       => 'master',
          :pull         => nil,
          :message      => nil,
          :close        => false,
          :merge        => false,
          :user         => nil,
          :password     => nil
        }

        @options.jenkins = {
          :command      => nil,
          :jenkins_name => nil,
          :jenkins_dsn  => 'http://localhost:8080',
          :job          => nil,
          :token        => nil
        }

        @options.attach  = {
          :command      => nil,
          :github       => nil,
          :jenkins      => nil
        }
      end

      # JenkinsPullover::CommandLineOptionParser.parse(opts)
      def parse(args)
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: jpullr COMMAND [options]"

          opts.separator "Command:"
          opts.separator "        start                        start the jpullr daemon"
          opts.separator "        stop                         stop the jpullr daemon"
          opts.separator "        restart                      restart the jpullr daemon"
          opts.separator ""

          # commands
          opts.on_head("start", "Start the server") do
            @options.daemon[:command]   = :start
          end

          opts.on_head("stop", "Stop the server") do
            @options.daemon[:command]   = :stop
          end

          opts.on_head("restart", "Restart the server") do
            @options.daemon[:command]   = :restart
          end

          opts.separator "Options:"
          opts.on("-D", "--debug", "Output debug information to STDERR") do
            @options.daemon[:debug]     = true
          end

          opts.on("-f", "--frequency SECONDS", Integer, "Frequency of Github polling in seconds (default = 5) (min = 1)") do |frequency|
            @options.daemon[:frequency] = frequency
          end

          opts.on("-l", "--log FILE", "Log to file (default = var/log/jenkins_pullover.log) ") do |file|
            @options.daemon[:log_file]  = file
          end

          opts.separator ""
          opts.separator "Github:"

          opts.on("--github-add RNAME", "Name of the repository to add") do |remote_name|
            @options.command = :remote_add
            @options.remote_name = remote_name
          end

          opts.on("--github-rm RNAME", "Remove remote repository by name") do |remote_name|
            @options.command = :remote_rm
            @options.remote_name = remote_name
          end

          opts.on("--comment-on RNAME", "Comment on remote repository by name") do |remote_name|
            @options.command = :remote_comment
            @options.remote_name = comment
          end

          opts.on("--github-account ACCOUNT", "[Required] The github account that owns the repository") do |account|
            @options.github_user = account
          end

          opts.on("--repo REPO", "[Required] The github repository to pull from") do |repo|
            @options.github_repo = repo
          end

          opts.on("--base BRANCH", "[Required] The base branch pulls are targeting (default = master)") do |branch|
            @options.branch = branch
          end

          opts.on("--message MESSAGE", "Comment to apply to pull") do |message|
            @options.message = message
          end

          opts.on("--pull NUMBER", Float, "Pull number to comment on") do |number|
            @options.pull_number = number.to_i
          end

          opts.on("--close", "Close pull request") do
            @options.close = true
          end

          opts.on("--merge", "Merge pull request on Github") do
            @options.merge = true
          end

          opts.on("--user NAME", "Your github username") do |user|
            @options.user = user
          end
          
          opts.on("--pass PASSWORD", "Your github password") do |pass|
            @options.pass = pass
          end
          opts.separator "Jenkins:"
          opts.on("--jenkins-add JNAME", "The name of the Jenkins server reference to add") do |jenkins_name|
            @options.command = :jenkins_add
            @options.jenkins_name = jenkins_name
          end

          opts.on("--jenkins-rm JNAME", "The name of the Jenkins server reference to remove") do |jenkins_name|
            @options.command = :jenkins_rm
            @options.jenkins_name = jenkins_name
          end

          opts.on("--server JSERVER", "The jenkins server DSN (default = http://localhost:8080)") do |jenkins_server|
            @options.jenkins_server = jenkins_server
          end

          opts.on("--job JOB", "[Required] The jenkins job name") do |job|
            @options.jenkins_job = job
          end

          opts.on("--token TOKEN", "The jenkins build token") do |token|
            @options.jenkins_token = token
          end

          opts.separator "Connect:"
          opts.on("--attach RNAME", "The Github reference to attach to Jenkins") do |remote_name|
            @options.command = :attach
            @options.remote_name = remote_name
          end

          opts.on("--to JNAME", "Jenkins reference to perform Github builds") do |jenkins_name|
            @options.jenkins_name = jenkins_name
          end

          opts.on("--detach RNAME", "The Github reference to detach from Jenkins") do |remote_name|
            @options.command = :detach
            @options.remote_name = remote_name
          end

          opts.on("--from JNAME", "Jenkins reference to detach from Github pulls") do |jenkins_name|
            @options.jenkins_name = jenkins_name
          end

          opts.separator "Status:"
          # Optional
          opts.on("--status", "Adds a new binding to the server with the name supplied") do
            @options.command = :status
          end

          # Add binding mandentory
          opts.separator ""
          opts.separator "Examples:"
          opts.separator ""
          opts.separator "Github:"
          opts.separator "        jpullr --github-add RNAME --github-account ACCOUNT --repo REPOSITORY --base BRANCH [--user NAME --pass PASSWORD]"
          opts.separator "        jpullr --github-rm RNAME"
          opts.separator "        jpullr --comment-on RNAME --message MESSAGE --pull NUMBER [--close] [--merge]"
          opts.separator ""
          opts.separator "Jenkins:"
          opts.separator "        jpullr --jenkins-add JNAME --server JSERVER --job JOB [--token TOKEN]"
          opts.separator "        jpullr --jenkins-rm JNAME"
          opts.separator ""
          opts.separator "Connect:"
          opts.separator "        jpullr --attach RNAME --to JNAME"
          opts.separator "        jpullr --detach RNAME --from JNAME"
          opts.separator ""
          opts.separator "Status:"
          opts.separator "        jpullr --status"
          opts.separator ""

          opts.on_tail("-h", "--help", "This help dialog") do
            puts opts
            exit
          end

          opts.on_tail("-v", "--version", "Version information") do
            puts "Version #{VERSION.values.join('.')}"
            puts "Written by Sam de Freyssinet. Copyright (c) Sittercity Inc, all rights reserved."
            exit
          end
        end

        opts.parse!(args)

        # if @options.github_user.nil?
        #   puts("Error: --account argument is required")
        #   puts opts
        #   exit JenkinsPullover::CommandLine::ERR_NO_GITHUB_ACCOUNT
        # elsif @options.github_repo.nil?
        #   puts("Error: --repo argument is required")
        #   puts opts
        #   exit JenkinsPullover::CommandLine::ERR_NO_GITHUB_REPO
        # end

      end

      # Runs the main application
      def main
        daemon = JenkinsPullover::Daemon.new(@options)
        daemon.exec
      end
    end
end

# Invoke the application here
app = JenkinsPullover::CommandLine.new
app.parse(ARGV)

app.main
