# Jenkins Pullover Jenkins Client Rspec Tests

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

require_relative "../../lib/jenkins/client"

describe JenkinsPullover::Jenkins::Client do

  it "correctly reports its ready state with a url supplied" do
    client = JenkinsPullover::Jenkins::Client.new({
      :jenkins_url => 'http://jenkins.local:8080'
    })
    
    client.ready?.should be_true
  end

  it "correctly reports its ready state with no url supplied" do
    client = JenkinsPullover::Jenkins::Client.new({
    })
    
    client.ready?.should be_false
  end

  it "provides the correct URI without a build key" do
    client = JenkinsPullover::Jenkins::Client.new({
      :jenkins_url => 'http://jenkins.local:8080'
    })

    client.uri_for_job('foo').should eq('http://jenkins.local:8080/job/foo/build')
  end

  it "provides the correct URI with a build key" do
    client = JenkinsPullover::Jenkins::Client.new({
      :jenkins_url       => 'http://jenkins.local:8080',
      :jenkins_build_key => 'abcdefGHIKJ12345'
    })

    client.uri_for_job('foo').should eq('http://jenkins.local:8080/job/foo/build?token=abcdefGHIKJ12345')
  end
  
  it "compiles the correct json with supplied build paramters" do
    client = JenkinsPullover::Jenkins::Client.new()

    client.compile_jenkins_json({
      :foo   => "bar",
      :fu    => "baz",
      :no    => "yes"
    }).should eq(
      "{\"parameter\":[{\"name\":\"foo\",\"value\":\"bar\"},{\"name\":\"fu\",\"value\":\"baz\"},{\"name\":\"no\",\"value\":\"yes\"}],\"\":\"\"}"
    )
  end

  it "creates the correct body entity for a paramterized build" do
    client = JenkinsPullover::Jenkins::Client.new()
    
    client.body({
      :foo   => "bar",
      :fu    => "baz",
      :no    => "yes"
    }).should eq "json={\"parameter\":[{\"name\":\"foo\",\"value\":\"bar\"},{\"name\":\"fu\",\"value\":\"baz\"},{\"name\":\"no\",\"value\":\"yes\"}],\"\":\"\"}"
  end

  it "creates the correct body entity for a non-paramterized build" do
    client = JenkinsPullover::Jenkins::Client.new()
    
    client.body().should be_nil
  end

  it "returns a POST http method when there is a valid body entity" do
    client = JenkinsPullover::Jenkins::Client.new()
    body = "foo=bar&baz=boo"
    client.method(body).should eq(:post)
  end

  it "returns a GET http method when there is an empty body" do
    client = JenkinsPullover::Jenkins::Client.new()
    client.method(nil).should eq(:get)
  end

end