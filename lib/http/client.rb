# Jenkins Pullover HTTP Client

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

# This module provides basic HTTP methods for all HTTP clients

module JenkinsPullover
  module HTTP
    module Client

      # Executes a HTTP request by method and URI
      def execute_http_request(method, uri, body = nil)
        resp = Net::HTTP.start(
          uri.host,
          uri.port,
          :use_ssl => uri.scheme == "https"
        ) do |http|
          case method
            when :get
              request = Net::HTTP::Get.new uri.request_uri
            when :post
              request = Net::HTTP::Post.new uri.request_uri
            when :put
              request = Net::HTTP::Put.new uri.request_uri
            when :delete
              request Net::HTTP::Delete.new uri.request_uri
          end
          request.body = body unless body.nil?
          request.basic_auth @user, @password unless @user.nil?
          http.request request
        end
      end

    end
  end
end