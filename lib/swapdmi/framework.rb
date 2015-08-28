
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

	#
	# used to create class hierarchies where the root parent tracks
	#	all instnaces of itself & subclasses.
	#	mostly used to provide some form of automated lookup for instances
	#
	def self.track_class_hierarchy(klass)
		klass.class_variable_set(:@@ixs, {})
		klass.class_variable_set(:@@masterClass, klass)
		klass.class_variable_set(:@@defaultIxId, :default)
		
		klass.instance_eval do 
			attr_reader :id
			
			def self.masterclass()
				self.class_variable_get(:@@masterClass)
			end
			
			def self.defineDefaultInstance(id)
				masterclass.class_variable_set(:@@defaultIxId, id.nil? ? :default : id)
			end
			
			def self.allInstances()
				self.class_variable_get(:@@ixs) 
			end
			
			def self.trackInstance(id, instance)
				cleanId = id.nil? ? :default : id
				self.allInstances[id] = instance
			end
			
			def self.instance(id = nil)
				cleanId = id.nil? ? masterclass.class_variable_set(:@@defaultIxId, :default) : id
				instance = self.allInstances[cleanId]
				throw "undefined class instance from hierarchy #{masterclass}: #{cleanId}" if instance.nil?
				instance
			end
			
			def self.[](id)
				self.instance(id) 
			end
			
			def self.default()
				self.instance(nil) 
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
			keys[0..-2].each {|k| root = root[k]}
			root.has_key?(keys[-1]) ? root[keys[-1]] : nil
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







