
module Test

	class TestDataSource < SwapDmi::DataSource
		def initializeModel(sundry = {})
			@objs = Hash.new {|h,k| h[k] = TestObject.new(:id => k)}
		end

		def [](id)
			@objs[id]
		end
	end

	class TestObject < SwapDmi::Model
		def initializeModel(sundry = {})
			@id = sundry[:id]
		end

		def action!(arg)
			self.logic[:test, :action].call(arg)
		end
	end

end
