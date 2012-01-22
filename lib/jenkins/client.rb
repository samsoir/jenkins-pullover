# Jenkins Pullover Jenkins Model

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

# Class providing HTTP interaction with Jenkins remote trigger server

require 'net/http'
require 'uri'
require "json"
require_relative '../util'
require_relative '../http/client'

module JenkinsPullover
  module Jenkins
   
   class Client

     include JenkinsPullover::Util, JenkinsPullover::HTTP::Client

     JENKINS_URI = "/job/%{job_name}/build"

     attr_accessor :jenkins_url, :jenkins_build_key

     # Class constructor
     def initialize(opts = {})
       initialize_opts(opts)
     end

     # Returns if the client is ready
     def ready
       @jenkins_url.nil? == false
     end

     # Create the URI for job
     def uri_for_job(job)
       uri = @jenkins_url + JENKINS_URI % {:job_name => job}

       uri += "?token=#{@jenkins_build_key}" unless @jenkins_build_key.nil?
       
       uri
     end

     # Triggers Jenkins to begin a build using remote trigger URI
     def trigger_build_for_job(job, params = {})
       uri = URI(uri_for_job(job))
       
       body = nil

       if params.size > 0
         method = :post
         body = compile_jenkins_json(params)
       else
         method = :get
       end
# URI.escape(foo, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
       execute_http_request(method, uri, body)
     end
     # Compiles the json required by Jenkins API
     def compile_jenkins_json(params)
       buffer = []
  
       params.each do |key, value|
         buffer << "{\"name\": \"#{key}\", \"value\": \"#{value}\"}"
       end
  
       "json={\"parameter\": [#{buffer.join(', ')}], \"\": \"\"}"
     end
    end
 end
end