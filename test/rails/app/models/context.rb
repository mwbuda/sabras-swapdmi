


module Test
	
	cxt1 = SwapDmi::ContextOfUse.new(:cxt1)
	cxt1.defineDataSource(Test::TestDataSource)
	
	cxt2 = SwapDmi::ContextOfUse.new(:cxt2)
	cxt2.defineDataSource(Test::TestDataSource)
	
end


