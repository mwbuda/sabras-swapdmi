module SwapDmi
	
	def self.idValue(rawid)
		if rawid.class.isSwapDmiId?
			rawid
		else
			rawid.to_s.to_sym
		end
	end
	
	module IdType
		def isSwapDmiId?()
			true
		end
	end
	
	module HasId
		
		def self.extends?(type)
		 	return false unless type.respond_to?(:whenAssignIdDo)
		 	return false unless type.instance_methods.include?(:id)
			return false unless type.instance_methods.include?(:assignId)
		 	true
		end
		
		def self.extended(base)
			base.class_variable_set(:@@onAssignId, [])
			base.instance_eval { include SwapDmi::HasId::Instance }
		end
		
		def whenAssignIdDo(&behavior)
			self.class_variable_get(:@@onAssignId) << behavior
			self
		end
		
		module Instance
			attr_reader :id
							
			def assignId(id)
				@id = SwapDmi.idValue(id)
				type = self.class
				instance = self
				type.class_variable_get(:@@onAssignId).each {|behavior| instance.instance_exec(@id,&behavior) }
			end
		end
		
	end
	
end

class Module
	def isSwapDmiId?()
		false
	end
	
	def self.isSwapDmiId?()
		true
	end
end

class Symbol
	extend SwapDmi::IdType
end

class Numeric
	extend SwapDmi::IdType
end

class NilClass
	extend SwapDmi::IdType 
end
