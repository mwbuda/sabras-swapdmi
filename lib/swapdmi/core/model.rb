
module SwapDmi
	class Model
		extend HasId
		
		attr_reader :contextOfUse
		alias :context :contextOfUse
	
		def initialize(id, context = ContextOfUse.default, sundry = {})
			self.assignId(id)
			@contextOfUse = context
			self.initializeModel(sundry)
		end
		
		def initializeModel(sundry = {})
			#define as neccesary in subclasses
		end
		protected :initializeModel
		
		def config()
			self.contextOfUse.config
		end
		
		def impl(k = :default)
			self.contextOfUse.impl(k)
		end
		
		def impls()
			self.contextOfUse.impls
		end

	end
end
