# Jenkins Pullover Daemon test

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

require_relative "../../lib/daemon/server.rb"
require_relative "../../lib/daemon/task.rb"

describe JenkinsPullover::Daemon::Server do

  it "adds tasks to the daemon" do
    daemon = JenkinsPullover::Daemon::Server.new({})

    daemon.tasks.empty?.should be_true

    daemon.add_task JenkinsPullover::Daemon::Task.new
    daemon.tasks.empty?.should be_false
    daemon.tasks.size.should eq(1)
  end

  it "raises an error if task is not a real task" do
    daemon = JenkinsPullover::Daemon::Server.new({})

    expect { daemon.add_task({}) }.to raise_error(RuntimeError, "you can only add real tasks")
  end

  it "removes a task from the daemon by a unique task" do
    daemon = JenkinsPullover::Daemon::Server.new({})
    tasks = {
      :task_a => JenkinsPullover::Daemon::Task.new,
      :task_b => JenkinsPullover::Daemon::Task.new
    }

    tasks.each do |key, task|
      daemon.add_task(task)
    end

    daemon.remove_task(tasks[:task_a])
    daemon.tasks.has_key?(tasks[:task_a]).should be_false
  end

  it "clears all tasks from the daemon when reset" do
    
  end

end 