
module SwapDmi
	
	#
	# used to create class hierarchies where the root parent tracks
	#	all instnaces of itself & subclasses.
	#	mostly used to provide some form of automated lookup for instances
	#
	module TrackClassHierarchy
		
		DefaultDefaultInstanceId = :default
		
		def self.extended(base)
			base.extend(SwapDmi::HasId) unless SwapDmi::HasId.extends?(base)
			base.instance_eval { include SwapDmi::TrackClassHierarchy::Instance }
				
			base.class_variable_set(:@@ixs, {})
			base.class_variable_set(:@@masterClass, base)
			base.class_variable_set(:@@defaultIxId, :default)
			base.class_variable_set(:@@preventIxIdOverwrite, false)
			
			base.whenAssignIdDo do |id| 
				if self.class.preventInstanceIdOverwrite? and self.class.hasInstance?(id)
					throw "TrackClassHierarchy Duplicate Id Error: #{id} in #{self.class.masterclass}"
				end
				self.class.trackInstance(self.id, self)
			end
		end
		
		def masterclass()
			self.class_variable_get(:@@masterClass)
		end
		
		def preventInstanceIdOverwrite?()
			self.class_variable_get(:@@preventIxIdOverwrite)
		end
		
		def preventInstanceIdOverwrite(prevent = true)
			self.class_variable_set(:@@preventIxIdOverwrite, prevent)
			self
		end
		
		def defineDefaultInstance(id)
			cid = id.nil? ? :default : SwapDmi.idValue(id)
			masterclass.class_variable_set(:@@defaultIxId, cid)
		end
		
		def defaultId()
			masterclass.class_variable_get(:@@defaultIxId)
		end
		
		def allInstances()
			self.class_variable_get(:@@ixs) 
		end
		
		def trackInstance(id, instance)
			cleanId = id.nil? ? :default : SwapDmi.idValue(id)
			self.allInstances[cleanId] = instance
		end
		alias :[]= :trackInstance
		
		def instance(id = self.defaultId)
			cleanId = id.nil? ? self.defaultId : SwapDmi.idValue(id)
			instance = self.allInstances[cleanId]
			#throw "undefined class instance from hierarchy #{masterclass}: #{cleanId}" if instance.nil?
			instance
		end
		alias :[] :instance
		
		def default()
			self.instance(self.defaultId) 
		end
		
		def hasInstance?(id = self.defaultId)
			instance = self.allInstances[SwapDmi.idValue(id)]
			!instance.nil?
		end
		
		def hasDefault?()
			self.hasInstance?(self.defaultId)
		end
		
		module Instance
			def default?()
				self.id == self.class.defaultId
			end
		end
		
	end
	
end

