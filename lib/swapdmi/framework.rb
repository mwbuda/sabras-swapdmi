
#
# various helpful/generic code used to implement the library itself, mostly abstract base classes & helper methods
#	to codify design patterns
#
# things in this file should generally have no bearing on the purpose of the library, they are building blocks
#	to produce the things that do implment the purpose of the library
#
#
#

module SwapDmi

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
		end
		
		module Instance
			attr_reader :id
							
			def assignId(id)
				@id = id
				type = self.class
				instance = self
				type.class_variable_get(:@@onAssignId).each {|behavior| instance.instance_exec(id,&behavior) }
			end
		end
		
	end
	
	#
	# used to create class hierarchies where the root parent tracks
	#	all instnaces of itself & subclasses.
	#	mostly used to provide some form of automated lookup for instances
	#
	module TrackClassHierarchy
		
		def self.extended(base)
			base.extend(SwapDmi::HasId) unless SwapDmi::HasId.extends?(base)
			base.instance_eval { include SwapDmi::TrackClassHierarchy::Instance }
			
			base.class_variable_set(:@@ixs, {})
			base.class_variable_set(:@@masterClass, base)
			base.class_variable_set(:@@defaultIxId, :default)
			
			base.whenAssignIdDo do |id| 
				self.class.trackInstance(self.id, self)
			end
		end
		
		def masterclass()
			self.class_variable_get(:@@masterClass)
		end
		
		def defineDefaultInstance(id)
			cid = id.nil? ? :default : id
			masterclass.class_variable_set(:@@defaultIxId, cid)
		end
		
		def defaultId()
			masterclass.class_variable_get(:@@defaultIxId)
		end
		
		def allInstances()
			self.class_variable_get(:@@ixs) 
		end
		
		def trackInstance(id, instance)
			cleanId = id.nil? ? :default : id
			self.allInstances[id] = instance
		end
		
		def instance(id = nil)
			cleanId = id.nil? ? self.defaultId : id
			instance = self.allInstances[cleanId]
			throw "undefined class instance from hierarchy #{masterclass}: #{cleanId}" if instance.nil?
			instance
		end
		alias :[] :instance
		
		def default()
			self.instance(nil) 
		end
		
		module Instance
			def default?()
				self.id == self.class.defaultId
			end
		end
		
	end
	
	module HasConfig
		def self.extended(base)
			base.extend(SwapDmi::HasId) unless SwapDmi::HasId.extends?(base)
			base.instance_eval { include SwapDmi::HasConfig::Instance }
			base.class_variable_set(:@@config, Hash.new {|h,k| h[k] = Hash.new})
		end
		
		def config(instance = nil)
			configData = self.class_variable_get(:@@config)
			instance.nil? ? configData : configData[instance]
		end
		
		module Instance
			def config()
				self.class.config[self.id]
			end	
		end
	end
	
	class HierarchicalIndex
		
		def initialize()
			@data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
		end
		
		def set(keys, v)
			root = @data
			keys[0..-2].each {|k| root = root[k]}
			root[keys[-1]] = v
		end
		
		def get(ks)
			root = @data
			ks[0..-2].each {|k| root = root[k]}
			root.has_key?(ks[-1]) ? root[ks[-1]] : nil
		end
		
		def [](*ks)
			self.get(ks)
		end
		
		def has?(ks)
			root = @data
			keys[0..-2].each {|k| root = root[k]}
			root.has_key?(keys[-1])
		end
		
	end
	
end







