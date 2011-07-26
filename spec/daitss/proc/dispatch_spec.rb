
require 'daitss/model/request'
require 'daitss/proc/wip'

require 'fileutils'
require 'time'

describe Request do

  let :package do
    sip = Sip.new :name => "mock_sip"
    Package.new :sip => sip, :project => Project.first
  end

  let(:agent) { Agent.first }

  after(:each) { FileUtils.rm_r package.wip.path if package.wip }

  (Wip::VALID_TASKS - [:ingest, :sleep]).each do |t|

    it "should create a wip for #{t}" do
      request = Request.new :package => package, :agent => agent, :type => t
      request.dispatch
      package.wip.should_not be_nil
      package.wip.path.should exist_on_fs
      package.wip.task.should == t
      request.status.should == :released_to_workspace
      request.package.events.last.name.should == "#{t} released"
    end

  end

  it "should not create a wip for d1refreshed packages if the package has already been refreshed " do
    request = Request.new :package => package, :agent => agent, :type => :d1refresh 
    package.log "d1refresh finished"

    request.dispatch.should == nil
    package.wip.should be_nil
    request.status.should_not == :released_to_workspace
    request.package.events.last.name.should_not == "d1refresh released"
  end



end
