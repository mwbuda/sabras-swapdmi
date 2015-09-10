

module Test
	
	
	imp1 = SwapDmi::ModelImpl.new(:imp1)
	imp1.define(:a) do |arg|
		config['a'] + arg
	end
	imp1.define(:b) do |arg|
		config['b'] + arg
	end
	
	imp2 = SwapDmi::ModelImpl.new(:imp2)
	imp2.define(:a) do |arg|
		config['a'] * arg
	end
	imp2.define(:b) do |arg|
		config['b'] * arg
	end
	
end






