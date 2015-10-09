
module Test

	class TestModel < SwapDmi::Model
		def a()
			impls[:a][:a].call(config['a'])
		end
		
		def b()
			impls[:b][:b].call(config['b'])
		end
	end
	
	class TestDataSource < SwapDmi::SmartDataSource
		defineDefaultModelType TestModel
		fetchResolvesNil
	end

end
