
#
# implements marshalling integration for data model objects
#
#
module SwapDmi
	SwapDmi.declareExtension(:modelMarshal)
	
	def self.marshal(raw)
		cooked = case data
			when SwapDmi::Model
				data.marshal
			when Array
				v2 = []
				data.each { |sv| v2 << self.marshal(sv) }
				v2
			when Hash
				v2 = {}
				data.each { |k,sv| v2[k] = self.marshal(sv) }
			else data 
		end
		Marshal::dump(cooked)
	end
	
	def self.unmarshal(marshalled)
		loaded = Marshal::Load(marshalled)
		self.parseUnMarshalled(loaded)
	end
	
	def self.parseMarshalData(loaded)
		case loaded
			when SwapDmi::PickledModel
				mclass = loaded.modelClass
				mclass.unmarshal(loaded)
			when Array
				v2 = []
				loaded.each { |sv| v2 << self.parseMarshalData(sv) }
				v2
			when Hash
				v2 = {}
				loaded.each { |k,sv| v2[k] = self.parseMarshalData(sv) }
				v2
			else loaded 
		end
	end
	
	class Model
		
		def self.unmarshal(pickle)
			m = self.new(pickle.id, ContextOfUse[pickle.contextOfUse], pickle.sundry)
			
			m.instance_exec(pickle) do |ser|
			ser.fields.each do |k,v|
				vx = self.class.unmarshalFieldValue(v)
				self.instance_variable_set("@#{k}".to_sym, vx)
			end end
			
			addlUnmarshal = self.additionalUnMarshallingProc
			m.instance_exec(pickle, &addlUnmarshal) unless addlUnmarshal.nil?
			m
		end
		
		def marshal()
			fields = {}
			self.instance_variables.each do |field|
				next if field == :@contextOfUse
				next if field == :@id
				v = self.instance_variable_get(field)
				next if self.omitMarshalFieldValue?(v)
				v = self.marshalFieldValue(v)
				fk = field.to_s[1,-1].to_sym
				fields[fk] = v
			end
			
			pickle = PickledModel.new(self.class, self.id, self.context.id, fields)
			addlMarshal = self.class.additionalMarshallingProc
			self.instance_exec(pickle, &addlMarshal) unless addlMarshal.nil?
			pickle
		end
		
		def self.unmarshalFieldValue(rawv)
			if rawv.is_a?(SwapDmi::PickledModel)
					mclass = rawv.modelClass
					return mclass.unmarshal(rawv)
			end
			
			if rawv.is_a?(Array)
				v2 = []
				rawv.each { |sv| v2 << self.unmarshalFieldValue(sv) }
				return v2
			end
			
			if rawv.is_a?(Hash)
				v2 = {}
				rawv.each { |k,sv| v2[k] = self.unmarshalFieldValue(sv) }
				return v2
			end
			
			rawv
		end

		def omitMarshalFieldValue?(v)
			omitTypes = [Proc, Method, IO, Binding]
			omit = false
			omitTypes.each do |omitType| 
				omit = v.is_a?(omitType)
				break if omit
			end 
			omit
		end

		def marshalFieldValue(v)
			return v.marshal if v.is_a?(SwapDmi::Model)
			
			if v.is_a?(Array)
				v2 = []
				v.each do |sv| 
					next if self.omitMarshalFieldValue?(sv)
					v2 << self.marshalFieldValue(sv)
				end
				return v2
			end
			
			if v.is_a?(Hash)
				v2 = {}
				v.each do |k,sv|
					next if self.omitMarshalFieldValue?(sv)
					v2[k] = self.marshalFieldValue(sv) 
				end
				return v2
			end
			
			v
		end
	
	end
	
	
	class PickledModel
	
		attr_reader :modelClass, :id, :contextOfUse, :sundry, :fields
		
		def initialize(mclass, id, context, fields = {}, sundry = {})
			@modelClass = mclass.to_s
			@id = id
			@contextOfUse = context
			
			@fields = {}
			@fields.merge!(fields) unless fields.nil?
			
			@sundry = {}
			@sundry.merge!(sundry) unless sundry.nil?
		end   

		def modelClass()
			@modelClass.split('::').inject(Object) do |mod, cname|
				mod.const_get(cname)
			end
		end
		
	end
	
end

SwapDmi.activateExtensionHooks(:modelMarshal)
