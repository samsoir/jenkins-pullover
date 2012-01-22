# Jenkins Pullover Github Client

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

# This class provides the basic HTTP interface to Github API, providing a
# simple set of methods for interacting with Pull requests

require 'net/http'
require_relative '../util'
require_relative '../http/client'

module JenkinsPullover
  module Github
    class Client

        include JenkinsPullover::Util, JenkinsPullover::HTTP::Client

        GITHUB_API_PROTOCOL = 'https://'
        GITHUB_API_HOST     = 'api.github.com'

        attr_accessor :user, :password, :github_user, :github_repo
        attr_writer :debug

        # Class constructor
        def initialize(opts = {})
          initialize_opts(opts)
        end

        # Client ready
        def ready
          @github_user && @github_repo
        end

        # Provides a hash of URI components
        def uri_parts(uri)
          uri_parts = {
            :protocol => JenkinsPullover::Github::Client::GITHUB_API_PROTOCOL,
            :host     => JenkinsPullover::Github::Client::GITHUB_API_HOST,
            :uri      => uri
          }
        end

        # Compiles the correct Github comment on pull URI string
        def uri_string_for_comments_on_pull(id)
          uri_parts(
            "/repos/#{@github_user}/#{@github_repo}/issues/#{id}/comments"
          ).values.join
        end

        # Compiles the the correct Github pull request URI string
        def uri_string_for_pull_requests
          uri_parts("/repos/#{@github_user}/#{@github_repo}/pulls").values.join
        end

        # Compiles the correct Github pull request URI string for id
        def uri_string_for_pull(id)
          uri_parts(
            "/repos/#{@github_user}/#{@github_repo}/pulls/#{id}"
          ).values.join
        end

        # Compiles the correct Github pull comment URI string
        def uri_comment_on_pull(id)
          uri_parts(
            "/repos/#{@github_user}/#{@github_repo}/issues/#{id}/comments"
          ).values.join
        end

        # Loads Pull Requests from Github
        def pull_requests
          uri = URI(uri_string_for_pull_requests)
          execute_http_request(:get, uri).body
        end

        # Loads the fall Pull request
        def pull_request(id)
          uri = URI(uri_string_for_pull(id))
          execute_http_request(:get, uri).body
        end

        # Loads Comments for Pull Request from Github
        def comments_for_pull_request(id)
          uri = URI(uri_string_for_comments_on_pull(id))
          execute_http_request(:get, uri).body
        end

        # Creates a comment on the Pull Request on Github
        # :comment must contain a json body
        def create_comment_for_pull(id, comment)
          uri = URI(uri_comment_on_pull(id))
          execute_http_request(:post, uri, comment)
        end

    end
  end
end