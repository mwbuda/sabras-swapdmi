
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
			@isReady = false
		end
		
		def defineOnReady(&ready)
			@readyLogic = ready
		end
		
		def ready!()
			return self if @isReady
			self.preReady()
			self.instance_exec(&@readyLogic) unless @readyLogic.nil?
			self.postReady()
			@isReady = true
			self
		end
		
		#hard-coded behavior called BEFORE configured ready logic
		def preReady()
			#does nothing. extend in subclasses
		end
		
		#hard-coded behavior called AFTER configured ready logic
		def postReady()
			#does nothing. extend in subclasses
		end
		
		def define(*keys, &logic)
			recv = self
			xlogic = Proc.new {|*args| recv.instance_exec(*args,&logic) }
			@logics.set(keys,xlogic)
			self
		end
		
		def defines?(*keys)
			@logics.has?(*keys)
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