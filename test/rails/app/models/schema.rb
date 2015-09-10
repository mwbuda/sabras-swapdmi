
module Test

	class TestModel < SwapDmi::Model
		def a()
			impl[:a].call(config['a'])
		end
		
		def b()
			impl[:b].call(config['b'])
		end
	end
	
	class TestDataSource < SwapDmi::DataSource
		defineDefaultModelType TestModel
		fetchResolvesNil
	end

end
