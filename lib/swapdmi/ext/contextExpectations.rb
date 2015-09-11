


module SwapDmi
	
	
	class DataSource
		def self.expectImpl(*ks,&addl)
			@expectImpl = ks.dup
			@expectImplProc = addl
		end
		
		def self.expectConfig(*ks,&addl)
			@expectCfg = ks.dup
			@expectCfgProc = addl
		end
		
		def checkExpectations()
			#TODO
		end
		
	end
	
	
end





