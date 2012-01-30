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

  it "correctly reports its unready state with no client" do
    github_model = JenkinsPullover::Github::Model.new

    github_model.ready?.should be_false
  end


  it "correctly reports its ready state with a ready client" do
    github_client = double("JenkinsPullover::Github::Client")
    github_client.stub(:ready?).and_return(true)
    github_client.stub(:nil?).and_return(false)
    github_model = JenkinsPullover::Github::Model.new({
      :github_client  => github_client
    })

    github_model.ready?.should be_true
  end

  it "correctly reports its unready state with client that is not ready" do
    github_client = double("JenkinsPullover::Github::Client")
    github_client.stub(:nil?).and_return(false)
    github_client.stub(:ready?).and_return(false)
    github_model = JenkinsPullover::Github::Model.new({
      :github_client  => github_client
    })

    github_model.ready?.should be_false
  end

  it "correctly filters the pulls that do not match the build base" do

    github_client = double("JenkinsPullover::Github::Client")
    github_client.stub(:pull_request).and_return(
      {:number => 1, :base => {:label => 'foo/bar'}},
      {:number => 2, :base => {:label => 'foo/bar'}},
      {:number => 3, :base => {:label => 'fubar'}}
    )
    github_client.stub(:ready?).and_return(true)

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
    build_comment = 'JenkinsPullover'
    github_client = github_mock_client
    github_client.stub(:comments_for_pull_request).and_return(
      [{:body => "Foobar", :created_at => "2012-01-25T12:00:00Z"}, {:body => "#{build_comment} has scheduled a build", :created_at => "2012-01-25T12:00:03Z"}],
      [{:body => "Foobar", :created_at => "2012-01-25T12:00:00Z"}, {:body => "#{build_comment} has scheduled a build", :created_at => "2012-01-25T12:00:02Z"}, {:body => "Fubar", :created_at => "2012-01-25T12:00:10Z"}],
      [{:body => "Foobar", :created_at => "2012-01-25T12:00:00Z"}],
      [{:body => "Foobar", :created_at => "2012-01-25T12:00:00Z"}, {:body => "Foobar", :created_at => "2012-01-25T12:00:03Z"}, {:body => "Foobar", :created_at => "2012-01-26T10:00:00Z"}, {:body => "Foobar", :created_at => "2012-01-30T18:00:00Z"}],
      [],
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
      :github_client  => github_client,
      :comment_prefix => build_comment
    })

    pulls.each do |pull|
      github_model.build_required(pull).should eq(pull[:result])
    end
  end

  it "creates the correct json to post as a comment" do
    
    messages = [
      {
        :data    => [1, "this is a message"],
        :args    => [1, {:body => "this is a message"}]
      },
      {
        :data    => [2, "this is another message"],
        :args    => [2, {:body => "this is another message"}]
      },
      {
        :data    => [3, "this is a final message"],
        :args    => [3, {:body => "this is a final message"}]
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

  it "creates a SUCCESS message on a good build" do
    comment_prefix = 'TestBuilder'
    build_number   = 12383

    github_model = JenkinsPullover::Github::Model.new({
      :comment_prefix => comment_prefix
    })
    
    github_model.build_result_message(build_number, :success).should eq(
      "#{comment_prefix} build:#{build_number} was a SUCCESS"
    )
  end

  it "creates a FAILURE message on a good build" do
    comment_prefix = 'TestBuilder'
    build_number   = 12383

    github_model = JenkinsPullover::Github::Model.new({
      :comment_prefix => comment_prefix
    })
    
    github_model.build_result_message(build_number, :failed).should eq(
      "#{comment_prefix} build:#{build_number} was a FAILURE"
    )
  end

  it "creates a build started message with build number" do
    comment_prefix = 'TestBuilder'
    build_number   = 12383

    github_model = JenkinsPullover::Github::Model.new({
      :comment_prefix => comment_prefix
    })
    
    github_model.build_started_message(build_number).should eq(
      "#{comment_prefix} has started pull request build:#{build_number}"
    )
  end

  it "creates a build scheduled message" do
    comment_prefix = 'TestBuilder'

    github_model = JenkinsPullover::Github::Model.new({
      :comment_prefix => comment_prefix
    })
    
    github_model.build_scheduled_message.should eq(
      "#{comment_prefix} has scheduled a build"
    )
  end

  it "fails validation for a task with no options" do
    err = {}

    github_model = JenkinsPullover::Github::Model.new({
      :options => {
        :remote_name  => nil,
        :account      => nil,
        :repo         => nil,
        :branch       => nil
      },
      :github_client => github_mock_client
    }).validate_task(err).should be_false

    err.has_key?(:remote_name).should be_true
    err[:remote_name].should eq(:empty)

    err.has_key?(:account).should be_true
    err[:account].should eq(:empty)

    err.has_key?(:repo).should be_true
    err[:repo].should eq(:empty)

    err.has_key?(:branch).should be_true
    err[:branch].should eq(:empty)

  end

  it "passes validation for a task required options supplied" do
    err = {}

    github_model = JenkinsPullover::Github::Model.new({
      :options => {
        :remote_name  => 'foo_repository',
        :account      => 'bar_owner',
        :repo         => 'fubard',
        :branch       => 'master'
      },
      :github_client => github_mock_client
    }).validate_task(err).should be_true

    err.empty?.should be_true
  end

    # github_model = JenkinsPullover::Github::Model.new({
    #   :options => {
    #     :command      => nil,
    #     :remote_name  => nil,
    #     :account      => nil,
    #     :repo         => nil,
    #     :branch       => 'master',
    #     :pull         => nil,
    #     :message      => nil,
    #     :close        => false,
    #     :merge        => false,
    #     :user         => nil,
    #     :password     => nil
    #   },
    #   :github_client => github_mock_client
    # })
    
  # it "is not ready when invalid options are passed to it" do
  #   github_model = JenkinsPullover::Github::Model.new({
  #     :options => {
  #       :command      => nil,
  #       :remote_name  => nil,
  #       :account      => nil,
  #       :repo         => nil,
  #       :branch       => 'master',
  #       :pull         => nil,
  #       :message      => nil,
  #       :close        => false,
  #       :merge        => false,
  #       :user         => nil,
  #       :password     => nil
  #     },
  #     :github_client => github_mock_client
  #   })
  # 
  #   github_model.ready?.should be_false
  # end
end

def github_mock_client
  github_client = double("JenkinsPullover::Github::Client")
  github_client.stub(:ready?).and_return(true)
  github_client
end