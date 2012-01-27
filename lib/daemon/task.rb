# Jenkins Pullover Daemon Task

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

require_relative "../github/model"

module JenkinsPullover
  module Daemon

    class Task

      include JenkinsPullover::Util

      attr_accessor :github_model, :jenkins_model, :options

      # Class constructor
      def initialize(opts = {})
        initialize_opts(opts)
      end

      # Report the ready state of the task
      def ready?
        return false if @github_model.nil? || @jenkins_model.nil?

        @github_model.ready? && @jenkins_model.ready?
      end

      # Setter for the github model method
      def github_model=(github_model)
        raise RuntimeError, "Must be instance of github_model" unless
          github_model.kind_of?(JenkinsPullover::Github::Model)

        @github_model = github_model
      end

      # Setter for the jenkins model method
      def jenkins_model=(jenkins_model)
        raise RuntimeError, "Must be instance of jenkins_model" unless
          jenkins_model.kind_of?(JenkinsPullover::Jenkins::Model)

        @jenkins_model = jenkins_model
      end

      # Run task
      def process

      end

    end
    
  end
end