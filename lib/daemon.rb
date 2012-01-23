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

    PID = '/var/run/jenkins-pullover.pid'

    attr_accessor :options

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

      # Make safe
      Dir.chdir('/')
      File.umask 0000

      STDIN.reopen('/dev/null')
      STDOUT.reopen(@options.logfile, 'a')
      STDERR.reopen(@options.logfile, 'a')

      trap('TERM') {
        exit
      }


      puts "Ran daemon..."
    end

  end

end