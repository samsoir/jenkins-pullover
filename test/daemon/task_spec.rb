# Jenkins Pullover Daemon task test

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

require_relative "../../lib/github/model"
require_relative "../../lib/jenkins/model"
require_relative "../../lib/github/client"
require_relative "../../lib/jenkins/client"
require_relative "../../lib/daemon/task"

describe JenkinsPullover::Daemon::Task do

  it "adds a github model to the task" do
    task = JenkinsPullover::Daemon::Task.new
    github_model = JenkinsPullover::Github::Model.new
    task.github_model = github_model

    task.github_model.should be_instance_of(JenkinsPullover::Github::Model)
    task.github_model.hash.should eq(github_model.hash)
  end

  it "adds a jenkins model to the task" do
    task = JenkinsPullover::Daemon::Task.new
    jenkins_model = JenkinsPullover::Jenkins::Model.new
    task.jenkins_model = jenkins_model

    task.jenkins_model.should be_instance_of(JenkinsPullover::Jenkins::Model)
    task.jenkins_model.hash.should eq(jenkins_model.hash)
  end

  it "raises an ErrorException if adding incorrect objects to github property" do
    task = JenkinsPullover::Daemon::Task.new
    bad_object = Hash.new
    expect {task.github_model = bad_object}.to raise_error(RuntimeError, "Must be instance of github_model")
  
    task.github_model.nil?.should be_true
  end

  it "raises an ErrorException if adding incorrect objects to jenkins property" do
    task = JenkinsPullover::Daemon::Task.new
    bad_object = Hash.new
    expect {task.jenkins_model = bad_object}.to raise_error(RuntimeError, "Must be instance of jenkins_model")
  
    task.jenkins_model.nil?.should be_true
  end

  it "allows only one github model to be assigned" do
    models = {
      :model_a => JenkinsPullover::Github::Model.new,
      :model_b => JenkinsPullover::Github::Model.new
    }

    task = JenkinsPullover::Daemon::Task.new

    models.each do |key, model|
      task.github_model = model
    end

    task.github_model.should be_instance_of(JenkinsPullover::Github::Model)
    task.github_model.hash.should eq(models[:model_b].hash)
  end

  it "allows only one jenkins model to be assigned" do
    models = {
      :model_a => JenkinsPullover::Jenkins::Model.new,
      :model_b => JenkinsPullover::Jenkins::Model.new
    }

    task = JenkinsPullover::Daemon::Task.new

    models.each do |key, model|
      task.jenkins_model = model
    end

    task.jenkins_model.should be_instance_of(JenkinsPullover::Jenkins::Model)
    task.jenkins_model.hash.should eq(models[:model_b].hash)
  end

  it "is not ready with no model" do
    task = JenkinsPullover::Daemon::Task.new
    task.ready?.should be_false
  end

  it "is not ready with one model ready" do
    ready_github_client = double("github_client", {:ready? => true})
    unready_jenkins_client = double("jenkins_client", {:ready? => false})

    task = JenkinsPullover::Daemon::Task.new({
      :jenkins_model => JenkinsPullover::Jenkins::Model.new({
        :jenkins_client => unready_jenkins_client
      }),
      :github_model  => JenkinsPullover::Github::Model.new({
        :github_client => ready_github_client
      })
    })

    task.ready?.should be_false
  end

  it "it not ready with one model missing" do
    ready_github_client = double("github_client", {:ready? => true})

    task = JenkinsPullover::Daemon::Task.new({
      :github_model  => JenkinsPullover::Github::Model.new({
        :github_client => ready_github_client
      })
    })

    task.ready?.should be_false
  end

  it "is ready with two ready models" do
    ready_github_client = double("github_client", {:ready? => true})
    ready_jenkins_client = double("jenkins_client", {:ready? => true})

    task = JenkinsPullover::Daemon::Task.new({
      :jenkins_model => JenkinsPullover::Jenkins::Model.new({
        :jenkins_client => ready_jenkins_client
      }),
      :github_model  => JenkinsPullover::Github::Model.new({
        :github_client => ready_github_client
      })
    })

    task.ready?.should be_true
  end

  it "does not process the task if not ready" do
    task = JenkinsPullover::Daemon::Task.new

    task.process.should be_false
  end

  # it "processes the task" do
  #   ready_github_client = double("github_client", {
  #     :ready?  => true,
  #     :process => nil
  #   })
  #   ready_jenkins_client = double("jenkins_client", {
  #     :ready?  => true,
  #     :process => true
  #   })
  # 
  #   
  # end

end