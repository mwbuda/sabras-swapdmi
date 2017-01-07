
require 'json'

#
# implements marshalling integration for data model objects
#
#
module SwapDmi
	SwapDmi.declareExtension(:modelMarshal)
	
	class ModelMarshalFinalizer
		def self.instance()
			@instance = self.new if @instance.nil?
			@instance
		end
		def initialize(&b)
			@block = b
		end
		def finalize(x)
			@block.call(x)
		end
	end
	
	class ModelMarshalReader
		def self.instance()
			@instance = self.new if @instance.nil?
			@instance
		end
		def initialize(&b)
			@block = b
		end
		def read(x)
			@block.call(x)
		end
	end
	
	module MarshalMarshalling
		class Finalizer < SwapDmi::ModelMarshalFinalizer
			def finalize(x)
				Marshal::dump(x)
			end
		end
		
		class Reader < SwapDmi::ModelMarshalReader
			def read(x)
				Marshal::load(x)
			end
		end
	end
	
	#
	# In order to distinguish b/w symbols and strings, most text is prefaced with a header code, 
	# 	consisting of '\c1<xx>\c2' where xx is a 2 digit numeric code indicating data type
	# For custom objects which do not extend SwapDmi::Model (or, by time in this encoder SwapDmi::PickledModel)
	# 		this encoding will not take place, 
	#			as the marshalling does will not know how to introspect the object 
	# The behavior can be obtained by translating the object to a raw array/hash. 
	# 	Note that you will probably have to accomodate this anyway, since JSON encoding doesn't handle class type
	# Note also that this encoding does not take place for PickledModel modelClass, id, & context attribs
	# 	as we know what those are, and the class's internal id handling eats raw strings nicely
	#
	# 	00: string
	# 	01: symbol
	#
	module JsonMarshalling
		
		def self.txtenc(t)
			case t
				when String then "\c100\c2#{t}"
				when Symbol then "\c101\c2#{t}"
				else t
			end
		end
		
		def self.txtdec(t)
			return t unless t.is_a? String
			m = /^\c1(\d\d)\c2(.*)$/ =~ t
			return t unless m
			case $1.to_i
				when 00 then $2
				when 01 then $2.to_sym
			end
		end
		
		class Finalizer < SwapDmi::ModelMarshalFinalizer
			def subproc(x)
				case x
					when Array
						v2 = []
						x.each {|sv| v2 << self.subproc(sv)}
						v2
					when Hash
						v2 = {}
						x.each do |k,sv| 
							kx = SwapDmi::JsonMarshalling.txtenc(k)
							v2[kx] = self.subproc(sv)
						end
						v2
					when SwapDmi::PickledModel
						{
							'_swapdmi' => true,
							'id' => x.id, 'mc' => x.modelClassName, 'cxt' => x.contextOfUse,
							'sx' => self.subproc(x.sundry), 'fs' => self.subproc(x.fields),
						}
					else
						SwapDmi::JsonMarshalling.txtenc(x)
				end
			end
			
			def finalize(x)
				JSON.dump({'data' => self.subproc(x)})
			end
		end
		
		class Reader < SwapDmi::ModelMarshalReader
			def parse(x)
				case x
					when Array
						v2 = []
						x.each {|sv| v2 << self.parse(sv) }
						v2
					when Hash then if x['_swapdmi']
							SwapDmi::PickledModel.new(
								x['mc'], x['id'], x['cxt'],
								self.parse(x['fs']),
								self.parse(x['sx']),
							)
					else
						v2 = {}
						x.each do |rk,sv|
							k = SwapDmi::JsonMarshalling.txtdec(rk) 
							v2[k] = self.parse(sv)
						end
						v2
					end
					else
						SwapDmi::JsonMarshalling.txtdec(x) 
				end
			end
			
			def read(x)
				self.parse( JSON.parse(x)['data'] )
			end
		end
	end
	
	def self.marshal(raw, fc = nil, &fb)
		fi =  00
		fi += 01 if fc.nil?
		fi += 10 if fb.nil?
		
		finalizer = case fi
			when 00 then fc.new(&fb)
			when 01 then SwapDmi::ModelMarshalFinalizer.new(&fb)
			when 10 then fc.instance
			when 11 then SwapDmi::MarshalMarshalling::Finalizer.instance
		end

		cooked = self.prepareMarshalData
		finalizer.finalize(cooked)
	end
	
	def self.prepareMarshalData(raw)
		case raw
			when SwapDmi::Model
				raw.marshal
			when Array
				v2 = []
				raw.each { |sv| v2 << self.prepareMarshalData(sv) }
				v2
			when Hash
				v2 = {}
				raw.each { |k,sv| v2[k] = self.prepareMarshalData(sv) }
			else raw 
		end
	end
	
	def self.unmarshal(marshalled, rc = nil, &rb)
		ri =  00
		ri += 01 if rc.nil?
		ri += 10 if rb.nil?
		
		reader = case ri
			when 00 then rc.new(&rb)
			when 01 then SwapDmi::ModelMarshalReader.new(&rb)
			when 10 then rc.instance
			when 11 then SwapDmi::MarshalMarshalling::Reader.instance
		end
		
		loaded = reader.read(marshalled)
		self.parseMarshalData(loaded)
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
		
		def self.initMarshalExclusions()
			return unless @marshalExclusions.nil?
			@marshalExclusions = [:@id, :@contextOfUse]
			@marshalExcClean = false
		end
		
		def self.excludeMarshalField(field)
			self.initMarshalExclude
			cfield = field.to_s.start_with?('@') ? field.to_sym : "@#{field}".to_sym
			@marshalExclusions << cfield
			@marshalExcClean = false
			self
		end
		
		def self.marshalExclusions()
			self.initMarshalExclusions
			return @marshalExclusions.dup if @marshalExcClean
			
			#tarverse class hierachy to get all excluded fields
			if self != SwapDmi::Model
				@marshalExclusions += self.superclass.marshalExclusions
				@marshalExclusions.uniq!
			end
			@marshalExcClean = true
			
			@marshalExclusions
		end
		
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
				next if self.class.marshalExclusions.include?(field)
				v = self.instance_variable_get(field)
				next if self.omitMarshalFieldValue?(v)
				v = self.marshalFieldValue(v)
				#we know first char will be '@', so drop
				fk = field.to_s[1,field.size-1].to_sym
				fields[fk] = v
			end
			
			pickle = PickledModel.new(self.class, self.id, self.context.id, fields)
			addlMarshal = self.class.additionalMarshallingProc
			self.instance_exec(pickle, &addlMarshal) unless addlMarshal.nil?
			pickle
		end
		
		# |pickled-model|
		#
		#
		def self.defineAdditionalMarshalling(&block)
			@addlMarshal = block
			self
		end
		def self.additionalMarshallingProc()
			@addlMarshal
		end
		
		# |pickled-model|
		#
		#
		def self.defineAdditionalUnMarshalling(&block)
			@addlUnmarshal = block
			self
		end
		def self.additionalUnMarshallingProc()
			@addlUnmarshal
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
			@id = SwapDmi.idValue(id)
			@contextOfUse = SwapDmi.idValue(context)
			
			@fields = {}
			@fields.merge!(fields) unless fields.nil?
			
			@sundry = {}
			@sundry.merge!(sundry) unless sundry.nil?
		end   

		def modelClassName()
			@modelClass
		end

		def modelClass()
			@modelClass.split('::').inject(Object) do |mod, cname|
				mod.const_get(cname)
			end
		end
		
	end
	
end

SwapDmi.activateExtensionHooks(:modelMarshal)
