
module SwapDmi
	
	DefaultMissingLogic = Proc.new {|modelLogic,*keys| throw :undefinedModelLogic }
		
	#TODO: error handling
	class ModelImpl
		extend TrackClassHierarchy
		extend HasConfig
		
		defineDefaultInstance(:unnamed)
		
		def initialize(id = :unnamed)
			self.assignId(id)
			@logics = HierarchicalIndex.new
			@missingLogic = DefaultMissingLogic
		end
		
		def define(*keys, &logic)
			recv = self
			xlogic = Proc.new {|*args| recv.instance_exec(*args,&logic) }
			@logics.set(keys,xlogic)
			self
		end
		
		def defines?(*keys)
			@logics.has?(keys)
		end
		
		def defineMissing(&logic)
			@missingLogic = logic
			self
		end
		
		def [](*keys)
			logic = @logics[*keys]
			@missingLogic.call(self,*keys) if logic.nil?
			logic
		end
	  
	end
	
	DefaultModelImpl = SwapDmi::ModelImpl.new
	
	
	
end