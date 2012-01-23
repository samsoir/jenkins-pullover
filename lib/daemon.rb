# Jenkins Pullover Daemon

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

module JenkinsPullover

  class Daemon

    PID    = 'jenkins-pullover.pid'
    INPROC = "inproc://workers"

    attr_accessor :options, :github, :jenkins

    # Class constructor
    def initialize(options)
      @options = options
    end

    def start
      puts "starting server..."
      daemonize
    end
    
    def stop
      puts "stopping server..."
    end

    # Daemonise the process
    def daemonize
      
      # fork first child process and exit parent
      raise RuntimeError, "Failed to fork first child" if (pid = fork) == -1
      exit unless pid.nil?
      
      # Restablish the session
      Process.setsid
      
      # fork second child process and exit parent
      raise RuntimeError, "Failed to fork second child" if (pid = fork) == -1
      exit unless pid.nil?

      # Write out pid
      File.open(PID, 'w') do |fhandle|
        fhandle.write("#{pid}")
      end

      file_handle = File.open(@options.logfile, 'w')

      # Make safe
      Dir.chdir('/')
      File.umask 0000

      # Reconnect STD/IO
      STDIN.reopen('/dev/null')
      STDOUT.reopen(file_handle, 'a')
      STDERR.reopen(file_handle, 'a')

      STDOUT.sync = true
      STDERR.sync = true

      trap('TERM') {
        $stderr.puts "Shutting down server..."
        exit
      }

      # Create github client
      github_client = JenkinsPullover::Github::Client.new({
        :github_user => @options.github_user,
        :github_repo => @options.github_repo,
        :user        => @options.user,
        :password    => @options.password
      })

      # Create github model
      @github = JenkinsPullover::Github::Model.new({
        :github_client => github_client,
        :debug         => @options.debug,
        :base_branch   => @options.branch
      })

      jenkins_client = JenkinsPullover::Jenkins::Client.new({
         :jenkins_url       => @options.jenkins_url,
         :jenkins_build_key => @options.jenkins_token
      })

      @jenkins = JenkinsPullover::Jenkins::Model.new({
         :jenkins_client    => jenkins_client
      })


      while true
        $stderr.puts "running in background"

        begin
          github_proc(@options)
        rescue => msg
          $stderr.puts "Encountered error:\n#{msg}"
        end

        sleep @options.frequency
      end
    end

    # Github server process
    def github_proc(options)
      $stderr.puts(options.inspect)
      @github.process_pull_requests.each do |pull|

        jenkins_proc(options, pull)
  
        @github.create_comment_for_pull(
            pull[:number],
            JenkinsPullover::Github::Model::JENKINS_PREFIX
        )
        
      end
    end

    # Jenkins server process
    def jenkins_proc(options, pull)
        @jenkins.trigger_build_for_job(options.jenkins_job, {
          :GITHUB_ACCOUNT     => options.github_user,
          :GITHUB_PULL_NUMBER => pull[:number],
          :GITHUB_USERNAME    => options.user
        })
    end
  end
end