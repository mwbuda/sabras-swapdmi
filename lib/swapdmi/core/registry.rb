

module SwapDmi
	
	#simple key/value stores in a tracked class hierarchy
	#	typically used to provide TrackClassHierarchy like behavior for pre-existing types
	#	which do not extend the SwapDmi module
	#	(canonical example being loggers thru the base install logging extension)
	class Registry
		extend TrackClassHierarchy
		preventInstanceIdOverwrite
		
		attr_accessor :defaultId
		
		def initialize(id)
			assignId(id)
			@registry = {}
		end
		
		def defineDefaultInstance(id)
			self.defaultId = id
			self
		end
		
		def register(id, logger)
			@registry[SwapDmi.idValue(id)] = logger
			self
		end
		
		def []=(id,logger)
			self.register(id, logger)
			logger
		end
		
		def [](id)
			@registry[SwapDmi.idValue(id)]
		end
		
		def default()
			self[self.defaultId]
		end
		
		def has?(id = self.defaultId)
			@registry.keys.include?(SwapDmi.idValue(id))
		end
	end
	
end

