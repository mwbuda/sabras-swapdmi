
#
# some basic extension management stuff for the library
#
#
module SwapDmi
	
	class ExtensionHook
		attr_reader :appliesFor, :description
		
		def initialize(desc, *ids, &action)
			@description = desc
			@appliesFor = ids.dup.freeze
			@loaded = false
			@action = action
		end
		
		def signal!(id)
			return false unless @appliesFor.include?(id)
			return false unless SwapDmi.hasExtensions?(*@appliesFor)
			
			begin
				@action.call()
				@loaded = true
			rescue 
				return false
			end
			
			true
		end
		
	end
	
	LoadedExtensions = []
	ExtensionHooks = []
	
	def self.declareExtension(id)
		throw :swapDmiDuplicateExtensionId if SwapDmi.hasExtensions?(id)
		SwapDmi::LoadedExtensions << id.to_s.to_sym
		self
	end
	
	def self.activateExtensionHooks(id)
		SwapDmi::ExtensionHooks.each do |hook|
			next unless hook.appliesFor.include?(id)
			hook.signal!(id)
		end
		self
	end
	
	def self.hasExtensions?(*ids)
		return false if ids.empty?
		ids.reduce(true) {|flag, id| flag and SwapDmi::LoadedExtensions.include?(id.to_s.to_sym)}
	end
	
	def self.addHookForExtension(desc, *ids, &addl)	
		SwapDmi::ExtensionHooks << SwapDmi::ExtensionHook.new(desc, *ids, &addl)
		self
	end
	
end