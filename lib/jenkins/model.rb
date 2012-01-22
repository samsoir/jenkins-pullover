# Jenkins Pullover Jenkins Model

# Author::    Sam de Freyssinet (sam@def.reyssi.net)
# Copyright:: Copyright (c) 2012 Sittercity, Inc. All Rights Reserved. 
# License::   ISC License
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

# Provides methods and business logic for working with JenkinsPullover

require_relative '../util'

module JenkinsPullover
  module Jenkins
   
   class Model

     include JenkinsPullover::Util

     attr_accessor :jenkins_client

     # Class constructor
     def initialize(opts = {})
       initialize_opts(opts)
     end

     # Triggers a scheduled build for the job supplied
     def trigger_build_for_job(job, params = {})
       raise RuntimeError,
        "No Jenkins client is available" if @jenkins_client.nil?

       raise RuntimeError,
        "Jenkins client is not ready" unless @jenkins_client.ready

       response = @jenkins_client.trigger_build_for_job

       # HTTP 302 is success(??) message
       # anything else should be considered an error
       unless response.instance_of?(HTTPFound)
         raise RuntimeError,
          "Jenkins responded with Error Message:\n#{response.body}"
       end
       
       response
     end

   end
    
  end
end