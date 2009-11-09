Given /^I submit (a|another) package$/ do |article|
  sip = test_sip_by_name('ateam')
  bin "submit #{sip}"  
  @aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
end

Given /^aip\-0 is one of them$/ do
  aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"].map { |p| File.basename p }
  aips.should include("aip-0")
end

When /^I type "([^\"]*)"$/ do |command|
  @last_output = bin "#{command}"
end

Then /^the list should have (\d+) aips?$/ do |size|
  @last_output.lines.map.size.should == size.to_i
end


Then /^(they|it) (should|should not) be in the list$/ do |cardinality, condition|
  state = @last_output.lines.map { |line| line.chomp.split.first }
  
  subject = case cardinality
            when "they" then @aips
            when "it" then [@aips.first]
            end

  case condition
  when "should"
    state.should include(*subject)
  when "should not"
    state.should_not include(*subject)
  end

end

def bin command
  output = %x{ruby -Ilib bin/#{command}}
  $?.should == 0
  output
end