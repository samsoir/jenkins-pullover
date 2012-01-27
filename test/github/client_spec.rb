# Jenkins Pullover Github Client Rspec Tests

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

require_relative '../../lib/github/client'

describe JenkinsPullover::Github::Client do

  it "parses a json response body into json objects" do

    mock_json = '{"foo": "bar", "number": 2, "bool": true}'

    parsed_json = JenkinsPullover::Github::Client
      .parse_github_json(mock_json)

    
    parsed_json.should be_instance_of(Hash)

    parsed_json[:foo].should eq("bar")
    parsed_json[:number].should eq(2)
    parsed_json[:number].should be_kind_of(Integer)
    parsed_json[:bool].should be_true
    parsed_json[:bool].should be_instance_of(TrueClass)

  end

  it "contains the args passed to initialized" do

    args = {
      :github_user => 'foo', 
      :github_repo => 'bar', 
      :user        => 'fu',
      :password    => 'ba'
    }

    github_client = JenkinsPullover::Github::Client.new args

    args.each do |k,v|

      github_client.instance_variable_get("@#{k}").should eq(v)

    end
  end

  it "returns true if the client is ready" do
    args = {
      :github_user => 'foo',
      :github_repo => 'bar'
    }

    github_client = JenkinsPullover::Github::Client.new args

    github_client.ready?.should be_true
  end

  it "returns false if the client is not ready" do

    github_client = JenkinsPullover::Github::Client.new
    github_client.ready?.should be_false

  end

  it "returns the correctly formated uri with no user" do

    args = {
      :github_user => 'foo',
      :github_repo => 'bar'
    }

    github_client = JenkinsPullover::Github::Client.new args

    github_client.uri_string_for_pull_requests.should eq("#{JenkinsPullover::Github::Client::GITHUB_API_PROTOCOL}#{JenkinsPullover::Github::Client::GITHUB_API_HOST}/repos/#{args[:github_user]}/#{args[:github_repo]}/pulls")

  end


end