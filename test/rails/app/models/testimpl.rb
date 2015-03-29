

module Test

	TestModelLogic = SwapDmi::ModelLogic.new(:test)
	TestModelLogic.defineSessionTracking {|session| session}
	
	TestModelLogic.define(:test, :action) do |arg|
		puts arg
	end
end






