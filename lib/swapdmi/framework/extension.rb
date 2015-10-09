
#
# some basic extension management stuff for the library
#
#
module SwapDmi
	
	LoadedExtensions = []
	
	def self.declareExtension(id)
		throw :swapDmiDuplicateExtensionId if SwapDmi.hasExtensions?(id)
		SwapDmi::LoadedExtensions << id.to_s.to_sym
	end
	
	def self.hasExtensions?(*ids)
		return false if ids.empty?
		ids.reduce(true) {|flag, id| flag and SwapDmi::LoadedExtensions.include?(id.to_s.to_sym)}
	end
	
end