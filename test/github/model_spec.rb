# Jenkins Pullover Github Model Rspec Tests

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

require_relative '../../lib/github/model'

describe JenkinsPullover::Github::Model do

  it "parses a json response body into json objects" do

    mock_json = '{"foo": "bar", "number": 2, "bool": true}'

    parsed_json = JenkinsPullover::Github::Model
      .parse_github_json(mock_json)

    
    parsed_json.should be_instance_of(Hash)

    parsed_json[:foo].should eq("bar")
    parsed_json[:number].should eq(2)
    parsed_json[:number].should be_kind_of(Integer)
    parsed_json[:bool].should be_true
    parsed_json[:bool].should be_instance_of(TrueClass)

  end

  it "correctly filters the pulls that do not match the build base" do

    github_client = double("JenkinsPullover::Github::Client")
    github_client.stub(:pull_request).and_return(
      "{\"number\": 1, \"base\": {\"label\": \"foo/bar\"}}",
      "{\"number\": 2, \"base\": {\"label\": \"foo/bar\"}}",
      "{\"number\": 3, \"base\": {\"label\": \"fubar\"}}"
    )

    github_model = JenkinsPullover::Github::Model.new({
      :base_branch   => 'foo/bar', 
      :github_client => github_client
    })
    
    pulls = [
      {
        :number => 1, 
        :result => true
      },
      {
        :number => 2, 
        :result => true
      },
      {
        :number => 3, 
        :result => false
      }
    ]
    
    pulls.each do |pull|
      github_model.check_pull_base_branch(pull).should eq(pull[:result])
    end
  end

  it "identifies if a build is required from the pull request" do

    build_comment = 'JenkinsPullover Build Initiated'

    github_client = double("JenkinsPullover::Github::Client")
    github_client.stub(:comments_for_pull_request).and_return(
      "[{\"body\": \"Foobar\", \"created_at\": \"2012-01-25T12:00:00Z\"}, {\"body\": \"#{build_comment}\", \"created_at\": \"2012-01-25T12:00:03Z\"}]",
      "[{\"body\": \"Foobar\", \"created_at\": \"2012-01-25T12:00:00Z\"}, {\"body\": \"#{build_comment}\", \"created_at\": \"2012-01-25T12:00:02Z\"}, {\"body\": \"Fubar\", \"created_at\": \"2012-01-25T12:00:10Z\"}]",
      "[{\"body\": \"Foobar\", \"created_at\": \"2012-01-25T12:00:00Z\"}]",
      "[{\"body\": \"Foobar\", \"created_at\": \"2012-01-25T12:00:00Z\"}, {\"body\": \"Foobar\", \"created_at\": \"2012-01-25T12:00:03Z\"}, {\"body\": \"Foobar\", \"created_at\": \"2012-01-26T10:00:00Z\"}, {\"body\": \"Foobar\", \"created_at\": \"2012-01-30T18:00:00Z\"}]",
      "[]",
    )

    pulls = [
      {
        :number     => 1,
        :updated_at => "2012-01-25T12:00:01Z",
        :merged     => false,
        :mergable   => true,
        :result     => false
      },
      {
        :number     => 2,
        :updated_at => "2012-01-25T12:10:01Z",
        :merged     => false,
        :mergable   => true,
        :result     => true
      },
      {
        :number     => 3,
        :updated_at => "2012-01-25T12:00:01Z",
        :merged     => false,
        :mergable   => true,
        :result     => true
      },
      {
        :number     => 4,
        :updated_at => "2012-02-03T11:03:01Z",
        :merged     => false,
        :mergable   => true,
        :result     => true
      },
      {
        :number     => 5,
        :updated_at => "2013-05-25T15:00:01Z",
        :merged     => false,
        :mergable   => true,
        :result     => true
      },
      {
        :number     => 6,
        :updated_at => "2013-05-25T15:00:01Z",
        :merged     => true,
        :mergable   => true,
        :result     => false
      },
      {
        :number     => 7,
        :updated_at => "2013-05-25T15:00:01Z",
        :merged     => false,
        :mergable   => false,
        :result     => false
      },
    ]

    github_model = JenkinsPullover::Github::Model.new({
      :github_client  => github_client
    })

    pulls.each do |pull|
      github_model.build_required(pull).should eq(pull[:result])
    end
  end

  it "creates the correct json to post as a comment" do
    
    messages = [
      {
        :data    => [1, "this is a message"],
        :args    => [1, "{\"body\":\"this is a message\"}"]
      },
      {
        :data    => [2, "this is another message"],
        :args    => [2, "{\"body\":\"this is another message\"}"]
      },
      {
        :data    => [3, "this is a final message"],
        :args    => [3, "{\"body\":\"this is a final message\"}"]
      }
    ]

    messages.each do |message|
      github_client = double("JenkinsPullover::Github::Client")
      github_client.should_receive(:create_comment_for_pull).with(*message[:args])

      github_model = JenkinsPullover::Github::Model.new({
        :github_client  => github_client
      })

      github_model.create_comment_for_pull(*message[:data])
    end
    
  end

end